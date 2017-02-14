//                              -*- Mode: JavaScript -*-
// fisher.js --- Fisher's exact test
//

(function () {

  fisher = {};

  function lngamm (z) {
    // Reference: "Lanczos, C. 'A precision approximation
    // of the gamma function', J. SIAM Numer. Anal., B, 1, 86-96, 1964."
    // Translation of  Alan Miller's FORTRAN-implementation
    // See http://lib.stat.cmu.edu/apstat/245

    var x = 0;
    x += 0.1659470187408462e-06 / (z + 7);
    x += 0.9934937113930748e-05 / (z + 6);
    x -= 0.1385710331296526     / (z + 5);
    x += 12.50734324009056      / (z + 4);
    x -= 176.6150291498386      / (z + 3);
    x += 771.3234287757674      / (z + 2);
    x -= 1259.139216722289      / (z + 1);
    x += 676.5203681218835      / (z);
    x += 0.9999999999995183;
    return (Math.log (x) - 5.58106146679532777 - z + (z - 0.5) * Math.log (z + 6.5));
  }


  function lnfact (n) {
    if (n <= 1) return (0);
    return (lngamm (n + 1));
  }


  function lnbico (n, k) {
    return (lnfact (n) - lnfact (k) - lnfact (n - k));
  }


  fisher.exact_nc = function (n11, n12, n21, n22, w) {
    // Fisher's exact test modified to use Fisher's non-central hypergeometric
    // distribution with a odds-ratio bias of w.  The procedure returns the p-value
    // based on a null-hypothesis of the odds-ratio being <= w.
    // Significant calls indicates that n11 / n12 is enriched by at least w.
    var x = n11;
    var m1 = n11 + n21;
    var m2 = n12 + n22;
    var n = n11 + n12;
    var x_min = Math.max (0, n - m2);
    var x_max = Math.min (n, m1);
    var l = [];
    for (var y = x_min; y <= x_max; y++) {
      l[y - x_min] = (lnbico (m1, y) + lnbico (m2, n - y) + y * Math.log (w));
    }
    var max_l = Math.max.apply (Math, l);


    var sum_l = l.map (function (x) { return Math.exp (x - max_l); }).reduce (function (a, b) {
        return a + b; }, 0);
    sum_l = Math.log (sum_l);


    var den_sum = 0;
    for (var y = x; y <= x_max; y++) {
      den_sum += Math.exp (l[y - x_min] - max_l);
    }
    den_sum = Math.log (den_sum);
    return Math.exp (den_sum - sum_l);
  };

  fisher.exact_nc_w = function (n11, n12, n21, n22) {
    // Returns a weight between 0 and 1 appropriate for colour coding
    if ((n11 / n12) / (n21 / n22) < 1) return 0;
    if (n11 + n12 == 0 || n11 + n21 == 0 || n12 + n21 == 0 || n12 + n22 == 0) {
      return 0;
    }
    var a = -Math.log (fisher.exact_nc (n11, n12, n21, n22, 2));
    var b = -Math.log (0.05);  // Will be clipped at 0
    var c = -Math.log (1e-20); // Will be clipped at 1
    var res = (a - b) / (c - b);
    //console.debug(a,b,c);
    //console.log (n11, n12, n21, n22, res);
    if (res > 1) return 1;
    if (res < 0) return 0;
    return res;
  };



})();