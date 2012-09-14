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
  logging.config.fileConfig(config, defaults)

  cache_opts = {
    'cache.type': 'memory',
    'cache.regions': 'mistic',
    'cache.mistic.expire': 300
    }

  cache = CacheManager(**parse_cache_config_options(cache_opts))

  return result

__all__ = [
  'read_config'
]
