import re
import logging
import random
import json



class Node(object):
  def __init__(self):
    self.attrs = {}



class Edge(object):
  def __init__(self, source, target):
    self.source = source
    self.target = target
    self.attrs = {}



class Graph(object):
  def __init__(self):
    self.nodes = set()
    self.edges = {}

  def removeEdges(self, edgeset):
    for e in edgeset:
      self.edges[e.source].pop(e.target)
      self.edges[e.target].pop(e.source)

    disconnected = [ k for k, v in self.edges.iteritems() if not len(v) ]
    for d in disconnected:
      self.edges.pop(d)

  def getEdges(self):
    for n1, adj in self.edges.iteritems():
      for n2, e in adj.iteritems():
        yield e

  def findNodes(self, f):
    return set([ n for n in self.nodes if f(n) ])

  def findNode(self, f):
    for n in self.nodes:
      if f(n): return n
    return None

  def pathLength(self, n1, n2):
    if n1 is n2:
      return 0

    out = set([n1])
    N = set([n1])

    p = 1
    while len(N):
      x = set()
      for n in N:
        x.update(self.adjacentNodes(n) - out)
      if n2 in x:
        return p
      N = x
      p = p + 1
      out.update(N)

    return -1

  def nodeSetNeighbourhood(self, N, radius):
    out = set()
    out.update(N)

    for i in xrange(radius):
      x = set()
      for n in N:
        x.update(self.adjacentNodes(n) - out)
      N = x
      out.update(N)

    return frozenset(out)

  def nodeNeighbourhood(self, n, radius):
    return nodeSetNeighbourhood(set([n]), radius)

  def sampleNodes(self, k):
    return frozenset(random.sample(self.nodes, k))

  def sampleConnectedNodes(self, k):
    n_start = random.choice(list(self.nodes))
    S = set([n_start])
    N = set(self.adjacentNodes(n_start))
    while len(S) < k:
      n = random.choice(list(N))
      N.remove(n)
      S.add(n)
      N.update(self.adjacentNodes(n) - S)
    return frozenset(S)

  def removeNode(self, n):
    try:
      self.nodes.remove(n)
    except KeyError:
      return

    tgts = self.edges.pop(n)

    for tgt in tgts.iterkeys():
      del self.edges[tgt][n]

  def subgraph(self, N):
    if type(N) not in (set, frozenset):
      N = frozenset(N)

    g = Graph()
    g.nodes = self.nodes & N

    e = {}

    for src in N:
      e[src] = {}
      for tgt, edge in self.edges.get(src, {}).iteritems():
        if tgt in N:
          e[src][tgt] = edge
    g.edges = e
    return g

  def connectedSubgraphs(self):
    N = set(self.nodes)

    while len(N):
      s = next(iter(N))
      c = set([s])
      o = set(self.adjacentNodes(s))

      while len(o):
        s = o.pop()
        c.add(s)
        o.update(self.adjacentNodes(s) - c)

      yield self.subgraph(c)

      N.difference_update(c)

  def subgraphIsFullyConnected(self, N):
    if type(N) not in (set, frozenset):
      N = frozenset(N)

    s = next(iter(N))
    c = set([s])
    o = set(self.adjacentNodes(s) & N)

    while len(o):
      s = o.pop()
      c.add(s)
      o.update((self.adjacentNodes(s) & N) - c)

    return len(c) == len(N)

  def isFullyConnected(self):
    s = next(iter(self.nodes))
    c = set([s])
    o = set(self.adjacentNodes(s))

    while len(o):
      s = o.pop()
      c.add(s)
      o.update(self.adjacentNodes(s) - c)

    return len(c) == len(self.nodes)

  def isFullyConnectedAfterRemoving(self, n):
    if n not in self.nodes or len(self.nodes) == 1:
      return True

    s = next(iter(self.adjacentNodes(n)))
    c = set([n])
    o = set([s])

    while len(o):
      s = o.pop()
      c.add(s)
      o.update(self.adjacentNodes(s) - c)

    return len(c) == len(self.nodes)

  def adjacentNodes(self, n):
    return frozenset(self.edges.get(n, {}).keys())

  def addNode(self, node):
    self.nodes.add(node)

  def getEdge(self, s, t):
    return self.edges.get(s, {}).get(t, None)

  def addEdge(self, edge):
    self.nodes.add(edge.source)
    self.nodes.add(edge.target)

    self.edges.setdefault(edge.source, {})[edge.target] = edge
    self.edges.setdefault(edge.target, {})[edge.source] = edge



attr_re = re.compile(r'''(\w+)=(([^"'][^\s,]*)|((?P<quote>['"]).*?(?<!\\)(?P=quote)))''')
def parseAttrs(s):
  if s[0] == '{':
    return json.loads(s)

  attrs = []
  for m in attr_re.finditer(s):
    k,v = m.groups()[:2]
    if v[0] in ('"', "'"):
      v = v[1:-1]
      v = v.replace('\\"', '"')
      v = v.replace("\\'", "'")
    attrs.append((k,v))
  return attrs



class DOTattributes(object):
  def __init__(self):
    self.name = 'G'
    self.graph = {}
    self.node = {}
    self.edge = {}

  def graphDefaults(self, g):
    return self.graph

  def nodeDefaults(self, g):
    return self.node

  def edgeDefaults(self, g):
    return self.edge

  def nodeAttrs(self, graph, node):
    return {}

  def edgeAttrs(self, graph, edge):
    return {}



class LargeGraph(DOTattributes):
  def __init__(self):
    super(LargeGraph, self).__init__()
    self.graph['outputorder'] = 'edgesfirst'
    self.node['label'] = ''
    self.node['shape'] = 'circle'
    self.node['width'] = .1
    self.node['height'] = .1
    self.node['fixedsize'] = True
    self.edge['color'] = "#eeeeee"



def fmtDOTAttrs(attr_objects, meth_name, args):
  def formatter(t):
    if t is type(True):
      return lambda x: x and 'true' or 'false'
    if t in (str, unicode):
      # hack to force double quoted strings.
      return lambda x: repr(x + "'")[:-2] + '"'

  d = {}

  kv_lists = []
  for a in attr_objects:
    try:
      m = getattr(a, meth_name)
    except AttributeError:
      continue
    d.update(m(*args))

  out = []
  for k,v in d.iteritems():
    try:
      v = formatter(type(v))(v)
    except:
      try:
        v = formatter(str)(str(v))
      except:
        logging.warn('could not format %s for DOT output' % (repr(v),))
        continue

    out.append('%s=%s' % (str(k), v))

  if not len(out): return None

  return '[' + ','.join(out) + ']'



def writeDOT(outf, g, attr = DOTattributes(), *attrs):
  def dotname(s):
    s = str(s)
    if '-' in s:
      s = '"' + s + '"'
    return s

  attrs = [attr] + list(attrs)

  print >>outf, 'graph %s {' % (attr.name,)

  ga = fmtDOTAttrs(attrs, 'graphDefaults', (g,))
  na = fmtDOTAttrs(attrs, 'nodeDefaults', (g,))
  ea = fmtDOTAttrs(attrs, 'edgeDefaults', (g,))

  if ga: print >>outf, '\tgraph %s;' % (ga,)
  if na: print >>outf, '\tnode %s;' % (na,)
  if ea: print >>outf, '\tedge %s;' % (ea,)

  for n in g.nodes:
    na = fmtDOTAttrs(attrs, 'nodeAttrs', (g, n))
    if na is None: na = ''
    print >>outf, '\t\t%s%s;' % (dotname(n.id), na)

  for src, tgts in g.edges.iteritems():
    for tgt, e in tgts.iteritems():
      if src < tgt:
        ea = fmtDOTAttrs(attrs, 'edgeAttrs', (g, e))
        if ea is None: ea = ''
        print >>outf, '\t\t%s -- %s%s;' % (dotname(src.id), dotname(tgt.id), ea)
  print >>outf, '}'



def fmtJSONAttrs(attrs):
  return json.dumps(attrs)

def fmtAttrs(attrs):
  def formatter(t):
    if t is type(True):
      return lambda x: x and 'true' or 'false'
    if t in (str, unicode):
      # hack to force double quoted strings.
      return lambda x: repr(x + "'")[:-2] + '"'

  out = []
  for k,v in attrs.iteritems():
    try:
      v = formatter(type(v))(v)
    except:
      try:
        v = formatter(str)(str(v))
      except:
        logging.warn('could not format %s for graph output' % (repr(v),))
        continue

    out.append('%s=%s' % (str(k), v))

  return ','.join(out)



def write(outf, g):
  if type(outf) in (str, unicode):
    outf = open(outf, 'w')

  edgeset = set(g.getEdges())
  print >>outf, 'p', 'edge', len(g.nodes), len(edgeset)
  nodes = list(g.nodes)
  node_nums = [ (node, i+1) for i, node in enumerate(nodes) ]

  for n, i in node_nums:
    print >>outf, 'n', i, fmtAttrs(n.attrs)

  node_nums = dict(node_nums)

  for e in edgeset:
    print >>outf, 'e', node_nums[e.source], node_nums[e.target], fmtAttrs(e.attrs)

def writeJSONAttrs(outf, g):
  if type(outf) in (str, unicode):
    outf = open(outf, 'w')

  edgeset = set(g.getEdges())
  print >>outf, 'p', 'edge', len(g.nodes), len(edgeset)
  nodes = list(g.nodes)
  nodes.sort(key = lambda n: getattr(n, '_order', 0))
  node_nums = [ (node, i+1) for i, node in enumerate(nodes) ]

  for n, i in node_nums:
    print >>outf, 'n', i, fmtJSONAttrs(n.attrs)

  node_nums = dict(node_nums)

  for e in edgeset:
    print >>outf, 'e', node_nums[e.source], node_nums[e.target], fmtJSONAttrs(e.attrs)

def read(inf):
  if type(inf) in (str, unicode):
    inf = open(inf, 'r')

  nodes = []
  edges = []
  for i in inf:
    if i[0] == 'p':
      p, edge, Nn, Ne = i.split(None, 3)
      Nn, Ne = int(Nn), int(Ne)
      if edge != 'edge':
        logging.warn("Expected dimacs graph in 'edge' format.")
    elif i[0] == 'c':
      pass
    elif i[0] == 'n':
      i = i.split(None, 2)
      if len(i) == 3:
        n_num, rest = i[1], i[2]
      else:
        n_num, rest = i[1], ''
      n_num = int(n_num)
      attr = parseAttrs(rest)
      nodes.append((n_num, attr))
    elif i[0] == 'e':
      i = i.split(None, 3)
      if len(i) == 4:
        n_src, n_tgt, rest = i[1], i[2], i[3]
      else:
        n_src, n_tgt, rest = i[1], i[2], ''
      n_src, n_tgt = int(n_src), int(n_tgt)
      attr = parseAttrs(rest)
      edges.append(((n_src, n_tgt), attr))
    else:
      logging.warn('Unrecognised line: [%s]' % (i.strip(),))

  if Nn != len(nodes):
    logging.warn('Expected %d nodes, read %d' % (Nn, len(nodes)))

  if Ne != len(edges):
    logging.warn('Expected %d edges, read %d' % (Ne, len(edges)))

  def makeNode(attr, n_num):
    n = Node()
    a = dict(attr)
    if 'id' in a:
      n.id = a['id']
    n.attrs = a
    n._node_num = n_num
    return n

  g = Graph()

  nodes = dict([ (n_num, makeNode(attr, n_num)) for n_num, attr in nodes ])

  for n in nodes.itervalues():
    g.addNode(n)

  def makeEdge(n1, n2, attr):
    e = Edge(n1, n2)
    a = dict(attr)
    if 'weight' in a:
      n.weight = float(a['weight'])
    e.attrs = a
    return e

  edges = [ makeEdge(nodes[n_src], nodes[n_tgt], attr) for (n_src, n_tgt), attr in edges ]

  for e in edges:
    g.addEdge(e)

  return g



def prim_mst(graph, edge_weight):
  span = []
  nodes = set(graph.nodes)

  s = set([nodes.pop()])

  while len(nodes):
    e = (1e300,None,None)
    for n in s:
      for n2, edge in graph.edges[n].iteritems():
        if n2 not in s:
          assert n2 in nodes
          w = edge_weight(edge)
          e = min(e, (w, n2, edge))
    s.add(e[1])
    nodes.remove(e[1])
    span.append(e[2])

  g = Graph()
  for edge in span:
    g.addEdge(edge)

  assert g.nodes == graph.nodes

  return g



if __name__ == '__main__':
  import sys
  import cStringIO
  c = cStringIO.StringIO('''\
p edge 5 7
n 1 id=10
n 2 id=11
n 3 id=12
n 4 id=13
n 5 id=14
e 1 3 weight=2
e 3 2 weight=2 note="this is special"
e 2 1 weight=2
e 4 1 weight=2
e 5 4 weight=2
e 4 3 weight=2
e 2 4 weight=2
''')
  graph = read(c)

  assert graph.isFullyConnected()

  node_3 = graph.findNode(lambda n: n.id == '12')
  node_4 = graph.findNode(lambda n: n.id == '13')
  node_5 = graph.findNode(lambda n: n.id == '14')

  assert graph.isFullyConnectedAfterRemoving(node_5)
  assert not graph.isFullyConnectedAfterRemoving(node_4)

  graph.addEdge(Edge(node_3, node_5))

  assert graph.isFullyConnectedAfterRemoving(node_4)

  graph.removeNode(node_4)

  assert graph.isFullyConnected()

  writeDOT(sys.stdout, graph, LargeGraph())



class dfs_visitor(object):
  def __init__(self):
    object.__init__(self)

  def discover_node(self, graph, node):
    pass

  def examine_edge(self, graph, node, child, edge):
    pass

  def tree_edge(self, graph, node, child, edge):
    pass

  def back_edge(self, graph, node, child, edge):
    pass

  def forward_or_cross_edge(self, graph, node, child, edge):
    pass

  def finish_node(self, graph, node):
    pass



def dfs(graph, node, vis):
  stack = []
  colour = {}

  colour[node] = 1
  vis.discover_node(graph, node)
  edges = graph.edges[node]
  stack.append((node, list(edges.items())))

  while len(stack):
    node, edge_list = stack.pop()
    i = 0
    while i < len(edge_list):
      child, edge = edge_list[i]
      i += 1
      vis.examine_edge(graph, node, child, edge)
      c_colour = colour.get(child, 0)
      if c_colour == 0:
        vis.tree_edge(graph, node, child, edge)
        stack.append((node, edge_list[i:]))
        node = child
        colour[node] = 1
        vis.discover_node(graph, node)
        edges = graph.edges[node]
        edge_list = list(edges.items())
        i = 0
      elif c_colour == 1:
        vis.back_edge(graph, node, child, edge)
      else:
        vis.forward_or_cross_edge(graph, node, child, edge)
    colour[node] = 2
    vis.finish_node(graph, node)


