#pragma once

#include <valarray>
#include <istream>
#include <sstream>
#include <iomanip>
#include <stdexcept>

#include "mathfuncs.hpp"

namespace matrix {



  template<typename T>
  struct const_slice {
    const std::valarray<T> &data;
    size_t offset, stride;
  
    const_slice(const std::valarray<T> &_data,
                       size_t _offset,
                       size_t _stride) : data(_data), offset(_offset), stride(_stride) {
    }
  
    const T &operator[](size_t idx) const {
      return data[stride * idx + offset];
    }
  };
  


  template<typename T>
  struct slice {
    std::valarray<T> &data;
    size_t offset, stride;
  
    slice(std::valarray<T> &_data,
                 size_t _offset,
                 size_t _stride) : data(_data), offset(_offset), stride(_stride) {
    }
  
    const T &operator[](size_t idx) const {
      return data[stride * idx + offset];
    }
  
    T &operator[](size_t idx) {
      return data[stride * idx + offset];
    }
  };
  


  template<typename T>
  struct matrix {
  private:
    matrix(const matrix &);
    matrix &operator=(const matrix &);
  
  public:
    typedef const_slice<T> const_slice;
    typedef slice<T> slice;

    std::vector<std::string> col_labels;
    std::vector<std::string> row_labels;
    size_t n_rows;
    size_t n_cols;
  
    std::valarray<T> data;
  
    const_slice row(size_t n) const {
      return const_slice(data, n * n_cols, 1);
    }
  
    const_slice col(size_t n) const {
      return const_slice(data, n, n_cols);
    }
  
    const T &operator()(size_t v) const {
      return data[v];
    }
  
    T &operator()(size_t v) {
      return data[v];
    }
  
    void posToColAndRow(size_t v, size_t &c, size_t &r) const {
      c = v % n_cols;
      r = (v - c) / n_cols;
    }
  
    size_t colAndRowToPos(size_t c, size_t r) const {
      return c + r * n_cols;
    }
  
    const T &operator()(size_t c, size_t r) const {
      return data[c + r * n_cols];
    }
  
    slice row(size_t n) {
      return slice(data, n * n_cols, 1);
    }
  
    slice col(size_t n) {
      return slice(data, n, n_cols);
    }
  
    T &operator()(size_t c, size_t r) {
      return data[c + r * n_cols];
    }
  
    matrix() : col_labels(), row_labels(), n_cols(0), n_rows(0), data() {
    }
  
    matrix(size_t _n_cols, size_t _n_rows) : col_labels(_n_cols), row_labels(_n_rows), n_cols(_n_cols), n_rows(_n_rows), data(_n_rows * _n_cols) {
    }
  
    matrix(std::istream &in) {
      std::string line;
      std::getline(in, line);
      col_labels = str::split(line, '\t');
      col_labels.erase(col_labels.begin());
  
      n_cols = col_labels.size();
  
      std::vector<std::valarray<T> > temp;
      while (in.good()) {
        std::getline(in, line);
        if (!line.size()) break;
  
        std::istringstream ins(line);
  
        std::string row;
        ins >> row;
  
        row_labels.push_back(row);
        temp.push_back(std::valarray<T>(n_cols));
        std::valarray<T> &rowdata = temp.back();
  
        for (size_t i = 0; i < n_cols; ++i) {
          ins >> rowdata[i];
        }
  
        if (ins.fail()) {
          throw std::runtime_error("failed to read matrix");
        }
      }
  
      n_rows = temp.size();
  
      data.resize(n_rows * n_cols);
      for (size_t i = 0; i < n_rows; ++i) {
        for (size_t j = 0; j < n_cols; ++j) {
          data[j + i * n_cols] = temp[i][j];
        }
      }
    }
  
    void swap(matrix &other) {
      std::swap(col_labels, other.col_labels);
      std::swap(row_labels, other.row_labels);
      std::swap(n_cols, other.n_cols);
      std::swap(n_rows, other.n_rows);
      std::swap(data, other.data);
    }
  
    void init(size_t _n_cols, size_t _n_rows) {
      n_cols = _n_cols;
      n_rows = _n_rows;
      col_labels.clear(); col_labels.resize(n_cols);
      row_labels.clear(); row_labels.resize(n_rows);
      data.resize(n_rows * n_cols);
    }
  };

  void covariance_matrix(const matrix<double> &m, matrix<double> &cov) {
    cov.init(m.n_cols, m.n_rows);
    for (size_t i = 0; i < m.n_cols; ++i) {
      for (size_t j = i; j < m.n_cols; ++j) {
        cov(i,j) = cov(j,i) = covariance(m.col(i), m.col(j), m.n_rows);
      }
    }
  }

}
