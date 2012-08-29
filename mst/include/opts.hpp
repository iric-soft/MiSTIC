// Copyright 2006 Tobias Sargeant (toby@permuted.net).
// All rights reserved.

#pragma once

#include <string>
#include <list>
#include <vector>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <map>

#include "stringfuncs.hpp"

namespace opt {
  class Parser;



  struct exception {
  private:
    mutable std::string err;
    mutable std::ostringstream accum;

  public:
    exception(const std::string &e) : err(e), accum() { }
    exception() : err(), accum() { }
    exception(const exception &e) : err(e.str()), accum() { }

    const std::string &str() const {
      if (accum.tellp()) {
        err = accum.str();
        accum.str("");
      }
      return err;
    }

    template<typename T>
    exception &operator<<(const T &t) {
      accum << t;
      return *this;
    }
  };



  struct Help {
    std::string long_opt;
    std::string short_opt;
    bool arg;
    std::string text;
    Help(const std::string &_long_opt, const std::string &_short_opt, bool _arg, const std::string &_text) :
        long_opt(_long_opt), short_opt(_short_opt), arg(_arg), text(_text) {
    }
  };



  template<typename val_t>
  struct Enum {
    typedef val_t value_t;
    std::map<std::string, val_t> enum_vals;

    val_t &operator[](const std::string &str) {
      return enum_vals[str];
    }

    val_t operator()(const std::string &str) const {
      typename std::map<std::string, val_t>::const_iterator i = enum_vals.find(str);
      if (i == enum_vals.end()) {
        throw exception() << "invalid argument -  " << str << ".";
      }
      return (*i).second;
    }
  };



  struct Opt {
    std::string str;
    bool arg;
    std::string help;

    virtual ~Opt() {
    }

    virtual void process(const std::string &opt, const std::string &arg, Parser &parser);

    Opt(const std::string &_str, bool _arg, const std::string &_help) : str(_str), arg(_arg), help(_help) {}
    Opt(char _ch, bool _arg, const std::string &_help) : str(1, _ch), arg(_arg), help(_help) {}
  };



  class Parser {
  protected:
    std::list<Opt *> short_opts;
    std::list<Opt *> long_opts;
    std::list<Help> help_text;

    std::string progname;

    virtual void help(std::ostream &out) {
      size_t max_long = 0;
      size_t max_short = 0;
      for (std::list<Help>::iterator i = help_text.begin(); i != help_text.end(); ++i) {
        max_long = std::max(max_long, (*i).long_opt.size());
        max_short = std::max(max_short, (*i).short_opt.size());
      }

      out << usageStr() << std::endl;
      out << std::setfill(' ');
      for (std::list<Help>::iterator i = help_text.begin(); i != help_text.end(); ++i) {
        out.setf(std::ios::left);
        out << std::setw(max_long + 1) << (*i).long_opt << std::setw(max_short + 1) << (*i).short_opt;
        if ((*i).arg) {
          out << "{arg} ";
        } else {
          out << "      ";
        }
        out << (*i).text << std::endl;
      }
    }

    virtual std::string usageStr() {
      return std::string ("Usage: ") + progname + std::string(" [options] [args]");
    };

    void long_opt(std::vector<std::string>::const_iterator &i, const std::vector<std::string>::const_iterator &e) {
      const std::string &a(*i);
      std::string opt, val;
      bool has_argopt;

      std::string::size_type eq = a.find('=');
      has_argopt = eq != std::string::npos;
      if (has_argopt) {
        opt = a.substr(2, eq - 2);
        val = a.substr(eq + 1);
      } else {
        opt = a.substr(2);
        val = "";
      }
      for (std::list<Opt *>::iterator o = long_opts.begin(), oe = long_opts.end(); o != oe; ++o) {
        if ((*o)->str == opt) {
          if (!(*o)->arg && has_argopt) throw exception() << "unexpected argument for option --" << (*o)->str << ".";
          if ((*o)->arg) {
            if (++i == e) throw exception() << "missing argument for option --" << (*o)->str << ".";
            val = *i;
          }
          (*o)->process("--" + opt, val, *this);
          // optval("--" + opt, val);
          ++i;
          return;
        }
      }
      throw exception() << "unrecognised option --" << opt << ".";
    }

    void short_opt(std::vector<std::string>::const_iterator &i, const std::vector<std::string>::const_iterator &e) {
      const std::string &a(*i);
      
      for (std::string::size_type j = 1; j < a.size(); ++j) {
        std::string opt = a.substr(j, 1);
        for (std::list<Opt *>::iterator o = short_opts.begin(), oe = short_opts.end(); o != oe; ++o) {
          if ((*o)->str == opt) {
            if ((*o)->arg) {
              if (j < a.size() - 1) {
                (*o)->process("-" + opt, a.substr(j + 1), *this);
                j = a.size() - 1;
              } else {
                if (++i == e) throw exception() << "missing argument for option -" << a[j] << ".";
                (*o)->process("-" + opt, *i, *this);
              }
            } else {
              (*o)->process("-" + opt, "", *this);
            }
            goto found;
          }
        }
        throw exception() << "unrecognised option -" << a[j] << ".";
      found:;
      }
      ++i;
    }

  public:
    Parser() {
    }

    virtual ~Parser() {
      for (std::list<Opt *>::iterator i = short_opts.begin(); i != short_opts.end(); ++i) delete *i;
      for (std::list<Opt *>::iterator i =  long_opts.begin(); i !=  long_opts.end(); ++i) delete *i;
    }

    Parser &option(const std::string &str, char ch, bool arg, const std::string &help) {
      long_opts.push_back(new Opt(str, arg, help));
      short_opts.push_back(new Opt(ch, arg, help));
      help_text.push_back(Help("--" + str, std::string("-") + ch, arg, help));
      return *this;
    }

    Parser &option(const std::string &str, bool arg, const std::string &help) {
      long_opts.push_back(new Opt(str, arg, help));
      help_text.push_back(Help("--" + str, "", arg, help));
      return *this;
    }

    Parser &option(char ch, bool arg, const std::string &help) {
      short_opts.push_back(new Opt(ch, arg, help));
      help_text.push_back(Help("", std::string("-") + ch, arg, help));
      return *this;
    }

    virtual void optval(const std::string &o, const std::string &v) {
    }

    virtual void arg(const std::string &a) {
    }

    virtual void done() {
    }

    bool parse(const std::string &pn, const std::vector<std::string> &opts) {
      try {
        progname = pn;
        std::vector<std::string>::const_iterator i = opts.begin();
        std::vector<std::string>::const_iterator e = opts.end();
        while (i != e) {
          const std::string &a(*i);
          if (a[0] == '-') {
            if (a == "-" || a == "--") { ++i; break; }
            if (a[1] == '-') {
              long_opt(i, e);
            } else {
              short_opt(i, e);
            }
          } else {
            break;
          }
        }
        while (i != e) { arg(*i++); }
        done();
        return true;
      } catch (exception e) {
        std::cerr << e.str() << std::endl;
        help(std::cerr);
        return false;
      }
    }

    bool parse(int argc, char **argv) {
      std::vector<std::string> opts(argc-1);
      for (int i = 1; i < argc; ++i) {
        opts[i-1] = argv[i];
      }
      return parse(argv[0], opts);
    }
  };



  inline void Opt::process(const std::string &opt, const std::string &arg, Parser &parser) {
    parser.optval(opt, arg);
  }
}
