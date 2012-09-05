#include "stringfuncs.hpp"
#include "mathfuncs.hpp"
#include "djset.hpp"
#include "opts.hpp"
#include "vector.hpp"
#include "index_cmp.hpp"

#include <iostream>
#include <iomanip>
#include <sstream>
#include <fstream>

#include <algorithm>
#include <functional>
#include <numeric>

#include <limits>

#include <vector>
#include <valarray>
#include <list>
#include <string>
#include <set>

#include <stdexcept>

#include <assert.h>
#include <fcntl.h>

#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/symmetric.hpp>
#include <boost/numeric/ublas/vector_proxy.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>
#include <boost/numeric/ublas/triangular.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/lu.hpp>

#include <boost/graph/graph_traits.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/depth_first_search.hpp>
#include <boost/graph/dijkstra_shortest_paths.hpp>



namespace ublas = boost::numeric::ublas;

typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::undirectedS> undirected_graph_t;
typedef boost::graph_traits<undirected_graph_t>::edge_descriptor ug_edge_t;
typedef boost::graph_traits<undirected_graph_t>::vertex_descriptor ug_vert_t;
typedef ublas::matrix<double> matrix_t;


 
// Matrix inversion routine.
// Uses lu_factorize and lu_substitute in uBLAS to invert a matrix
// From: http://www.crystalclearsoftware.com/cgi-bin/boost_wiki/wiki.pl?action=browse&id=LU_Matrix_Inversion
bool invertMatrix(const matrix_t &input, matrix_t &inverse) {
  typedef ublas::permutation_matrix<size_t> pmatrix;

  matrix_t A(input);

  pmatrix pm(A.size1());

  int res = lu_factorize(A,pm);
  if( res != 0 ) return false;

  inverse.assign(ublas::identity_matrix<matrix_t::value_type>(A.size1()));

  lu_substitute(A, pm, inverse);

  return true;
}



template<typename matrix_t>
void writeMatrix(std::ostream &out,
                 matrix_t &matrix,
                 std::vector<std::string> &row_labels,
                 std::vector<std::string> &col_labels) {
  const size_t N = matrix.size1();
  const size_t M = matrix.size2();

  assert (row_labels.size() == N);
  assert (col_labels.size() == M);

  for (size_t j = 0; j < M; ++j) {
    out << '\t' << col_labels[j];
  }
  out << std::endl;

  for (size_t i = 0; i < N; ++i) {
    out << row_labels[i];
    for (size_t j = 0; j < M; ++j) {
      out << '\t' << matrix(i,j);
    }
    out << std::endl;
  }
}

struct rowMax {
  template<typename row_t>
  double operator()(const row_t &row) {
    return *std::max_element(row.begin(), row.end());
  }
};

struct rowMean {
  template<typename row_t>
  double operator()(const row_t &row) {
    return mean(row, row.size());
  }
};

struct rowVariance {
  template<typename row_t>
  double operator()(const row_t &row) {
    return variance(row, row.size());
  }
};

template<typename func_t>
void selectRows(const matrix_t &m, size_t n_rows, std::vector<size_t> &selected_rows, func_t func) {
  typedef ublas::matrix_row<const matrix_t> row_t;

  std::vector<double> scores;
  std::vector<size_t> indices;
  const size_t N = m.size1();
  scores.reserve(N);
  indices.reserve(N);

  for (size_t i = 0; i < N; ++i) {
    row_t r(m, i);
    scores.push_back(func(r));
    indices.push_back(i);
  }

  std::sort(indices.begin(), indices.end(), make_index_cmp(scores));

  selected_rows.insert(selected_rows.end(), indices.end() - n_rows, indices.end());
}

void takeRows(matrix_t &m, std::vector<std::string> &m_rows, const std::vector<size_t> &selected_rows) {
  matrix_t temp(selected_rows.size(), m.size2());
  std::vector<std::string> temp_ids;
  temp_ids.reserve(selected_rows.size());

  for (size_t i = 0; i < selected_rows.size(); ++i) {
    size_t s = selected_rows[i];
    temp_ids.push_back(m_rows[s]);
    for (size_t j = 0; j < m.size2(); ++j) {
      temp(i, j) = m(s, j);
    }
  }

  std::swap(m, temp);
  std::swap(m_rows, temp_ids);
}

template<typename matrix_t>
void readMatrix(std::istream &in,
                size_t id_col,
                size_t first_data_col,
                matrix_t &matrix,
                std::vector<std::string> &row_labels,
                std::vector<std::string> &col_labels) {
  typedef typename matrix_t::value_type T;

  std::string line;
  std::getline(in, line);

  std::vector<std::string> vals;
  vals = str::split(line, '\t');

  size_t n_cols = vals.size() - first_data_col;
  col_labels.clear();
  col_labels.reserve(n_cols);
  col_labels.insert(col_labels.end(),
                    vals.begin() + first_data_col,
                    vals.end());

  std::list<std::valarray<T> > temp;

  while (in.good()) {
    std::getline(in, line);
    if (!line.size()) break;
    vals = str::split(line, '\t');

    row_labels.push_back(vals[id_col]);
    temp.push_back(std::valarray<T>(n_cols));

    std::valarray<T> &rowdata = temp.back();
    for (size_t i = 0; i < n_cols; ++i) {
      std::istringstream ins(vals[first_data_col + i]);
      ins >> rowdata[i];
      if (ins.fail()) {
        throw std::runtime_error("failed to read matrix");
      }
    }

  }

  size_t n_rows = temp.size();

  matrix.resize(n_rows, n_cols, false);

  typedef typename std::list<std::valarray<T> >::const_iterator iter_t;
  iter_t ii = temp.begin();
  for (size_t i = 0; i < n_rows; ++i) {
    for (size_t j = 0; j < n_cols; ++j) {
      matrix(i,j) = (*ii)[j];
    }
    ++ii;
  }
}



template<typename vec_t>
std::pair<double, double> trimmed_mean_sd(const vec_t &v, double discard_fraction) {
  size_t N_disc = (size_t)floor(v.size() * discard_fraction / 2.0);
  if (N_disc == 0) {
    return std::make_pair(
        mean(v, v.size()),
        stddev(v, v.size()));
  } else {
    size_t N_rem = v.size() - 2*N_disc;
    if (N_rem == 0) {
      return std::pair<double, double>(0.0, std::numeric_limits<double>::infinity());
    }
    std::vector<double> trim;
    trim.reserve(v.size());
    std::copy(v.begin(), v.end(), std::back_inserter(trim));
    std::nth_element(trim.begin(), trim.begin() + N_disc, trim.end(), std::less<double>());
    std::nth_element(trim.begin() + N_disc, trim.begin() + 2*N_disc, trim.end(), std::greater<double>());
    return std::make_pair(
        mean(trim.begin() + 2*N_disc, N_rem),
        stddev(trim.begin() + 2*N_disc, N_rem));
  }
}



template<typename vec_t>
void zScoreTransform(vec_t &v) {
  const size_t N = v.size();

  const std::pair<double, double> mean_sd = trimmed_mean_sd(v, .05);
  const double mean = mean_sd.first;
  const double sd = mean_sd.second;

  for (size_t i = 0; i < N; ++i) {
    v[i] = (v[i] - mean) / sd;
  }
}



template<typename vec_t>
void rankTransform(vec_t &v, std::vector<double> &rankvals) {
  const size_t N = v.size();

  std::vector<size_t> indices(N);
  for (size_t i = 0; i < N; ++i) indices[i] = i;

  std::sort(indices.begin(), indices.end(), make_index_cmp(v));

  size_t i = 0;

  while (i < N) {
    size_t j = i;
    double val = 0.0;

    while (j < N && v[indices[j]] == v[indices[i]]) {
      val += rankvals[j++];
    }

    val /= j-i;

    while (i < j) {
      v[indices[i++]] = val;
    }
  }
}



void makeRankVals(std::vector<double> &rankvals, const size_t N) {
  rankvals.resize(N);
  double rs = 0;

  for (size_t i = 0; i < N; ++i) {
    rankvals[i]  = ((i+1)-(N+1)/2.0) / (N/2.0);
    rs += rankvals[i] * rankvals[i];
  }

  rs = 1.0/sqrt(rs);

  for (size_t i = 0; i < N; ++i) {
    rankvals[i] *= rs;
  }
}



void rowZScoreTransform(matrix_t &m) {
  typedef ublas::matrix_row<matrix_t> row_t;
  const size_t N = m.size1();

  for (size_t i = 0; i < N; ++i) {
    row_t r(m, i);
    zScoreTransform(r);
  }
}



void rowRankTransform(matrix_t &m) {
  typedef ublas::matrix_row<matrix_t> row_t;
  const size_t N = m.size1();
  const size_t M = m.size2();

  std::vector<double> rankvals;
  makeRankVals(rankvals, M);

  for (size_t i = 0; i < N; ++i) {
    row_t r(m, i);
    rankTransform(r, rankvals);
  }
}



inline void triIndexToRowCol(size_t index, size_t &row, size_t &col) {
}



template<typename weight_func_t>
void weightMatrix(const matrix_t &m,
                  matrix_t &m_weight,
                  const weight_func_t &weight_func) {
  typedef typename ublas::matrix_row<const matrix_t> row_t;

  const size_t N = m.size1();
  const size_t M = m.size2();

  matrix_t temp(N, N);

#if 1
  const size_t B = 64;
  const int NB = (N + B - 1) / B;

#pragma omp parallel for
  for (int blk = 0; blk < NB * NB; ++blk) {
    size_t j0 = blk / NB;
    size_t i0 = blk - (j0 * NB);
    if (i0 > j0) continue;

    i0 *= B;
    j0 *= B;

    for (size_t i = i0; i < i0 + B; ++i) {
      for (size_t j = j0; j < j0 + B; ++j) {
        if (i <= j && j < N) {
          temp(i,j) = temp(j,i) = weight_func(row_t(m, i), row_t(m, j), M);
        }
      }
    }
  }
#else
#pragma omp parallel for
  for (int i = 0; i < (int)N; ++i) {
    for (int j = i; j < (int)N; ++j) {
      temp(i,j) = temp(j,i) = weight_func(row_t(m, i), row_t(m, j), M);
    }
  }
#endif

  m_weight.swap(temp);
}



// c.f. WGCNA
// Assumes that entries in m_dist are [0,1], where 1 is connected and 0 is unconnected.

// WGCNA = (sum(a_iu.a_uj) + a_ij) / (min(sum(a_iu), sum(a_ju)) + 1 - a_ij)

void topologicalOverlap(const matrix_t &m_dist,
                        matrix_t &m_topo) {
  typedef ublas::matrix_row<const matrix_t> row_t;
  typedef ublas::matrix_column<const matrix_t> col_t;

  const size_t N = m_dist.size1();

  std::vector<double> row_sums(N, 0.0);

  matrix_t temp(N,N);

  noalias(temp) = prod(m_dist, m_dist);

  for (size_t i = 0; i < N; ++i) {
    row_t r(m_dist, i);
    row_sums[i] = std::accumulate(r.begin(), r.end(), 0.0);
  }

  temp(0,0) = 1.0;
  for (size_t i = 1; i < N; ++i) {
    temp(i,i) = 1.0;
    for (size_t j = 0; j < i; ++j) {
      temp(i,j) = (temp(i,j) + m_dist(i,j)) / (std::min(row_sums[i], row_sums[j]) + 1  - m_dist(i,j));
      assert(temp(i,j) >= 0 && temp(i,j) <= 1);
      temp(j,i) = temp(i,j);
    }
  }

  m_topo.swap(temp);
}



class root_finder : public boost::default_dfs_visitor {
public:
  std::vector<size_t> &dc;
  size_t &best_root;
  size_t &max_score;

  root_finder(std::vector<size_t> &_dc, size_t &_best_root, size_t &_max_score) : dc(_dc), best_root(_best_root), max_score(_max_score) {
    best_root = max_score = 0;
  }

  void finish_vertex(size_t u, const undirected_graph_t &g) {
    boost::graph_traits<undirected_graph_t>::adjacency_iterator i, ei;
    tie(i, ei) = adjacent_vertices(u, g);
    dc[u] = 1;

    bool root = true;

    size_t score = 0;

    while (i != ei) {
      size_t v = *i++;
      if (!dc[v]) {
        root = false;
      } else {
        dc[u] += dc[v];
        score += std::min(dc[v], num_vertices(g) - dc[v]);
      }
    }

    if (!root) {
      score += std::min(dc[u], num_vertices(g) - dc[u]);
    }

    if (score > max_score) {
      max_score = score;
      best_root = u;
    }
  }
};



size_t pickRootNode(const undirected_graph_t &mst) {
  size_t max_score, best_root;
  std::vector<size_t> descendant_count(num_vertices(mst), 0);
  root_finder vis(descendant_count, best_root, max_score);
  boost::depth_first_search(mst, boost::visitor(vis));
  return best_root;
}



size_t pickRootNode(const matrix_t &m_dist) {
  typedef ublas::matrix_row<const matrix_t> row_t;

  const size_t N = m_dist.size1();

  double best = 0.0;
  size_t best_i = 0;

  {
    best_i = 0;
    row_t r(m_dist, 0);
    best = std::accumulate(r.begin(), r.end(), 0.0);
  }

  for (size_t i = 1; i < N; ++i) {
    row_t r(m_dist, i);
    double sum = std::accumulate(r.begin(), r.end(), 0.0);
    if (sum < best) {
      best = sum;
      best_i = i;
    }
  }

  return best_i;
}



struct edge_expander : public boost::default_dfs_visitor {
  size_t root;
  const matrix_t &m_dist;
  double expansion_factor;
  undirected_graph_t &result;
  std::vector<double> path;
  std::vector<double> worst;

  edge_expander(size_t _root,
                const matrix_t &_m_dist,
                double _expansion_factor,
                undirected_graph_t &_result) :
      root(_root),
      m_dist(_m_dist),
      expansion_factor(_expansion_factor),
      result(_result),
      path(),
      worst() {
    path.reserve(m_dist.size1());
    worst.reserve(m_dist.size1() + 1);
    worst.push_back(0.0);
  }

  void tree_edge(const boost::graph_traits<undirected_graph_t>::edge_descriptor &e, const undirected_graph_t &g) {
    double d;
    path.push_back(d = m_dist(source(e, g), target(e, g)));
    worst.push_back(std::max(worst.back(), d));
  }

  void finish_vertex(size_t u, const undirected_graph_t &g) {
    if (root < u && path.size() > 1) {
      double d_direct = m_dist(root, u);
      double d_path = worst.back();
      double d_max = pow(1-d_path, 1.0/expansion_factor) * expansion_factor + d_path;
      // double d_max = d_path + expansion_factor;
      // double d_max = d_path * expansion_factor;
      if (d_direct < d_max) {
        std::cerr << "#expand " << path.size() << " " << d_direct << " " << worst.back() << std::endl;
        boost::add_edge(root, u, result);
      }
    }
    if (path.size()) {
      path.pop_back();
    }
    worst.pop_back();
  }
};



void expandMST(const undirected_graph_t &mst,
               const matrix_t &m_dist,
               double expansion_factor,
               undirected_graph_t &expanded) {
  expanded = mst;
  for (size_t root = 0; root < num_vertices(mst); ++root) {
    edge_expander vis(root, m_dist, expansion_factor, expanded);
    boost::depth_first_search(mst, boost::root_vertex(root).visitor(vis));
  }
}



struct edge_heap_comparator {
  const matrix_t &m_dist;

  edge_heap_comparator(const matrix_t &_m_dist) : m_dist(_m_dist) {
  }

  bool operator()(size_t a, size_t b) const {
    return m_dist.data()[b] < m_dist.data()[a];
  }
};



// #include "graph_layout.hpp"



void kruskalMST(const matrix_t &m_dist, undirected_graph_t &graph) {
  const size_t N = m_dist.size1();
  size_t c, r;

  djset::djset set(N);

  std::vector<size_t> edge_heap;

  edge_heap_comparator heap_cmp(m_dist);

  edge_heap.reserve(N * (N-1) / 2);
  for (size_t r = 1; r < N; ++r) {
    for (size_t c = 0; c < r; ++c) {
      edge_heap.push_back(&m_dist(r,c) - &m_dist(0,0));
    }
  }

  std::make_heap(edge_heap.begin(), edge_heap.end(), heap_cmp);

  undirected_graph_t temp(N);

  for (size_t i = 0; i < N-1; ++i) {
    do {
      assert(edge_heap.size());
      std::pop_heap(edge_heap.begin(), edge_heap.end(), heap_cmp);
      size_t e = edge_heap.back();

      r = e / N;
      c = e - (r * N);

      assert((size_t)(&m_dist(r,c) - &m_dist(0,0)) == e);

      edge_heap.pop_back();
    } while (set.same_set(c, r));

    set.merge_sets(c, r);
    add_edge(r, c, temp);
  }

  graph.swap(temp);
}



namespace metric {
  namespace weight {
    struct random {
      random(const matrix_t &) {
        unsigned int seed;
        int fd = open("/dev/random", O_RDONLY);
        read(fd, &seed, sizeof(seed));
        close(fd);
        srandom(seed);
      }
  
      template<typename vec_t>
      double operator()(const vec_t &a,
                        const vec_t &b,
                        size_t sz) const {
        return double(::random()) / RAND_MAX;
      }
    };
  
    struct euclidean {
      euclidean(const matrix_t &) { }

      template<typename vec_t>
      double operator()(const vec_t &a,
                        const vec_t &b,
                        size_t sz) const {
        return ::euclideanDistance(a, b, sz);
      }
    };
  
    struct dotprod {
      dotprod(const matrix_t &) { }

      template<typename vec_t>
      double operator()(const vec_t &a,
                        const vec_t &b,
                        size_t sz) const {
        return ::dotprod(a, b, sz);
      }
    };
  
    struct pearson_corr {
      pearson_corr(const matrix_t &) { }

      template<typename vec_t>
      double operator()(const vec_t &a,
                        const vec_t &b,
                        size_t sz) const {
        return ::pearson_corr(a, b, sz);
      }
    };
  
    struct mahalanobis {
      matrix_t cov;
      matrix_t inv_cov;
      mahalanobis(const matrix_t &m) : cov(m.size2(), m.size2()) {
        typedef ublas::matrix_column<const matrix_t> col_t;

        const size_t N = m.size2();

        for (size_t i = 0; i < N; ++i) {
          for (size_t j = 0; j <= i; ++j) {
            cov(i,j) = cov(j, i) = covariance(col_t(m, i), col_t(m, j), m.size1());
          }
        }
        invertMatrix(cov, inv_cov);
      }

      template<typename vec_t>
      double operator()(const vec_t &a,
                        const vec_t &b,
                        size_t sz) const {

        return sqrt(inner_prod(prod(a, inv_cov), b));
      }
    };
  }

  namespace transform {
    struct identity {
      void transform(matrix_t &mat) { }
    };
  
    struct zscore {
      void transform(matrix_t &mat) { rowZScoreTransform(mat); }
    };

    struct rank {
      void transform(matrix_t &mat) { rowRankTransform(mat); }
    };
  }
}



struct xform_abs { double operator()(double x) const { return fabs(x); } };
struct xform_clip { double operator()(double x) const { return std::max(0.0, x); } };
struct xform_scale { double operator()(double x) const { return (1 + x) / 2; } };

struct xform_half { double operator()(double x) const { return x / 2; } };
struct xform_inv { double operator()(double x) const { return 1 - x; } };

struct xform_abs_inv { double operator()(double x) const { return 1 - fabs(x); } };
struct xform_clip_inv { double operator()(double x) const { return 1 - std::max(0.0, x); } };
struct xform_scale_inv { double operator()(double x) const { return (1 - x) / 2; } };

struct xform_power { double p; xform_power(double _p) : p(_p) {} double operator()(double x) const { return pow(x, p); } };



struct tanh_transform {
  double scale;

  tanh_transform(double _scale) : scale(_scale) {
  }

  double operator()(double x) const {
    return tanh(x*scale);
  }
};



double medianWeight(const matrix_t &wm) {
  const size_t N = wm.size1();
  const size_t N2 = N>>1;

  std::vector<double> wm_vals;
  wm_vals.reserve(N * (N-1) / 2);

  for (size_t r = 1; r < N; ++r) {
    for (size_t c = 0; c < r; ++c) {
      wm_vals.push_back(wm(r,c));
    }
  }

  if (N & 1) {
    std::nth_element(wm_vals.begin(), wm_vals.begin() + N2, wm_vals.end());
    return wm_vals[N2];
  } else {
    nth_element(wm_vals.begin(), wm_vals.begin() + N2 - 1, wm_vals.end());
    double v1 = wm_vals[N2 - 1];
    return (v1 + *min_element(wm_vals.begin() + N2, wm_vals.end())) / 2;
  }
}



template<typename map_t>
void transformMatrix(const matrix_t &wm, matrix_t &dm, map_t map) {
  const size_t N = wm.size1();

  if (&wm != &dm) {
    matrix_t temp(N,N);
    dm.swap(temp);
  }

#pragma omp parallel for
  for (int i = 0; i < (int)N; ++i) {
    for (int j = 0; j < (int)N; ++j) {
      dm(i,j) = map(wm(i,j));
    }
    dm(i,i) = 0.0;
  }
}



//              Untransformed identity distmetric?        Rank-transformed identity distmetric?
// Euclidean:   [0, +inf)     0        y                  [0, 2]           0        y          
// Mahalanobis: [0, +inf)     0        y                  [0, 2] ?         0        y          
// Random:      [0, 1]        0        y                  [0, 1]           0        y          
// Dot prod:    (-inf, +inf)  +inf     n                  [-1, 1]          +1       n          
// Pearson      [-1, 1]       +1       n                  [-1, 1]          +1       n          

// tanh(x/median(x)) : (-inf, +inf) -> (-1, +1)

// rank-transformed euclidean distance has median=sqrt(2) (assuming random distribution on sphere)

struct Options : public opt::Parser {
  std::string matrix;
  std::string weight_file;
  std::string dist_file;
  std::string graph_file;
  bool expand;
  double expansion_factor;
  double weight_power;
  size_t id_col;
  size_t data_col;
  size_t probe_count;

  enum WeightFunc { PEARSON, EUCLIDEAN, DOTPROD, MAHALANOBIS, RANDOM } weight_func;
  enum SelectFunc { SF_VARIANCE, SF_MEAN, SF_MAX, SF_NONE } select_func;
  enum ExprTransformFunc { ET_RANK, ET_ZSCORE, ET_NONE } expr_transform;
  enum SimilarityTransform { ST_ABS, ST_CLIP, ST_SCALE, ST_NONE } similarity_transform;

  // a similarity measure has 1 as similar, 0 as dissimilar. (-1 as anti-similar)
  // a dissimilarity measure has 0 as similar, 1 as dissimilar. (-1 as ???)

  // ST_ABS: 1 - fabs(x)
  // ST_CLIP: 1 - max(x, 0)       
  // ST_SCALE: 1 - (1+x)/2

  opt::Enum<WeightFunc> wf_enum;
  opt::Enum<SelectFunc> sf_enum;
  opt::Enum<ExprTransformFunc> et_enum;
  opt::Enum<SimilarityTransform> st_enum;

  bool tanh_transform;
  bool TOM_transform;

  bool layout;

  virtual void optval(const std::string &o, const std::string &v) {
    if (o == "--help"                 || o == "-h") { help(std::cout); exit(0); }
    if (o == "--matrix"               || o == "-m") { matrix = v; return; }
    if (o == "--expr-transform"       || o == "-x") { expr_transform = et_enum(v); return; }
    if (o == "--save-distances"       || o == "-D") { dist_file = v; return; }
    if (o == "--save-weights"         || o == "-W") { weight_file = v; return; }
    if (o == "--weight-func"          || o == "-w") { weight_func = wf_enum(v); return; }
    if (o == "--tanh-transform"       || o == "-t") { tanh_transform = true; return; }
    if (o == "--weight-power"         || o == "-P") { weight_power = strtod(v.c_str(), NULL); return; }
    if (o == "--TOM-transform"        || o == "-T") { TOM_transform = true; return; }
    if (o == "--similarity-transform" || o == "-s") { similarity_transform = st_enum(v); return; }
    if (o == "--expand"               || o == "-e") { expand = true; return; }
    if (o == "--expansion-factor"     || o == "-E") { expansion_factor = strtod(v.c_str(), NULL); return; }
    if (o == "--layout"               || o == "-l") { layout = true; return; }
    if (o == "--save-graph"           || o == "-g") { graph_file = v; return; }
    if (o == "--id-col"               || o == "-i") { id_col = strtoul(v.c_str(), NULL, 10); return; }
    if (o == "--data-col"             || o == "-d") { data_col = strtoul(v.c_str(), NULL, 10); return; }
    if (o == "--n-probes"             || o == "-n") { probe_count = strtoul(v.c_str(), NULL, 10); return; }
    if (o == "--select-probes"        || o == "-p") { select_func = sf_enum(v); return; }
  }

  virtual void done() {
    if (tanh_transform) {
      if (expr_transform == ET_RANK ||
          weight_func == PEARSON ||
          weight_func == RANDOM) {
        throw opt::exception() << "tanh transformation only makes sense for unbounded weights.";
      }
    }

    bool is_sim = (weight_func == PEARSON || weight_func == DOTPROD);

    if (!probe_count && select_func != SF_NONE) {
      throw opt::exception() << "must specify a number of probes to select.";
    }

    if (probe_count && select_func == SF_NONE) {
      throw opt::exception() << "must specify a probe selection function.";
    }

    if (similarity_transform == ST_NONE) {
      if (is_sim) throw opt::exception() << "must specify a similarity transform (-s).";
    } else {
      if (!is_sim) throw opt::exception() << "must not specify a similarity transform.";
      if (weight_func == DOTPROD &&
          similarity_transform == ST_SCALE &&
          !tanh_transform) {
        throw opt::exception() << "similarity-transform=scale does not make sense with dot-product weights unless tanh transformation is specified.";
      }
    }

    // if we get this far, we have a way of getting a dissimilarity measure.

    if (TOM_transform || weight_power != 1.0) {
      // we can only TOM transform or raise weights to a power if we can create a [0,1] similarity matrix.
      bool std_sim = true;
      switch (weight_func) {
        case RANDOM:
        case PEARSON:
          // ok
          break;
        case EUCLIDEAN:
        case MAHALANOBIS:
          std_sim = tanh_transform;
          break;
        case DOTPROD:
          std_sim = tanh_transform || (expr_transform == ET_RANK);
          break;
      }

      if (!std_sim) {
        if (TOM_transform)       throw opt::exception() << "topological overlap metric requires a [0,1] similarity measure.";
        if (weight_power != 1.0) throw opt::exception() << "power transform requires a [0,1] similarity measure.";
      }
    }
  }

  Options() {
    matrix = "";
    dist_file = "";
    weight_file = "";
    graph_file = "";
    expr_transform = ET_NONE;
    weight_func = PEARSON;
    tanh_transform = false;
    TOM_transform = false;
    layout = false;
    expr_transform = ET_NONE;
    similarity_transform = ST_NONE;
    expand = false;
    expansion_factor = 1.01;
    weight_power = 1.0;
    id_col = 0;
    data_col = 1;
    probe_count = 0;
    select_func = SF_NONE;

    wf_enum["pearson"]     = PEARSON;
    wf_enum["euclidean"]   = EUCLIDEAN,
    wf_enum["dotprod"]     = DOTPROD,
    wf_enum["mahalanobis"] = MAHALANOBIS,
    wf_enum["random"]      = RANDOM,

    sf_enum["max"]         = SF_MAX;
    sf_enum["mean"]        = SF_MEAN;
    sf_enum["variance"]    = SF_VARIANCE;

    et_enum["z-score"]     = ET_ZSCORE;
    et_enum["rank"]        = ET_RANK;

    st_enum["abs"]         = ST_ABS;
    st_enum["clip"]        = ST_CLIP;
    st_enum["scale"]       = ST_SCALE;

    option("help",                  'h', false,              "help text");
    option("matrix",                'm', true,               "input expression matrix");
    option("rank",                  'r', false,              "rank transform input expression values");
    option("save-weights",          'W', true,               "save weight matrix to file");
    option("save-distances",        'D', true,               "save distance matrix to file");
    option("weight-func",           'w', true,               "function for weight calculation");
    option("tanh-transform",        't', false,              "tanh-transform weights");
    option("weight-power",          'P', true,               "power to which to raise weights prior to TOM/graph generation");
    option("TOM-transform",         'T', false,              "apply topological overlap metric transform");
    option("similarity-transform",  's', true,               "choose mapping from similarity to dissimilarity metric");
    option("expand",                'e', false,              "expand the MST based upon nearly minimum edges");
    option("expansion-factor",      'E', true,               "the factor for MST expansion (>1).");
    option("layout",                'l', false,              "perform graph layout");
    option("save-graph",            'g', true,               "save graph to file");
    option("id-col",                'i', true,               "column in input matrix containing identifiers");
    option("data-col",              'd', true,               "first column in input matrix containing expression values");
    option("n-probes",              'n', true,               "select top n probes");
    option("select-probes",         'p', true,               "probe selection function");
  }
};

static Options options;


int main(int argc, char **argv) {
  if (!options.parse(argc, argv)) exit(1);

  matrix_t m;
  std::vector<std::string> m_rows, m_cols;

  if (options.matrix != "") {
    std::cerr << "reading matrix file [" << options.matrix << "]" << std::endl;
    std::ifstream mat(options.matrix.c_str());
    if (!mat.good()) {
      std::cerr << "unable to open matrix file [" << options.matrix << "]" << std::endl;
      exit(1);
    }

    readMatrix(mat, options.id_col, options.data_col, m, m_rows, m_cols);
  } else {
    std::cerr << "reading matrix file [stdin]" << std::endl;
    readMatrix(std::cin, options.id_col, options.data_col, m, m_rows, m_cols);
  }
  std::cerr << "reading matrix file done" << std::endl;

  if (options.probe_count) {
    std::vector<size_t> selected_rows;
    selected_rows.reserve(options.probe_count);
    switch (options.select_func) {
      case Options::SF_MAX:
        selectRows(m, options.probe_count, selected_rows, rowMax());
        takeRows(m, m_rows, selected_rows);
        break;
      case Options::SF_MEAN:
        selectRows(m, options.probe_count, selected_rows, rowMean());
        takeRows(m, m_rows, selected_rows);
        break;
      case Options::SF_VARIANCE:
        selectRows(m, options.probe_count, selected_rows, rowVariance());
        takeRows(m, m_rows, selected_rows);
        break;
      case Options::SF_NONE:
        break;
    }
  }

  std::cerr << "operating on " << m_rows.size() << " rows" << std::endl;

  switch (options.expr_transform) {
    case Options::ET_NONE: {
      break;
    }
    case Options::ET_RANK: {
      std::cerr << "rank transform" << std::endl;
      metric::transform::rank().transform(m);
      break;
    }
    case Options::ET_ZSCORE: {
      std::cerr << "z-score transform" << std::endl;
      metric::transform::zscore().transform(m);
      break;
    }
  }

  matrix_t m_weight;

  std::cerr << "weight matrix" << std::endl;
  // compute weight matrix
  switch (options.weight_func) {
    case Options::PEARSON:
      weightMatrix(m, m_weight, metric::weight::pearson_corr(m));
      break;
    case Options::EUCLIDEAN:
      weightMatrix(m, m_weight, metric::weight::euclidean(m));
      break;
    case Options::DOTPROD:
      weightMatrix(m, m_weight, metric::weight::dotprod(m));
      break;
    case Options::MAHALANOBIS:
      weightMatrix(m, m_weight, metric::weight::mahalanobis(m));
      break;
    case Options::RANDOM:
      weightMatrix(m, m_weight, metric::weight::random(m));
      break;
  }

  if (options.weight_file != "") {
    std::cerr << "write weight matrix" << std::endl;
    std::ofstream out(options.weight_file.c_str());
    if (!out.good()) {
      std::cerr << "could not write weight matrix to file [" << options.weight_file << "]" << std::endl;
    } else {
      out << std::setprecision(30);
      writeMatrix(out, m_weight, m_rows, m_rows);
    }
  }

  if (options.tanh_transform) {
    std::cerr << "tanh transform" << std::endl;
    transformMatrix(m_weight, m_weight, tanh_transform(medianWeight(m_weight)));
  }

  if (options.TOM_transform || options.weight_power != 1.0) {
    // convert to similarity measure
    std::cerr << "similarity transform" << std::endl;
    switch (options.similarity_transform) {
      case Options::ST_ABS:
        transformMatrix(m_weight, m_weight, xform_abs());
        break;
      case Options::ST_CLIP:
        transformMatrix(m_weight, m_weight, xform_clip());
        break;
      case Options::ST_SCALE:
        transformMatrix(m_weight, m_weight, xform_scale());
        break;
      case Options::ST_NONE:
        transformMatrix(m_weight, m_weight, xform_inv());
        break;
    }

    if (options.weight_power != 1.0) {
      std::cerr << "power transform" << std::endl;
      transformMatrix(m_weight, m_weight, xform_power(options.weight_power));
    }

    // topological overlap
    if (options.TOM_transform) {
      std::cerr << "topological overlap" << std::endl;
      topologicalOverlap(m_weight, m_weight);
    }

    std::cerr << "similarity transform (2)" << std::endl;
    // convert back to dissimilarity measure
    transformMatrix(m_weight, m_weight, xform_inv());
  } else {
    std::cerr << "similarity transform" << std::endl;
    switch (options.similarity_transform) {
      case Options::ST_ABS:
        transformMatrix(m_weight, m_weight, xform_abs_inv());
        break;
      case Options::ST_CLIP:
        transformMatrix(m_weight, m_weight, xform_clip_inv());
        break;
      case Options::ST_SCALE:
        transformMatrix(m_weight, m_weight, xform_scale_inv());
        break;
      case Options::ST_NONE:
        break;
    }
  }


  if (options.dist_file != "") {
    std::cerr << "write distance matrix" << std::endl;
    std::ofstream out(options.dist_file.c_str());
    if (!out.good()) {
      std::cerr << "could not write weight matrix to file [" << options.dist_file << "]" << std::endl;
    } else {
      out << std::setprecision(30);
      writeMatrix(out, m_weight, m_rows, m_rows);
    }
  }

  std::cerr << "minimum spanning tree" << std::endl;

  undirected_graph_t mst;
  kruskalMST(m_weight, mst);

  size_t root;

  root = pickRootNode(m_weight);
  std::cerr << "root (method 1): " << m_rows[root] << std::endl;

  root = pickRootNode(mst);
  std::cerr << "root (method 2): " << m_rows[root] << std::endl;

  undirected_graph_t graph;

  if (options.expand) {
    expandMST(mst, m_weight, options.expansion_factor, graph);
    std::cerr << "#expanded edge count: " << num_edges(graph) << " (delta = " << num_edges(graph) - num_edges(mst) << ")" << std::endl;
  } else {
    graph = mst;
  }

  // if (options.layout) {
  //   layout::GraphLayout<3> layout(graph, root);
  //   layout.run();
  // }

  if (options.graph_file != "") {
    std::ofstream out(options.graph_file.c_str());
    out << "p edge " << num_vertices(graph) << " " << num_edges(graph) << std::endl;
    for (size_t i = 0; i < num_vertices(graph); ++i) {
      out << "n " << i+1 << " id=" << m_rows[i] << std::endl;
    }
    typedef boost::graph_traits<undirected_graph_t>::edge_iterator edge_iterator;
    edge_iterator e, e_end;
    for (tie(e, e_end) = edges(graph); e != e_end; ++e) {
      size_t u = source(*e, graph);
      size_t v = target(*e, graph);
      out << "e " << u+1 << " " << v+1 << " weight=" << m_weight(u,v) << std::endl;
    }
  }

  return 0;
}
