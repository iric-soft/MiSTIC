import sys
import os
import argparse
import exceptions
import logging

from mistic.app import data
from mistic.scripts.helpers import *
from mistic.util.djset import *

cmd = 'sets'

def init_parser(parser):
  parser.add_argument('-t',
                      '--transform',
                      choices = ('log', 'rank', 'anscombe', 'none'),
                      default = None,
                      help='dataset transformation (default: first listed)')

  parser.add_argument('-c',
                      '--csize',
                      default = None,
                      type = int,
                      help='cluster formation size (default: from config)')

  parser.add_argument('-n',
                      '--app-name',
                      default='main',
                      type=str,
                      help='Load the named application (default: main)')

  parser.add_argument('config',
                      type=argparse.FileType('r'), help='config file')

  parser.add_argument('dataset',
                      help='dataset to produce sets for')

def run(args):
  defaults = dict(
    here = os.path.dirname(os.path.abspath(args.config.name)),
    __file__ = os.path.abspath(args.config.name)
  )

  init_logging(args.config, defaults)
  init_beaker_cache()

  settings = read_config(args.config, 'app:' + args.app_name, defaults)

  if 'mistic.data' not in settings:
    raise exceptions.RuntimeError('no dataset configuration supplied')

  APP_DATA = data.GlobalConfig(settings['mistic.data'])

  APP_DATA.load_metadata()
  APP_DATA.load(args.dataset)

  ds = data.datasets.get(args.dataset)
  if ds is None:
    raise RuntimeError('Could not find config entry for dataset [%s]' % (args.dataset,))

  if args.transform is not None:
    nodes, edges, positions = ds.mst(args.transform)
  else:
    nodes, edges, positions = ds.mst(ds.transforms[0])

  if args.csize is None:
    if 'icicle' in ds.config and 'cluster_minsize' in ds.config['icicle']:
      args.csize = ds.config['icicle']['cluster_minsize']
    else:
      args.csize = 5

  djset = DisjointSet(len(nodes))

  last_weight = {}

  clusters = []
  cluster_heads = set()

  for (a, b), w in edges:
    a_sz = djset.set_size(a)
    b_sz = djset.set_size(b)

    a_hd = djset.find_set_head(a)
    b_hd = djset.find_set_head(b)


    if a_sz >= args.csize and b_sz >= args.csize:
      a_set = [ ]
      b_set = [ ]

      for x in range(len(nodes)):
        x_hd = djset.find_set_head(x)
        if x_hd == a_hd:
          a_set.append(x)
        elif x_hd == b_hd:
          b_set.append(x)

      a_set = set(a_set)
      b_set = set(b_set)

      a_parents = [ i for i,j in enumerate(clusters) if j[3] < a_set and i in cluster_heads ]
      b_parents = [ i for i,j in enumerate(clusters) if j[3] < b_set and i in cluster_heads ]

      cluster_heads -= set(a_parents + b_parents)

      cluster_heads.add(len(clusters))
      clusters.append((1 - last_weight[a_hd], w - last_weight[a_hd], a_parents, a_set))
      cluster_heads.add(len(clusters))
      clusters.append((1 - last_weight[b_hd], w - last_weight[b_hd], b_parents, b_set))


    hd = djset.merge_sets(a, b)
    last_weight[hd] = w

  print 'cluster_id\tcluster_min_corr\tw_delta\tchild_clusters\tcluster_geneids\tcluster_symbols'
  for i, j in enumerate(clusters):
    print '{0:d}\t{1:.5f}\t{2:.5f}\t{3:s}\t{4:s}\t{5:s}'.format(
      i,
      j[0],
      j[1],
      ','.join(map(str, j[2])),
      ','.join([ nodes[x] for x in j[3] ]),
      ','.join([ ds.annotation.symbol.get(nodes[x], nodes[x]) for x in j[3] ])
    )
