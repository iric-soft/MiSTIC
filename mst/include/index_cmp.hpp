#pragma once

template<typename seq_t>
struct index_cmp {
  const seq_t &seq;
  index_cmp(const seq_t &_seq) : seq(_seq) {}
  bool operator()(size_t a, size_t b) { return seq[a] < seq[b]; }
};

template<typename seq_t>
index_cmp<seq_t> make_index_cmp(const seq_t &seq) { return index_cmp<seq_t>(seq); }



