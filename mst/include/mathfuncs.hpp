#pragma once

#include <math.h>

template<typename array_t>
double mean(const array_t &a, size_t sz) {
  double m = 0;
  for (size_t i = 0; i < sz; ++i) {
    m += a[i];
  }
  return m / sz;
}

template<typename array_t>
double variance(const array_t &a, size_t sz) {
  double ma = mean(a, sz);
  double v = 0;
  for (size_t i = 0; i < sz; ++i) {
    v += (a[i] - ma) * (a[i] - ma);
  }
  return v / sz;
}

template<typename array_t>
double sample_variance(const array_t &a, size_t sz) {
  double ma = mean(a, sz);
  double v = 0;
  for (size_t i = 0; i < sz; ++i) {
    v += (a[i] - ma) * (a[i] - ma);
  }
  return v / (sz-1);
}

template<typename array_t>
double sample_stddev(const array_t &a, size_t sz) {
  return sqrt(sample_variance(a, sz));
}

template<typename array_t>
double stddev(const array_t &a, size_t sz) {
  return sqrt(variance(a, sz));
}

template<typename array_t>
double pearson_corr(const array_t &a, const array_t &b, size_t sz) {
#if 0
  double sum_sq_a = 0.0;
  double sum_sq_b = 0.0;
  double sum_coproduct = 0.0;
  double mean_a = a[0];
  double mean_b = b[0];

  for (size_t i = 1; i < sz; ++i) {
    double sweep = double(i) / double(i+1);
    double delta_a = a[i] - mean_a;
    double delta_b = b[i] - mean_b;
    sum_sq_a += delta_a * delta_a * sweep;
    sum_sq_b += delta_b * delta_b * sweep;
    sum_coproduct += delta_a * delta_b * sweep;
    mean_a += delta_a / (i+1);
    mean_b += delta_b / (i+1);
  }

  double pop_sd_a = sqrt(sum_sq_a / sz);
  double pop_sd_b = sqrt(sum_sq_b / sz);
  double cov_a_b = sum_coproduct / sz;
  return cov_a_b / (pop_sd_a * pop_sd_b);
#else
  double s_ab = 0.0;
  double s_aa = 0.0;
  double s_bb = 0.0;

  double ma = mean(a, sz);
  double mb = mean(b, sz);

  for (size_t i = 0; i < sz; ++i) {
    double am = a[i] - ma;
    double bm = b[i] - mb;
    s_ab += am * bm;
    s_aa += am * am;
    s_bb += bm * bm;
  }
  return s_ab / (sqrt(s_aa) * sqrt(s_bb));
#endif
}

template<typename array_t>
double covariance(const array_t &a, const array_t &b, size_t sz) {
  double ma = mean(a, sz);
  double mb = mean(b, sz);
  double c = 0;
  for (size_t i = 0; i < sz; ++i) {
    c += (a[i] - ma) * (b[i] - mb);
  }
  return c / sz;
}

template<typename array_t>
double dotprod(const array_t &a, const array_t &b, size_t sz) {
  double d = 0;
  for (size_t i = 0; i < sz; ++i) {
    d += a[i] * b[i];
  }
  return d;
}

template<typename array_t>
double euclideanDistance(const array_t &a, const array_t &b, size_t sz) {
  double d = 0.0;
  for (size_t i = 0; i < sz; ++i) {
    double x = (a[i] - b[i]);
    d += x * x;
  }
  return sqrt(d);
}
