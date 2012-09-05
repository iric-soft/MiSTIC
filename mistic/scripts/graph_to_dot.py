from mistic.util import graph
import sys
import argparse

class NeighbourhoodLength(object):
  def edgeAttrs(self, g, e):
    s_adj = g.adjacentNodes(e.source)
    t_adj = g.adjacentNodes(e.target)
    Nu = len(s_adj | t_adj)
    Ni = len(s_adj & t_adj)
    if e.source in t_adj:
      Nu -= 2
    return {'len': (Nu - Ni) ** .5 + 3}

class UniformLength(object):
  def edgeAttrs(self, g, e):
    return {'len': 1}

cmd = 'graph-to-dot'

def init_parser(p):
  p.add_argument('-e', '--edge-length', choices=('neighbourhood', 'uniform'), default='neighbourhood')
  p.add_argument('input',  type=argparse.FileType('rbU'), help='input file in dimacs format')
  p.add_argument('output', type=argparse.FileType('wb'),  help='output file in graphviz .dot format')

def run(args):
  g = graph.read(args.input)

  for n in g.nodes:
    n.id, n.attrs['label'] = n._node_num, n.id

  graph.writeDOT(args.output, g, graph.LargeGraph(),
                 dict(neighbourhood = NeighbourhoodLength(),
                      uniform       = UniformLength())[args.edge_length])

__all__ = [ 'cmd', 'init_parser', 'run' ]
