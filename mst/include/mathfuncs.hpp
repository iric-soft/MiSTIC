#pragma once

#include <math.h>
#include <cmath>
#include <limits>
#include <algorithm>

#include "index_cmp.hpp"

namespace {
  template<typename array_t>
  void _assign_ranks_to_indices(const std::vector<size_t> &indices, array_t &a, bool normalize) {
    const size_t N = indices.size();

    size_t i = 0;

    double rv = 0;

    double rank_offset, rank_scale;

    if (normalize) {
      rank_offset = 0.0;
      rank_scale = 1.0;
    } else {
      rank_offset = (N-1)/2.0;
      rank_scale = 1.0 / sqrt((N*N - 1)/12.0);
    }

    while (i < N) {
      size_t j = i;
      double val = 0.0;

      while (j < N && a[indices[j]] == a[indices[i]]) {
        val += rv;
        rv += 1.0;
        ++j;
      }

      val /= j-i;

      val = (val - rank_offset) * rank_scale;

      while (i < j) {
        a[indices[i++]] = val;
      }
    }
  }

  std::pair<double, double> _trimmed_mean_sd(std::vector<double> &work, double discard_fraction, double ddof = 0.0) {
    size_t N_disc = (size_t)floor(work.size() * discard_fraction / 2.0);

    if (work.size() <= 2 * N_disc) {
      return std::make_pair(std::numeric_limits<double>::quiet_NaN(), std::numeric_limits<double>::quiet_NaN());
    }

    size_t N_rem = work.size() - 2 * N_disc;

    std::nth_element(work.begin(), work.begin() + N_disc, work.end(), std::less<double>());
    std::nth_element(work.begin() + N_disc, work.begin() + 2 * N_disc, work.end(), std::greater<double>());

    double ma = 0.0;
    double va = 0.0;

    for (size_t i = 0; i < N_rem; ++i) {
      ma += work[i + 2 * N_disc];
    }

    ma /= double(N_rem) - ddof;

    for (size_t i = 0; i < N_rem; ++i) {
      double x = work[i + 2 * N_disc] - ma;
      va += x * x;
    }

    va /= double(N_rem) - ddof;

    return std::make_pair(ma, va);
  }

  std::pair<double, double> _winsorised_mean_sd(std::vector<double> &work, double discard_fraction, double ddof = 0.0) {
    size_t N_disc = (size_t)floor(work.size() * discard_fraction / 2.0);

    if (work.size() <= 2 * N_disc) {
      return std::make_pair(std::numeric_limits<double>::quiet_NaN(), std::numeric_limits<double>::quiet_NaN());
    }

    size_t N_rem = work.size() - 2 * N_disc;

    std::nth_element(work.begin(), work.begin() + N_disc, work.end(), std::less<double>());
    std::nth_element(work.begin() + N_disc, work.begin() + 2 * N_disc, work.end(), std::greater<double>());

    double lo = *std::min_element(work.begin() + 2 * N_disc, work.end());
    double hi = *std::max_element(work.begin() + 2 * N_disc, work.end());

    double ma = 0.0;
    double va = 0.0;

    for (size_t i = 0; i < N_rem; ++i) {
      ma += work[i + 2 * N_disc];
    }

    ma += N_disc * lo + N_disc * hi;
    ma /= double(work.size()) - ddof;

    for (size_t i = 0; i < N_rem; ++i) {
      double x = work[i + 2 * N_disc] - ma;
      va += x * x;
    }

    va +=
      N_disc * (lo - ma) * (lo - ma) +
      N_disc * (hi - ma) * (hi - ma);
    va /= double(work.size()) - ddof;

    return std::make_pair(ma, va);
  }
}

template<bool masked>
struct mathkernel_t {
  template<typename array_t>
  static double min(const array_t &a, size_t sz);

  template<typename array_t>
  static double max(const array_t &a, size_t sz);

  template<typename array_t>
  static double mean(const array_t &a, size_t sz, double ddof = 0.0);

  template<typename array_t>
  static double variance(const array_t &a, size_t sz, double ddof = 0.0);

  template<typename array_t>
  static double pop_variance(const array_t &a, size_t sz) {
    return variance(a, sz, 0.0);
  }

  template<typename array_t>
  static double sample_variance(const array_t &a, size_t sz) {
    return variance(a, sz, 1.0);
  }

  template<typename array_t>
  static double stddev(const array_t &a, size_t sz, double ddof = 0.0) {
    return sqrt(variance(a, sz, ddof));
  }

  template<typename array_t>
  static double pop_stddev(const array_t &a, size_t sz) {
    return sqrt(sample_variance(a, sz, 0.0));
  }

  template<typename array_t>
  static double sample_stddev(const array_t &a, size_t sz) {
    return sqrt(sample_variance(a, sz));
  }

  template<typename array_t>
  static double covariance(const array_t &a, const array_t &b, size_t sz, double ddof = 0.0);

  template<typename array_t>
  static double dot_product(const array_t &a, const array_t &b, size_t sz);

  template<typename array_t>
  static double euclidean_distance(const array_t &a, const array_t &b, size_t sz);

  template<typename array_t>
  static double pearson_corr(const array_t &a, const array_t &b, size_t sz, double ddof = 0.0);

  template<typename array_t>
  static void transform(array_t &a, size_t sz, double offset, double scale);

  template<typename array_t>
  static std::pair<double, double> trimmed_mean_sd(array_t &a, size_t sz, double discard_fraction, double ddof = 0.0);

  template<typename array_t>
  static std::pair<double, double> winsorised_mean_sd(array_t &a, size_t sz, double discard_fraction, double ddof = 0.0);

  template<typename array_t>
  static void rank_transform(array_t &a, size_t sz, bool normalize = true);
};



template<>
template<typename array_t>
double mathkernel_t<false>::min(const array_t &a, size_t sz) {
  double m = a[0];

  for (size_t i = 1; i < sz; ++i) m = std::min(m , a[i]);

  return m;
}

template<>
template<typename array_t>
double mathkernel_t<false>::max(const array_t &a, size_t sz) {
  double m = a[0];

  for (size_t i = 1; i < sz; ++i) m = std::max(m , a[i]);

  return m;
}

template<>
template<typename array_t>
double mathkernel_t<false>::mean(const array_t &a, size_t sz, double ddof) {
  double m = 0;

  for (size_t i = 0; i < sz; ++i) {
    m += a[i];
  }

  return m / (double(sz) - ddof);
}

template<>
template<typename array_t>
double mathkernel_t<false>::variance(const array_t &a, size_t sz, double ddof) {
  double ma = mean(a, sz, ddof);
  double v = 0;

  for (size_t i = 0; i < sz; ++i) {
    v += (a[i] - ma) * (a[i] - ma);
  }

  return v / (double(sz) - ddof);
}

template<>
template<typename array_t>
double mathkernel_t<false>::covariance(const array_t &a, const array_t &b, size_t sz, double ddof) {
  double ma = mean(a, sz, ddof);
  double mb = mean(b, sz, ddof);
  double c = 0;

  for (size_t i = 0; i < sz; ++i) {
    c += (a[i] - ma) * (b[i] - mb);
  }

  return c / (sz - ddof);
}

template<>
template<typename array_t>
double mathkernel_t<false>::dot_product(const array_t &a, const array_t &b, size_t sz) {
  double d = 0;
  for (size_t i = 0; i < sz; ++i) {
    d += a[i] * b[i];
  }
  return d;
}

template<>
template<typename array_t>
double mathkernel_t<false>::euclidean_distance(const array_t &a, const array_t &b, size_t sz) {
  double d = 0.0;
  for (size_t i = 0; i < sz; ++i) {
    double x = (a[i] - b[i]);
    d += x * x;
  }
  return sqrt(d);
}

template<>
template<typename array_t>
double mathkernel_t<false>::pearson_corr(const array_t &a, const array_t &b, size_t sz, double ddof) {
  double ma = mean(a, sz);
  double mb = mean(b, sz);

  double s_ab = 0.0;
  double s_aa = 0.0;
  double s_bb = 0.0;

  for (size_t i = 0; i < sz; ++i) {
    double am = a[i] - ma;
    double bm = b[i] - mb;
    s_ab += am * bm;
    s_aa += am * am;
    s_bb += bm * bm;
  }

  return s_ab / (sqrt(s_aa) * sqrt(s_bb));
}

template<>
template<typename array_t>
void mathkernel_t<false>::transform(array_t &a, size_t sz, double offset, double scale) {
  for (size_t i = 0; i < sz; ++i) {
    a[i] = (a[i] + offset) * scale;
  }
}

template<>
template<typename array_t>
std::pair<double, double> mathkernel_t<false>::trimmed_mean_sd(array_t &a, size_t sz, double discard_fraction, double ddof) {
  std::vector<double> work;
  work.reserve(sz);

  for (size_t i = 0; i < sz; ++i) {
    work.push_back(a[i]);
  }

  return _trimmed_mean_sd(work, discard_fraction, ddof);
}

template<>
template<typename array_t>
std::pair<double, double> mathkernel_t<false>::winsorised_mean_sd(array_t &a, size_t sz, double discard_fraction, double ddof) {
  std::vector<double> work;
  work.reserve(sz);

  for (size_t i = 0; i < sz; ++i) {
    work.push_back(a[i]);
  }

  return _winsorised_mean_sd(work, discard_fraction, ddof);
}

template<>
template<typename array_t>
void mathkernel_t<false>::rank_transform(array_t &a, size_t sz, bool normalize) {
  std::vector<size_t> indices;
  indices.reserve(sz);
  for (size_t i = 0; i < sz; ++i) {
    indices.push_back(i);
  }

  std::sort(indices.begin(), indices.end(), make_index_cmp(a));

  _assign_ranks_to_indices(indices, a, normalize);
}




template<>
template<typename array_t>
double mathkernel_t<true>::min(const array_t &a, size_t sz) {
  double m = std::numeric_limits<double>::quiet_NaN();

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i]) && (std::isnan(m) || m < a[i])) {
      m = a[i];
    }
  }

  return m;
}

template<>
template<typename array_t>
double mathkernel_t<true>::max(const array_t &a, size_t sz) {
  double m = std::numeric_limits<double>::quiet_NaN();

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i]) && (std::isnan(m) || m > a[i])) {
      m = a[i];
    }
  }

  return m;
}

template<>
template<typename array_t>
double mathkernel_t<true>::mean(const array_t &a, size_t sz, double ddof) {
  double m = 0;
  double n = 0;

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i])) { m += a[i]; n += 1; }
  }

  if (sz > 0 && n == 0.0) return std::numeric_limits<double>::quiet_NaN();

  return m / (n - ddof);
}

template<>
template<typename array_t>
double mathkernel_t<true>::variance(const array_t &a, size_t sz, double ddof) {
  double ma = mean(a, sz, ddof);
  double n = 0;
  double v = 0;

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i])) {
      v += (a[i] - ma) * (a[i] - ma);
      n += 1;
    }
  }

  if (sz > 0 && n == 0.0) return std::numeric_limits<double>::quiet_NaN();

  return v / (double(n) - ddof);
}

template<>
template<typename array_t>
double mathkernel_t<true>::covariance(const array_t &a, const array_t &b, size_t sz, double ddof) {
  double n = 0.0;
  double ma = 0.0;
  double mb = 0.0;

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i]) && !std::isnan(b[i])) {
      ma += a[i];
      mb += b[i];
      n += 1;
    }
  }

  if (sz > 0 && n == 0.0) return std::numeric_limits<double>::quiet_NaN();

  ma /= (n - ddof);
  mb /= (n - ddof);

  double c = 0;
  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i]) && !std::isnan(b[i])) {
      c += (a[i] - ma) * (b[i] - mb);
    }
  }

  return c / (n - ddof);
}

template<>
template<typename array_t>
double mathkernel_t<true>::dot_product(const array_t &a, const array_t &b, size_t sz) {
  double d = 0;

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i] && !std::isnan(b[i]))) {
      d += a[i] * b[i];
    }
  }

  return d;
}

template<>
template<typename array_t>
double mathkernel_t<true>::euclidean_distance(const array_t &a, const array_t &b, size_t sz) {
  double d = 0.0;

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i] && !std::isnan(b[i]))) {
      double x = (a[i] - b[i]);
      d += x * x;
    }
  }

  return sqrt(d);
}

template<>
template<typename array_t>
double mathkernel_t<true>::pearson_corr(const array_t &a, const array_t &b, size_t sz, double ddof) {
  double ma = 0.0;
  double mb = 0.0;
  double n = 0.0;

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i]) && !std::isnan(b[i])) {
      ma += a[i];
      mb += b[i];
      n += 1;
    }
  }

  if (sz > 0 && n == 0.0) return std::numeric_limits<double>::quiet_NaN();

  double s_ab = 0.0;
  double s_aa = 0.0;
  double s_bb = 0.0;

  ma /= (n - ddof);
  mb /= (n - ddof);

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i]) && !std::isnan(b[i])) {
      double am = a[i] - ma;
      double bm = b[i] - mb;
      s_ab += am * bm;
      s_aa += am * am;
      s_bb += bm * bm;
    }
  }

  return s_ab / (sqrt(s_aa) * sqrt(s_bb));
}

template<>
template<typename array_t>
void mathkernel_t<true>::transform(array_t &a, size_t sz, double offset, double scale) {
  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i])) a[i] = (a[i] + offset) * scale;
  }
}

template<>
template<typename array_t>
std::pair<double, double> mathkernel_t<true>::trimmed_mean_sd(array_t &a, size_t sz, double discard_fraction, double ddof) {
  std::vector<double> filt;
  filt.reserve(sz);

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i])) filt.push_back(a[i]);
  }

  return _trimmed_mean_sd(filt, discard_fraction, ddof);
}

template<>
template<typename array_t>
std::pair<double, double> mathkernel_t<true>::winsorised_mean_sd(array_t &a, size_t sz, double discard_fraction, double ddof) {
  std::vector<double> filt;
  filt.reserve(sz);

  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i])) filt.push_back(a[i]);
  }

  return _winsorised_mean_sd(filt, discard_fraction, ddof);
}

template<>
template<typename array_t>
void mathkernel_t<true>::rank_transform(array_t &a, size_t sz, bool normalize) {
  std::vector<size_t> indices;
  indices.reserve(sz);
  for (size_t i = 0; i < sz; ++i) {
    if (!std::isnan(a[i])) {
      indices.push_back(i);
    }
  }

  std::sort(indices.begin(), indices.end(), make_index_cmp(a));

  _assign_ranks_to_indices(indices, a, normalize);
}

// alternate pearson correlation calculation.
//   double sum_sq_a = 0.0;
//   double sum_sq_b = 0.0;
//   double sum_coproduct = 0.0;
//   double mean_a = a[0];
//   double mean_b = b[0];

//   for (size_t i = 1; i < sz; ++i) {
//     double sweep = double(i) / double(i+1);
//     double delta_a = a[i] - mean_a;
//     double delta_b = b[i] - mean_b;
//     sum_sq_a += delta_a * delta_a * sweep;
//     sum_sq_b += delta_b * delta_b * sweep;
//     sum_coproduct += delta_a * delta_b * sweep;
//     mean_a += delta_a / (i+1);
//     mean_b += delta_b / (i+1);
//   }

//   double pop_sd_a = sqrt(sum_sq_a / sz);
//   double pop_sd_b = sqrt(sum_sq_b / sz);
//   double cov_a_b = sum_coproduct / sz;
//   return cov_a_b / (pop_sd_a * pop_sd_b);
