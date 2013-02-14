import sys
import os
import re
import uuid
import collections
import mistic.data.dataset
import json
import logging

from beaker.cache import *
from cache_helpers import *

__obo_unescape = {
  't': '\t',
  'n': '\n',
  'W': ' '
}

def obo_unescape(x):
  return re.sub(r'\\(.)', lambda m: __obo_unescape.get(m.group(1), m.group(1)), x)

def obo_def(x):
  return x

def parse_obo(file):
  rectype = 'Header'
  kv = []

  comment_re = re.compile(r'(?<!\\)!.*')
  cont_re = re.compile(r'(?<!\\)\\$')
  tag_re = re.compile(r'^(.*?)(?<!\\):\s*(.*)')

  while True:
    line = file.readline()
    if line == '':
      break
    line = comment_re.sub('', line.rstrip('\n'))

    if line.startswith('['):
      if rectype is not None:
        yield rectype, kv
      rectype = line[1:-1]
      kv = []
      continue

    while cont_re.search(line) is not None:
      line = file.readline()
      if line == '':
        logging.warn('incomplete last line')
        break
      cont = comment_re.sub('', line.rstrip('\n'))
      line = line[:-1] + cont

    if not len(line):
      continue

    m = tag_re.match(line)
    if m is None:
      logging.warn('unknown OBO line: [%r]' % (line,))
      continue

    tag, val = m.groups()
    tag = obo_unescape(tag)

    kv.append((tag, val))

  if rectype is not None:
    yield rectype, kv

        

class OntologyNode(object):
  def __init__(self, kv):
    self.parents = set()
    self.alt_ids = set()
    self.subsets = set()
    for tag, val in kv:
      if tag == 'id':
        self.id = intern(val.strip())
      elif tag == 'alt_id':
        self.alt_ids.add(intern(val.strip()))
      elif tag == 'namespace':
        self.namespace = intern(val)
      elif tag == 'name':
        self.desc = obo_unescape(val)
      elif tag == 'def':
        self.definition = obo_def(val)
      elif tag == 'is_a':
        self.parents.add(intern(val.strip()))
      elif tag == 'subset':
        self.subsets.add(intern(val.strip()))
      # else:
      #   logging.warn('skipped: %r' % ((tag, val),))

    self.parents = tuple(sorted(self.parents))
    self.alt_ids = tuple(sorted(self.alt_ids))
    self.subsets = tuple(sorted(self.subsets))


class Ontology(object):
  def __init__(self):
    self.nodes = {}

  def load(self, path):
    self.path = path
    obo = os.path.join(path, 'gene_ontology_ext.obo')
    for rectype, kv in parse_obo(open(obo, 'rbU')):
      if rectype == 'Term':
        n = OntologyNode(kv)
        self.nodes[n.id] = n

    for v in self.nodes.values():
      for alt_id in v.alt_ids:
        assert alt_id not in self.nodes
        self.nodes[alt_id] = v

  def parents(self, terms):
    o = set(terms)
    visited = set()
    while len(o):
      n = o.pop()
      if n in visited:
        continue

      visited.add(n)

      node = self.nodes.get(n)
      if node is None:
        logging.warn('no node for GO ID %s' % (n,))
        continue

      o.update(set(node.parents) - visited)

    return visited - set(terms)

ontology = Ontology()



class Orthology(object):
  def __init__(self):
    self.annot_id_to_og = {}
    self.og_to_annot_ids = collections.defaultdict(lambda: collections.defaultdict(set))

  def load(self, path):
    self.path = path
    for row in open(self.path):
      row = row.split()
      og = row[0]
      items = [ tuple(x.split(':', 1)) for x in row[1:] ]
      for i in items:
        self.og_to_annot_ids[og][i[0]].add(i[1])
        self.annot_id_to_og[i] = og

    self.og_to_annot_ids = dict([
        (k1, dict([ (k2, frozenset(v2)) for k2, v2 in v1.iteritems() ]))
        for k1, v1 in self.og_to_annot_ids.iteritems()
    ])

  def map_ids(self, ids, src_annot, tgt_annot):
    if src_annot == tgt_annot:
      return [ frozenset((i,)) for i in ids ]
    result = []
    for i in ids:
      og = self.annot_id_to_og.get((src_annot, i))
      result.append(self.og_to_annot_ids.get(og, {}).get(tgt_annot, frozenset()))
    return result

orthology = Orthology()



class Collection(object):
  def __init__(self):
    self.objects = []
    self.id_to_index = {}

  def add(self, obj):
    self.id_to_index[obj.id] = len(self.objects)
    self.objects.append(obj)

  def get(self, id):
    if id not in self.id_to_index: return None
    return self.objects[self.id_to_index[id]]

  def all(self):
    return tuple(self.objects)

annotations = Collection()
datasets = Collection()

class Annotation(object):
  def __init__(self, **kw):
    self.id = kw.get('id', uuid.uuid4())
    self.name = kw.get('name', self.id)
    self.description = kw.get('desc', '')
    self.path = kw['path']
    self.desc = {}
    self.symbol = {}
    self.attrs = {}
    
    self.go = collections.defaultdict(set)
    self.go_genes = collections.defaultdict(set)
   
    self.go_indirect = collections.defaultdict(set)
    self.go_genes_indirect = collections.defaultdict(set)
    
    self.others = collections.defaultdict(list)
    self.others_genes = collections.defaultdict(list)
        
    desc = {}
    for row in open(self.path):
      
      ident, row = row.split(None, 1)
      try:
          attrs = json.loads(row)
          
      except: 
          print 'NOT ABLE TO LOAD '
          print ident, row
          
          continue
      
      self.attrs[ident] = attrs
      self.desc[ident] = attrs.get('name', '')
      self.symbol[ident] = attrs.get('symbol', '')
      self.go[ident] = set([ x[0] for x in attrs.get('go', []) ])
      self.go_indirect[ident] = ontology.parents(self.go[ident])
      
      for ka in  attrs.keys():
        if ka=="go": continue 
        if not self.others.has_key(ka): 
          self.others[ka] = collections.defaultdict(set)
       
        try: 
          self.others[ka][ident].add(attrs.get(ka))
        except :
          self.others[ka][ident] = set(attrs.get(ka)) 
        
        for g in self.others[ka][ident]:
          if not self.others_genes.has_key(ka): 
            self.others_genes[ka] = collections.defaultdict(set)
          self.others_genes[ka][g].add(ident)
            
      for g in self.go[ident]:
        self.go_genes[g].add(ident)
      for g in self.go_indirect[ident]:
        self.go_genes_indirect[g].add(ident)
      
    self.genes = set(self.attrs.keys())

  def gene_set(self, go = []):
    if go == []:
      return self.genes
    else:
      go = set(go)
      return [ gene for gene in self.genes if go <= self.go.get(gene, set()) ]

  @property
  def info(self):
    return dict(id = self.id, name = self.name, desc = self.description)



class DataSet(object):
  def __init__(self, **kw):
    self.id = kw.get('id', uuid.uuid4())
    self.name = kw.get('name', self.id)
    self.description = kw.get('desc', '')
    self.source = kw['file']
    self.data = mistic.data.dataset.DataSet.readTSV(kw['file'])
    self.type = kw.get('type', '')
    self.experiment = kw.get('expt', '')
    self.annotation = annotations.get(kw['anot'])
    self.transforms = set(('none', 'log', 'rank', 'anscombe')) & set(kw.get('xfrm', 'none').split(','))
    self.tags = kw.get('tags', '')
   
   
  @property
  def info(self):
    return dict(
      id = self.id,
      name = self.name,
      desc = self.description,
      annotation = self.annotation.id)

  @property
  def genes(self):
    return self.data.rownames

  @property
  def symbols(self):
    return [self.annotation.symbol.get(r) for r in self.data.rownames]

  @property
  def samples(self):
    return self.data.colnames
  
  @property
  def numberSamples(self):
    return len(self.data.colnames)
        
  def _makeTransform(self, xform):
    return dict(
      log =      mistic.data.dataset.LogTransform,
      anscombe = mistic.data.dataset.AnscombeTransform,
      rank =     mistic.data.dataset.RankTransform
      ).get(xform, lambda: None)()

  @key_cache_region('mistic', 'genecorr', lambda args: (args[0].id,) + args[1:])
  def _genecorr(self, gene, xform, absthresh, thresh):
    result = self.data.rowcorr(self.data.r(gene), transform = self._makeTransform(xform))
    
    if absthresh is not None:
      absthresh = float(absthresh)
      result = [ r for r in result if abs(r[2]) >= absthresh ]

    if thresh is not None:
      thresh = float(thresh)
      result = [ r for r in result if r[2] >= thresh ]

    return dict(
      gene = gene,
      symbol = self.annotation.symbol.get(gene, ''),
      desc = self.annotation.desc.get(gene, ''),
      dataset = self.id,
      row = self.data.r(gene),
      xform = xform,
      data = tuple([
          dict(
            idx=a,
            gene=b,
            symbol = self.annotation.symbol.get(b, ''),
            desc = self.annotation.desc.get(b, ''),
            corr=c,
            ) for a,b,c in result ]))

  def genecorr(self, gene, xform = None, absthresh = None, thresh = None):
    return self._genecorr(gene, xform, absthresh, thresh)

  def readPositionData(self, pos):
    node_re = re.compile(r'^\s*(\S*) \[(.*)\];$')
    attr_re = re.compile(r'(\S+=(?:[^"\s]+|"[^"]*"))\s*,\s*')

    if isinstance(pos, basestring):
      try:
        pos = open(pos)
      except IOError:
        return None
    pos_data = {}

    for l in pos:
      m = node_re.match(l)

      if m is not None:
        node, args = m.groups()
        if node in ('node', 'edge', 'graph'):
          continue

        node = int(node) - 1

        for x in attr_re.split(args):
          if len(x):
            k, v = x.split('=', 1)
            if k == 'pos':
              pos_data[node] = map(float, v[1:-1].split(','))

    n_components = min([ len(v) for v in pos_data.itervalues() ])
    ranges = [ (min([ v[c] for v in pos_data.itervalues()]),
                max([ v[c] for v in pos_data.itervalues()])) for c in range(n_components) ]
    extents = [ x[1] - x[0] for x in ranges ]
    centres = [ (x[1] + x[0]) / 2.0 for x in ranges ]
    scale = max(extents)

    def transform(pos):
      if pos is None:
        return tuple([ 0.0 ] * n_components)
      return tuple([ (pos[c] - centres[c]) / scale + 0.5 for c in range(n_components) ])

    return [ transform(pos_data.get(n)) for n in range(max(pos_data.iterkeys())+1) ]

  @key_cache_region('mistic', 'mst', lambda args: (args[0].id,) + args[1:])
  def mst(self, xform):
    d, f = os.path.split(self.source)
    g = os.path.join(d, 'transformed', xform, os.path.splitext(f)[0] + '.g')
    pos = os.path.join(d, 'transformed', xform, os.path.splitext(f)[0] + '.output.dot')

    try:
      g = open(g)
    except IOError:
      return None

    h = g.readline()
    m = re.match(r'p\s+edge\s+([0-9]+)\s+([0-9]+)\s*$', h)
    if m is None:
      return None

    n_nodes, n_edges = map(int, m.groups())
    nodes = [ None ] * n_nodes

    lines = list(g)

    for l in lines:
      if l[0] == 'n':
        l = l.split()
        nodes[int(l[1])-1] = l[2].replace('id=', '')

    def E(l):
      l = l.split()
      e1 = int(l[1]) - 1
      e2 = int(l[2]) - 1
      w = float(l[3].replace('weight=', ''))
      return (e1, e2), w

    edges = [ E(l) for l in lines if l[0] == 'e' ]

    return nodes, edges, self.readPositionData(pos)

  def mst_subset(self, xform, geneset):
    mst = self.mst(xform)
    if mst is None:
      return None

    nodes, edges, pos = mst

    geneset = sorted(set(geneset) & set(nodes))

    dataset_idx = dict([ (j, i) for i, j in enumerate(geneset) ])

    new_nodes = geneset
    new_edges = [
      ((dataset_idx[nodes[a]], dataset_idx[nodes[b]]), w)
      for (a, b), w in edges
      if nodes[a] in dataset_idx and nodes[b] in dataset_idx
      ]
    new_pos = [ (0.0, 0.0) ] * len(new_nodes)
    for i, n in enumerate(nodes):
      if n in dataset_idx:
        new_pos[dataset_idx[n]] = pos[i]

    return new_nodes, new_edges, new_pos

  def expndata(self, gene, xform = None):
    expn = self.data.row(self.data.r(gene), transform = self._makeTransform(xform))

    return dict(
      gene = gene,
      symbol = self.annotation.symbol.get(gene, ''),
      desc = self.annotation.desc.get(gene, ''),
      dataset = self.id,
      row = self.data.r(gene),
      xform = xform,
      data = tuple([ dict(sample=a, expr=float(b)) for a, b in zip(self.samples, expn) ])
    )



def collectItems(settings, prefix):
  items = collections.defaultdict(dict)

  for k, v in settings.iteritems():
    if k.startswith(prefix):
      k = k.split('.')
      items[int(k[2])][k[3]] = v

  return [ v for k,v in sorted(items.items()) ]

def loadOntology(settings):
  ontology.load(settings['mistic.ontology'])

def loadOrthology(settings):
  orthology.load(settings['mistic.orthology'])

def loadAnnotations(settings):
    for d in collectItems(settings, 'mistic.annotation.'):
        annotations.add(Annotation(**d))

def loadData(settings):
    for d in collectItems(settings, 'mistic.dataset.'):
      print ('Loading %s' % d['name'])
      datasets.add(DataSet(**d))
     
      


def load(settings):
  
 
  logging.info('loading ontology')
  loadOntology(settings)
  logging.info('loading orthologs')
  loadOrthology(settings)
  logging.info('loading annotations')
  loadAnnotations(settings)
  logging.info('loading data')
  loadData(settings)
  logging.info('loading done')

  # get corr for BAD and SLC39A13
  #print [x for x in datasets.all()[0].genecorr('BAD', 'log', 0, 0)['data'] if x['symbol']=='SLC39A13']
  
