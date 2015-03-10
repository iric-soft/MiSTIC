(function() {
    var MAXLOG    = 7.09782712893383996843e+2;
    var M_SQRT1_2 = 0.707106781186547524400844362104849039;
    var M_SQRT2   = 1.41421356237309504880168872420969808;

    var ZP = [
        2.46196981473530512524E-10,
        5.64189564831068821977E-1,
        7.46321056442269912687E0,
        4.86371970985681366614E1,
        1.96520832956077098242E2,
        5.26445194995477358631E2,
        9.34528527171957607540E2,
        1.02755188689515710272E3,
        5.57535335369399327526E2,
    ];

    var ZQ = [
        1.0,
        1.32281951154744992508E1,
        8.67072140885989742329E1,
        3.54937778887819891062E2,
        9.75708501743205489753E2,
        1.82390916687909736289E3,
        2.24633760818710981792E3,
        1.65666309194161350182E3,
        5.57535340817727675546E2,
    ];

    var ZR = [
        5.64189583547755073984E-1,
        1.27536670759978104416E0,
        5.01905042251180477414E0,
        6.16021097993053585195E0,
        7.40974269950448939160E0,
        2.97886665372100240670E0,
    ];

    var ZS = [
        1.00000000000000000000E0,
        2.26052863220117276590E0,
        9.39603524938001434673E0,
        1.20489539808096656605E1,
        1.70814450747565897222E1,
        9.60896809063285878198E0,
        3.36907645100081516050E0,
    ];

    var ZT = [
        9.60497373987051638749E0,
        9.00260197203842689217E1,
        2.23200534594684319226E3,
        7.00332514112805075473E3,
        5.55923013010394962768E4,
    ];

    var ZU = [
        1.00000000000000000000E0,
        3.35617141647503099647E1,
        5.21357949780152679795E2,
        4.59432382970980127987E3,
        2.26290000613890934246E4,
        4.92673942608635921086E4,
    ];

    var polevl = function(x, coef) {
        // evaluates a polynomial y = C_0 + C_1x + C_2x^2 + ... + C_Nx^N
        // Coefficients are stored in reverse order, i.e. coef[0] = C_N
        var result = 0.0;
        for (var i in coef) {
            result = result * x + coef[i];
        }
        return result;
    };

    stats = {};

    stats.erfc = function(a) {
        var x;
        x = Math.abs(a);

        if (x < 1.0) {
            return 1.0 - stats.erf(a);
        }

        var z = -a * a;

        if (z < -MAXLOG) {
            // underflow
            return (a < 0.0) ? 2.0 : 0.0;
        }

        z = Math.exp(z);

        var p, q;
        if (x < 8.0) {
            p = polevl(x, ZP);
            q = polevl(x, ZQ);
        } else {
            p = polevl(x, ZR);
            q = polevl(x, ZS);
        }

        var y = z * p / q;

        if (a < 0.0) {
            y = 2.0 - y;
        }

        if (y == 0.0) {
            // underflow
            return (a < 0.0) ? 2.0 : 0.0;
        }

        return y;
    };

    var lngamma = function(z) {
        var x = 0.1659470187408462e-06 / (z + 7);
        x += 0.9934937113930748e-05 / (z + 6);
        x -= 0.1385710331296526 / (z + 5);
        x += 12.50734324009056 / (z + 4);
        x -= 176.6150291498386 / (z + 3);
        x += 771.3234287757674 / (z + 2);
        x -= 1259.139216722289 / (z + 1);
        x += 676.5203681218835 / (z);
        x += 0.9999999999995183;
        return Math.log(x) - 5.58106146679532777 - z + (z - 0.5) * Math.log(z + 6.5);
    };

    var lnfactorial = function(n) {
        return n < 1 ? 0 : lngamma(n + 1);
    };

    var lncombination = function(n, p) {
        return lnfactorial(n) - lnfactorial(p) - lnfactorial(n - p);
    };

    hypergeom = {};

    // pmf(k, K, n, N) = choose(n, k) * choose(N-n, K-k) / choose(N, K)
    // -- the probability of selecting k in K, from a set of n in N.
    hypergeom.logpmf = function(k, K, n, N) {
        return
            + lncombination(n, k)
            + lncombination(N-n, K-k)
            - lncombination(N, K);
    };

    hypergeom.pmf = function(k, K, n, N) {
        return Math.exp(hypergeom.logpmf(k, K, n, N));
    };

    hypergeom.cdf = function(k, K, n, N) {
        var p = 0.0;
        for (var _k = 0; _k <= k; ++_k) {
            p += hypergeom.pmf(_k, K, n, N);
        }
        return p;
    };

    hypergeom.logcdf = function(k, K, n, N) {
        return Math.log(hypergeom.cdf(k, K, n, N));
    };

    hypergeom.sf = function(k, K, n, N) {
        var p = 0.0;
        for (var _k = k + 1; _k <= K && _k <= n; ++_k) {
            p += hypergeom.pmf(_k, K, n, N);
        }
        return p;
    };

    hypergeom.logsf = function(k, K, n, N) {
        return Math.log(hypergeom.sf(k, K, n, N));
    };

    stats.erf = function(a) {
        if (Math.abs(a) > 1.0) {
            return 1.0 - stats.erfc(a);
        }
        var z = a * a;
        return a * polevl(z, ZT) / polevl(z, ZU);
    };

    stats.z_low = function(x) {
        // Returns left-hand tail of z distribution (0 to x).
        // x ranges from -infinity to +infinity; result ranges from 0 to 1

        var y = x * M_SQRT1_2;
        var z = Math.abs(y);

        if (z < M_SQRT1_2) {
            return 0.5 + 0.5 * stats.erf(y);
        } else if (x > 0.0) {
            return 1.0 - 0.5 * stats.erfc(z);
        } else {
            return 0.5 * stats.erfc(z);
        }
    };

    stats.z_high = function(x) {
        // Returns right-hand tail of z distribution (0 to x).
        // x ranges from -infinity to +infinity; result ranges from 0 to 1

        var y = x * M_SQRT1_2;
        var z = Math.abs(y);

        if (z < M_SQRT1_2) {
            return 0.5 - 0.5 * stats.erf(y);
        } else if (x < 0.0) {
            return 1.0 - 0.5 * stats.erfc(z);
        } else {
            return 0.5 * stats.erfc(z);
        }
    };

    stats.zprob = function(x) {
        return 2 * stats.z_high(Math.abs(x));
    };

  stats.sum = function(a) {
     var sz = a.length;
     var sum_a = a[0];

     for (var i = 1; i < sz; ++i) {
        sum_a += a[i];
    }
    return sum_a;
    };


  stats.average = function(a) {
      var sz = a.length;
      var mean_a = a[0];

      for (var i = 1; i < sz; ++i) {
        var delta_a = a[i] - mean_a;
        mean_a += delta_a / (i+1);
    }
    return mean_a;
    };

  stats.stdev = function(a) {
     var sz = a.length;
     var sum_sq_a = 0.0;
     var mean_a = a[0];

    for (var i = 1; i < sz; ++i) {
        var sweep = i / (i+1);
        var delta_a = a[i] - mean_a;
        sum_sq_a += delta_a * delta_a * sweep;
        mean_a += delta_a / (i+1);
       }

     var pop_sd_a = Math.sqrt(sum_sq_a / sz);
     return pop_sd_a ;
    };
  stats.range = function (a) {
      var sz = a.length;
      var range = [a[0], a[0]];
      for (var i = 1; i < sz; ++i) {
        if (a[i]<range[0]) { range[0] = a[i];}
        if (a[i]>range[1]) { range[1] = a[i];}
      }
      return range
  };


    stats.pearson = function(a, b) {
        var sz = Math.min(a.length, b.length);
        var sum_sq_a = 0.0;
        var sum_sq_b = 0.0;
        var sum_coproduct = 0.0;
        var mean_a = a[0];
        var mean_b = b[0];

        for (var i = 1; i < sz; ++i) {
            var sweep = i / (i+1);
            var delta_a = a[i] - mean_a;
            var delta_b = b[i] - mean_b;
            sum_sq_a += delta_a * delta_a * sweep;
            sum_sq_b += delta_b * delta_b * sweep;
            sum_coproduct += delta_a * delta_b * sweep;
            mean_a += delta_a / (i+1);
            mean_b += delta_b / (i+1);
        }

        var pop_sd_a = Math.sqrt(sum_sq_a / sz);
        var pop_sd_b = Math.sqrt(sum_sq_b / sz);
        var cov_a_b = sum_coproduct / sz;
        return cov_a_b / (pop_sd_a * pop_sd_b);
    };

    stats.oddsratio = function(a, b, c, d) {
        return a * d / (b * c);
    };


    // ** Fisher's exact test has been moved to fisher.js **


    // Chi-square test of independence.
    stats.chi2 = function(a, b, c, d) {
        if (a < 0 || b < 0 || c < 0 || d < 0) {
            throw "all values must be nonnegative.";
        }

        var t = a+b+c+d;
        var ea, eb, ec, ed;

        ea = (a+b) * (a+c) / t;
        eb = (b+a) * (b+d) / t;
        ec = (c+a) * (c+d) / t;
        ed = (d+b) * (d+c) / t;

        var chi2 = (
            Math.pow(a - ea, 2) / ea +
            Math.pow(b - eb, 2) / eb +
            Math.pow(c - ec, 2) / ec +
            Math.pow(d - ed, 2) / ed
        );

        return chi2;
    };

    // Chi-square test of independence.
    stats.chi2_yates = function(a, b, c, d) {
        if (a < 0 || b < 0 || c < 0 || d < 0) {
            throw "all values must be nonnegative.";
        }

        var t = a+b+c+d;
        var ea, eb, ec, ed;

        ea = (a+b) * (a+c) / t;
        eb = (b+a) * (b+d) / t;
        ec = (c+a) * (c+d) / t;
        ed = (d+b) * (d+c) / t;

        if (ea == 0.0 || eb == 0.0 || ec == 0.0 || ed == 0.0) {
            console.log('inputs', a, b, c, d);
            throw "expected value is zero.";
        }

        var chi2 = (
            Math.pow(Math.abs(a - ea) - 0.5, 2) / ea +
            Math.pow(Math.abs(b - eb) - 0.5, 2) / eb +
            Math.pow(Math.abs(c - ec) - 0.5, 2) / ec +
            Math.pow(Math.abs(d - ed) - 0.5, 2) / ed
        );

        return chi2;
    };

    stats.kappa = function(a, b, c, d) {
        if (a < 0 || b < 0 || c < 0 || d < 0) {
            throw "all values must be nonnegative.";
        }

        var tot = a + b + c + d;
        var Pa  = (a + d) / tot;
        var PA1 = (a + b) / tot;
        var PA2 = 1 - PA1;
        var PB1 = (a + c) / tot;
        var PB2 = 1 - PB1;
        var Pe  = PA1*PB1 + PA2*PB2;
        return (Pa - Pe) / (1.0 - Pe);
    };

    stats.forPeak = function(a, b, c, d) {
        if (a < 0 || b < 0 || c < 0 || d < 0) {
            throw "all values must be nonnegative.";
        }

        var tot = a + b + c + d;
        var Pa  = (a + d) / tot;
        var PA1 = (a + b) / tot;
        var PA2 = 1 - PA1;
        var PB1 = (a + c) / tot;
        var PB2 = 1 - PB1;
        var Pe  = PA1*PB1 + PA2*PB2;
        return (Pa - Pe) / (1.0 - Pe);
    };
})();
