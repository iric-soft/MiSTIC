import ConfigParser
import logging.config
from beaker.cache import CacheManager
from beaker.util import parse_cache_config_options

def read_config(config, section, defaults):
  result = {}

  p = ConfigParser.ConfigParser(defaults = defaults)
  p.readfp(config)

  if p.has_section(section):
    for key, value in p.items(section):
      if key.endswith('__eval__'):
        result[key[:-len('__eval__')]] = eval(value)
      else:
        result[key] = value

  config.seek(0, 0)

  return result

def init_logging(config, defaults):
  logging.config.fileConfig(config, defaults)

  config.seek(0, 0)

def init_beaker_cache():
  cache_opts = {
    'cache.type': 'memory',
    'cache.regions': 'mistic',
    'cache.mistic.expire': 300
    }

  cache = CacheManager(**parse_cache_config_options(cache_opts))

__all__ = [
  'read_config',
  'init_logging',
  'init_beaker_cache'
]
