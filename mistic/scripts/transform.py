from mistic.data.dataset import *
import sys
import os
import argparse
import exceptions
import logging

cmd = 'transform'

class File(argparse.FileType):
  def __init__(self, mode='w', bufsize=-1):
    super(File, self).__init__(mode, bufsize)

  def __call__(self, string):
    if string != '-' and ('w' in self._mode or 'a' in self._mode):
      filedir = os.path.dirname(string)
      if not os.path.exists(filedir):
        try:
          os.makedirs(filedir)
        except OSError:
          if not os.path.exists(filedir):
            raise exceptions.RuntimeError('Could not create directory for output file [%s]' % (string,))
    return super(File, self).__call__(string)

def filt(row, name):
  return numpy.median(row) > 0.0

class DupFilterer(object):
  def __init__(self):
    self.seen = set()
    self.n_dups = 0

  def __call__(self, row, name):
    if name in self.seen:
      self.n_dups += 1
      return False
    self.seen.add(name)
    return True

def init_parser(parser):
  parser.add_argument('transform', choices = ('log', 'rank', 'anscombe', 'none'), help='dataset transformation')
  parser.add_argument('input', type = File('rbU'), help='input dataset')
  parser.add_argument('output', type = File('wb'), help='output dataset')

def run(args):
  dataset = DataSet.readTSV(args.input)
  
  if args.transform == 'rank':
    dataset.data = RankTransform()(dataset.data)
  elif args.transform == 'anscombe':
    dataset.data = AnscombeTransform()(dataset.data)
    dataset.filter(filt)
  elif args.transform == 'log':
    dataset.data = LogTransform()(dataset.data)
    dataset.filter(filt)
  elif args.transform == 'none':
    dataset.filter(filt)

  dup = DupFilterer()
  dataset.filter(dup)

  if dup.n_dups:
    logging.warn('Dataset had %d duplicate IDs. Duplicates have been discarded.' % (dup.n_dups,))

  dataset.writeTSV(args.output)

__all__ = [ 'cmd', 'init_parser', 'run' ]
