# -*- python-indent: 2 -*-
"""
Helper functions for beaker caching.
"""

from beaker.cache import *
import logging

logger = logging.getLogger(__name__)

def warnonce(s, emitted = set()):
  if s in emitted:
    return
  emitted.add(s)
  logger.warn(s)


def stringify_key(cache_key):
  if type(cache_key) in (tuple, list):
    try:
      return " ".join(map(str, cache_key))
    except UnicodeEncodeError:
      return " ".join(map(unicode, cache_key))
  elif not isinstance(cache_key, basestring):
    try:
      return str(cache_key)
    except UnicodeEncodeError:
      return unicode(cache_key)
  return cache_key



def get_cache(region, namespace):
  if region not in cache_regions:
    warnonce('Cache region not configured: %s' % region)
    return None
  reg = cache_regions[region]
  if not reg.get('enabled', True):
    return None
  return Cache._get_cache(namespace, reg)



class ResultCacher(object):
  __slots__ = ( '_cache', '_arg_region', '_arg_namespace', '_arg_key_generator', '_arg_func' )

  def __get__(self, obj, ownerClass = None):
    import types
    return types.MethodType(self, obj)

  @property
  def cache(self):
    if self._cache is not None:
      return self._cache
    self._cache = get_cache(self._arg_region, self._arg_namespace)
    return self._cache

  def forget(self, key):
    c = self.cache
    if c is not None:
      c.remove_value(key = stringify_key(key))

  def __init__(self, region, namespace, key_generator, func):
    self._cache = None
    self._arg_region = region
    self._arg_namespace = namespace
    self._arg_key_generator = key_generator
    self._arg_func = func

  def __call__(self, *args):
    c = self.cache
    if c is None:
      return self._arg_func(*args)
    key = stringify_key(self._arg_key_generator(args))

    def creator():
      return self._arg_func(*args)

    return c.get_value(key, createfunc=creator)


def key_cache_region(region, namespace, key_generator):
  """
  Return a caching function decorator that generates keys based using
  a key generator function.
  """
  def decorate(func):
    return ResultCacher(region, namespace, key_generator, func)

  return decorate



__all__ = [
  'key_cache_region'
]
