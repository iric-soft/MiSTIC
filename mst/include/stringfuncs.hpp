#pragma once

#include <string>
#include <vector>

namespace str {
  static inline void makelower(std::string &r) {
    for (std::string::size_type i = 0; i < r.size(); i++) r[i] = tolower(r[i]);
  }
  
  static inline std::string lower(const std::string &s) {
    std::string r = s;
    makelower(r);
    return r;
  }
  
  static inline void makeupper(std::string &r) {
    for (std::string::size_type i = 0; i < r.size(); i++) r[i] = toupper(r[i]);
  }
  
  static inline std::string upper(const std::string &s) {
    std::string r = s;
    makeupper(r);
    return r;
  }
  
  static inline std::string replace(const std::string &s, const std::string &m, const std::string &r) {
    std::string::size_type i = 0;
    std::string o;
    while (1) {
      std::string::size_type j = s.find(m, i);
      if (j == std::string::npos) {
        o.append(s, i, s.size() - i);
        return o;
      } else {
        o.append(s, i, j - i);
        o.append(r);
        i = j + m.size();
      }
    }
  }
  
  template<typename _CharT, typename _Traits, typename _Alloc>
  static inline std::basic_string<_CharT, _Traits, _Alloc> strip(const std::basic_string<_CharT, _Traits, _Alloc> &s) {
    int x, y;
    for (x = 0; x < (int)s.size() && std::isspace(s[x]); x++);
    for (y = (int)s.size() - 1; y >=0 && std::isspace(s[y]); y--);
    return std::basic_string<_CharT, _Traits, _Alloc>(s, x, y - x + 1);
  }
  
  template<typename _CharT, typename _Traits, typename _Alloc>
  static inline std::vector<std::basic_string<_CharT, _Traits, _Alloc> > split(const std::basic_string<_CharT, _Traits, _Alloc> &s,
                                                                               _CharT split,
                                                                               int nsplits = -1) {
    typedef std::basic_string<_CharT, _Traits, _Alloc> string_type;
  
    std::vector<string_type> result;
    int x = 0, rx = 0;
    while (x < (int)s.size()) {
      if (s[x] == (_CharT)split) {
        result.push_back(string_type(s, rx, x - rx));
        rx = x + 1;
        if (!--nsplits) {
          result.push_back(string_type(s, rx));
          return result;
        }
      }
      x++;
    }
    if (rx < (int)s.size()) {
      result.push_back(string_type(s, rx));
    }
    return result;
  }
  
  template<typename _CharT, typename _Traits, typename _Alloc>
  static inline std::vector<std::basic_string<_CharT, _Traits, _Alloc> > split(const std::basic_string<_CharT, _Traits, _Alloc> &s,
                                                                               int nsplits = -1) {
    typedef std::basic_string<_CharT, _Traits, _Alloc> string_type;
  
    std::vector<string_type> result;
    int x = 0, rx = 0;
  
    int y = (int)s.size() - 1;
    while (std::isspace(s[x])) x++;
    rx = x;
    while (y >= 0 && isspace(s[y])) y--;
    y++;
  
    while (x < y) {
      if (std::isspace(s[x])) {
        result.push_back(string_type(s, rx, x - rx));
        while (x < y && std::isspace(s[x])) x++;
        rx = x;
        if (!--nsplits) {
          result.push_back(string_type(s, rx));
          return result;
        }
      } else {
        x++;
      }
    }
    if (rx != y) {
      result.push_back(string_type(s, rx, y - rx));
    }
    return result;
  }
}
