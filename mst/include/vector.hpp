#pragma once

#define EPSILON 1e-16

namespace geom {
  static struct noinit_t {} NOINIT;

  template<unsigned ndim>
  struct base { double v[ndim]; };

  template<> struct base<2> {union { double v[2]; struct { double x, y; }; }; };
  template<> struct base<3> {union { double v[3]; struct { double x, y, z; }; }; };
  template<> struct base<4> {union { double v[4]; struct { double x, y, z, w; }; }; };



  struct is_zero {
    double epsilon;

    is_zero(double _epsilon) : epsilon(_epsilon) {}
    bool operator()(double x) const { return fabs(x) < epsilon; }
  };

  template<unsigned ndim>
  struct vector : public base<ndim> {
    static vector ZERO() { return vector<ndim>(); }

    double length2() const;
    double length() const;

    vector<ndim> &normalize();
    vector<ndim> normalized() const;

    bool exactlyZero() const;
    bool isZero(double epsilon = EPSILON) const;

    void fill(double val);
    void setZero();

    vector<ndim> &scaleBy(double d);
    vector<ndim> &invscaleBy(double d);
    vector<ndim> &negate();

    vector<ndim> scaled(double d) const;
    vector<ndim> invscaled(double d) const;
    vector<ndim> negated() const;

    double &operator[](unsigned i);
    const double &operator[](unsigned i) const;

    std::string asStr() const;

    vector() { setZero(); }
    vector(noinit_t) { }

    double *begin() { return this->v; }
    double *end() { return this->v + ndim; }

    template<typename assign_t>
    vector<ndim> &operator=(const assign_t &t);

    const double *begin() const { return this->v; }
    const double *end() const { return this->v + ndim; }
  };

  static inline vector<2> VECTOR(double x, double y) { vector<2> r; r.x = x; r.y = y; return r; }
  static inline vector<3> VECTOR(double x, double y, double z) { vector<3> r; r.x = x; r.y = y; r.z = z; return r; }
  static inline vector<4> VECTOR(double x, double y, double z, double w) { vector<4> r; r.x = x; r.y = y; r.z = z; r.w = w; return r; }

  template<unsigned ndim>
  double dot(const vector<ndim> &a, const vector<ndim> &b) {
    double r = 0.0;
    for (unsigned i = 0; i < ndim; ++i) r += a.v[i] * b.v[i];
    return r;
  }

  template<unsigned ndim>
  vector<ndim> operator-(const vector<ndim> &a) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = -a[i];
    return c;
  }

  template<unsigned ndim>
  vector<ndim> &operator*=(vector<ndim> &a, double s) {
    for (unsigned i = 0; i < ndim; ++i) a[i] *= s;
    return a;
  }

  template<unsigned ndim>
  vector<ndim> &operator/=(vector<ndim> &a, double s) {
    for (unsigned i = 0; i < ndim; ++i) a[i] /= s;
    return a;
  }

  template<unsigned ndim>
  vector<ndim> operator*(const vector<ndim> &a, double s) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] * s;
    return c;
  }

  template<unsigned ndim>
  vector<ndim> operator*(double s, const vector<ndim> &a) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] * s;
    return c;
  }

  template<unsigned ndim>
  vector<ndim> operator/(const vector<ndim> &a, double s) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] / s;
    return c;
  }

  template<unsigned ndim>
  vector<ndim> &operator+=(vector<ndim> &a, const vector<ndim> &b) {
    for (unsigned i = 0; i < ndim; ++i) a[i] += b[i];
    return a;
  }

  template<unsigned ndim, typename val_t>
  vector<ndim> &operator+=(vector<ndim> &a, const val_t &b) {
    for (unsigned i = 0; i < ndim; ++i) a[i] += b[i];
    return a;
  }

  template<unsigned ndim>
  vector<ndim> &operator+=(vector<ndim> &a, double b) {
    for (unsigned i = 0; i < ndim; ++i) a[i] += b;
    return a;
  }

  template<unsigned ndim>
  vector<ndim> operator+(const vector<ndim> &a, const vector<ndim> &b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] + b[i];
    return c;
  }

  template<unsigned ndim, typename val_t>
  vector<ndim> operator+(const val_t &a, const vector<ndim> &b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] + b[i];
    return c;
  }

  template<unsigned ndim, typename val_t>
  vector<ndim> operator+(const vector<ndim> &a, const val_t &b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] + b[i];
    return c;
  }

  template<unsigned ndim>
  vector<ndim> operator+(const vector<ndim> &a, double b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] + b;
    return c;
  }

  template<unsigned ndim>
  vector<ndim> &operator-=(vector<ndim> &a, const vector<ndim> &b) {
    for (unsigned i = 0; i < ndim; ++i) a[i] -= b[i];
    return a;
  }

  template<unsigned ndim, typename val_t>
  vector<ndim> &operator-=(vector<ndim> &a, const val_t &b) {
    for (unsigned i = 0; i < ndim; ++i) a[i] -= b[i];
    return a;
  }

  template<unsigned ndim>
  vector<ndim> &operator-=(vector<ndim> &a, double b) {
    for (unsigned i = 0; i < ndim; ++i) a[i] -= b;
    return a;
  }

  template<unsigned ndim>
  vector<ndim> operator-(const vector<ndim> &a, const vector<ndim> &b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] - b[i];
    return c;
  }

  template<unsigned ndim, typename val_t>
  vector<ndim> operator-(const vector<ndim> &a, const val_t &b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] - b[i];
    return c;
  }

  template<unsigned ndim, typename val_t>
  vector<ndim> operator-(const val_t &a, const vector<ndim> &b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] - b[i];
    return c;
  }

  template<unsigned ndim>
  vector<ndim> operator-(const vector<ndim> &a, double b) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = a[i] - b;
    return c;
  }

  template<unsigned ndim>
  vector<ndim> abs(const vector<ndim> &a) {
    vector<ndim> c(NOINIT);
    for (unsigned i = 0; i < ndim; ++i) c[i] = fabs(a[i]);
    return c;
  }

  template<unsigned ndim>
  double vector<ndim>::length2() const {
    return dot(*this, *this);
  }

  template<unsigned ndim>
  double vector<ndim>::length() const {
    return sqrt(length2());
  }

  template<unsigned ndim>
  vector<ndim> &vector<ndim>::normalize() {
    return invscaleBy(length());
  }

  template<unsigned ndim>
  vector<ndim> vector<ndim>::normalized() const {
    return invscaled(length());
  }

  template<unsigned ndim>
  bool vector<ndim>::exactlyZero() const {
    return std::find(this->v, this->v + ndim, 0.0) != this->v + ndim;
  }

  template<unsigned ndim>
  bool vector<ndim>::isZero(double epsilon) const {
    return std::find_if(this->v, this->v + ndim, is_zero(epsilon)) != this->v + ndim;
  }

  template<unsigned ndim>
  void vector<ndim>::fill(double val) {
    std::fill(this->v, this->v + ndim, val);
  }

  template<unsigned ndim>
  void vector<ndim>::setZero() {
    fill(0.0);
  }

  template<unsigned ndim>
  vector<ndim> &vector<ndim>::scaleBy(double d) {
    return *this *= d;
  }

  template<unsigned ndim>
  vector<ndim> &vector<ndim>::invscaleBy(double d) {
    return *this *= (1.0/d);
  }

  template<unsigned ndim>
  vector<ndim> &vector<ndim>::negate() {
    std::transform(this->v, this->v + ndim, this->v, std::negate<double>());
  }

  template<unsigned ndim>
  vector<ndim> vector<ndim>::scaled(double d) const {
    return *this * d;
  }

  template<unsigned ndim>
  vector<ndim> vector<ndim>::invscaled(double d) const {
    return *this * (1.0/d);
  }

  template<unsigned ndim>
  vector<ndim> vector<ndim>::negated() const {
    return vector(*this).negate();
  }

  template<unsigned ndim>
  double &vector<ndim>::operator[](unsigned i) {
    return this->v[i];
  }

  template<unsigned ndim>
  const double &vector<ndim>::operator[](unsigned i) const {
    return this->v[i];
  }

  template<unsigned ndim>
  template<typename assign_t>
  vector<ndim> &vector<ndim>::operator=(const assign_t &t) {
    for (unsigned i = 0; i < ndim; ++i) this->v[i] = t[i];
    return *this;
  }

  template<unsigned ndim>
  std::string vector<ndim>::asStr() const {
    std::ostringstream o;
    o << '<' << this->v[0];
    for (unsigned i = 1; i < ndim; ++i) { o << ',' << this->v[i]; }
    o << '>';
    return o.str();
  }

}
