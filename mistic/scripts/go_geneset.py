import sys
import os
import argparse
import exceptions
import logging
import json

from mistic.app import data
from mistic.scripts.helpers import *
from mistic.util.djset import *

cmd = 'go-geneset'

def init_parser(parser):
  parser.add_argument('-n',
                      '--app-name',
                      default='main',
                      type=str,
                      help='Load the named application (default: main)')

  parser.add_argument('config',
                      type=argparse.FileType('r'), help='config file')

  parser.add_argument('annotation',
                      help='annotation to produce GO genesets for')

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

  annotation = data.annotations.get(args.annotation);
  if annotation is None:
    raise RuntimeError('Could not find config entry for annotation [%s]' % (args.annotation,))

  for go, ids in annotation.go_genes.iteritems():
    ids = sorted(ids)
    print go, json.dumps(
      dict(
        ids = ids,
        evidence = [ [ x[1] for x in annotation.attrs[i]['go'] if x[0] == go ][0] for i in ids ]
      ))
