# -*- coding: utf-8 -*-
from pyramid.httpexceptions import HTTPFound, HTTPNotFound, HTTPBadRequest
from pyramid.view import view_config
from pyramid.response import Response
from pyramid.renderers import render_to_response

from mistic.app import data
from mistic.util import gorilla
from mistic.data.dataset import *

import numpy
import math
import scipy.stats
import re
import json
import collections
import pickle
import os
import logging

from beaker.cache import *
from mistic.app.cache_helpers import *
from mistic.app.tables import *



def urank(ranks, N):
    # takes 0-based ranks.
    N1 = len(ranks)
    N2 = N - N1
    U = sum(ranks) + N1 - N1 * (N1+1) / 2.0
    z = (U - (N1*N2) / 2.0) / math.sqrt(N1*N2*(N1+N2+1) / 12.0)
    return U, scipy.stats.norm.sf(z)

CACHED = (10, {'public':True})

@view_config(route_name="mistic.json.datasets", request_method="GET", renderer="json")
def datasets(context, request):
    return [ d.info for d in data.datasets.all() ]


class GO(object):
    def __init__(self, request):
        self.request = request

    @view_config(route_name="mistic.json.go", request_method="GET", renderer="json")
    def index(self):
        ids = self.request.GET.getall('id')
        if not len(ids):
            return [ node.__dict__ for node in data.ontology.nodes.itervalues() ]
        else:
            return [ node.__dict__ for node in [ data.ontology.nodes.get(i) for i in ids ] if node is not None ]

    @view_config(route_name="mistic.json.go.search", request_method="GET", renderer="json")
    def search(self):
        query = self.request.GET.getall('q')
        query = sum([ q.split() for q in query ], [])
        query = [ re.compile(re.sub(r'([-[\]{}()*+?.,\\^$|#])', r'\\\1', q), re.I) for q in query if q != '' ]

        if query == []:
            return []

        limit = self.request.GET.get('l')
        try:
            limit = int(limit)
        except:
            limit = 100
        limit = min(limit, 100)

        out = []

        for node_id, node in data.ontology.nodes.iteritems():
            r = dict(
                id = node.id,
                ns = node.namespace,
                name = node.name)

            if (any([ q.match(r['id'])     is not None for q in query ]) or
                all([ q.search(r['name'])  is not None for q in query ])):
                out.append(r)
        out.sort(key = lambda r: r['id'])
        out = out[:limit]
        return out



class GOTerm(GO):
    def __init__(self, request):
        super(GOTerm, self).__init__(request)
        self.node = data.ontology.nodes.get(request.matchdict['go_id'])
        if self.node is None:
            raise HTTPNotFound()

    @view_config(route_name="mistic.json.go.id", request_method="GET", renderer="json")
    def index(self):
        return dict(
            id = self.node.id,
            ns = self.node.namespace,
            name = self.node.name)

    @view_config(route_name="mistic.json.go.name", request_method="GET", renderer="json")
    def name(self):
        return self.node.name

class ColAnnotation(object):
    def __init__(self, request):
        self.request = request
        #self.cannotation = data.annotations.get(request.matchdict['cannotation'])
        self.dataset = data.datasets.get(request.matchdict['dataset'])

    @view_config(route_name="mistic.json.cannotation.items", request_method="GET", renderer="json")
    def items(self):

      k = []
      v = []
      if not self.dataset.cannotation:
          return []
      anns = self.dataset.cannotation.data
      return { col: sorted(set(anns[col]) - set([""])) for col in anns.columns }


class Annotation(object):
    def __init__(self, request):
        self.request = request
        self.annotation = data.annotations.get(request.matchdict['annotation'])
        if self.annotation is None:
            raise HTTPNotFound()

        self._genesets_search = {3 : self._genesets, 2: self._genesets_cat, 1: self._genesets_type}

    def gene_record(self, gene, genesets = None):
        '''
        return a gene record as a dict.

        if genesets is not None, it should be a list of geneset
        identifiers in dot-separated form, with * being a wildcard.

        in this case, the genesets key is populated with the geneset
        identifiers associated with this gene, restricted to the
        specified geneset identifiers.

        if a geneset does not define a set of categories, then any
        named category will match.
        '''
        record = dict(
            id = gene,
            symbol = self.annotation.get_symbol(gene),
            name = self.annotation.get_name(gene)
        )

        if genesets is not None and len(genesets):
            gene_geneset_ids = self.annotation.get_geneset_ids(gene, genesets)
            record['genesets'] = sorted(gene_geneset_ids)

        return record

    @view_config(route_name="mistic.json.annotation.gene_ids", request_method="GET", renderer="json")
    def gene_ids(self):
        gs = self.request.GET.getall('filter_gsid')

        if not len(gs):
            return sorted(self.annotation.get_gene_ids())
        else:
            geneids_by_gs = [ self.annotation.get_gene_ids(x) for x in gs ]
            s = set(geneids_by_gs[0])
            for s2 in geneids_by_gs[1:]:
                s.intersection_update(s2)
            return sorted(s)

    @view_config(route_name="mistic.json.annotation.genes", request_method="GET", renderer="json")
    def genes(self):
        result = self.annotation.get_gene_ids(self.request.GET.getall('filter_gsid'))
        return [ self.gene_record(gene, set(self.request.GET.getall('gs'))) for gene in result ]


    def _query_to_regex (self, query):
      if query:
        query = [ re.sub(r'([-[\]{}()*+?.,\\^$|#])', r'\\\1', q) for q in query if q != '']
        query = [ re.compile(q, re.I) for q in query ]
      return query

    @key_cache_region('mistic', 'jsonviews', lambda args: args[1])
    def _genesets(self, query, limit):
        out = []

        query_type = [q.split(':')[1] for q in query if 'ty:' in q ]
        query_catg = [q.split(':')[1] for q in query if 'ct:' in q ]
        query = [q.split(':')[1] if ':' in q else q for q in query]

        query = self._query_to_regex(query)

        for gsid in sorted(self.annotation.get_geneset_ids()):
          if limit and len(out) > limit :
            break

          geneset_id, ident = gsid.rsplit(':', 1)
          geneset_id = geneset_id.split('.')
          geneset_id, geneset_cat = geneset_id[0], geneset_id[1:]
          geneset = self.annotation.genesets.get(geneset_id)

          row = geneset.genesets.ix[ident]
          name = row['name']

          if len(query_type)==0 or geneset_id in query_type:
            if (all([ q.search(gsid+' '+name) is not None for q in query ])):
              out.append(dict(name = name, id = gsid))


        return out


    def _genesets_cat (self, query, limit):

      out = []

      query_type = [q.split(':')[1] for q in query if 'ty:' in q ]
      query = [q.split(':')[1] if ':' in q else q for q in query]
      geneset_types = self.annotation.genesets.keys()
      geneset_type = [q for q in query_type if q in geneset_types]


      if len(geneset_type)>0 :
        geneset_type = geneset_type[0]
        query = tuple([q for q in query if q != geneset_type])   # Use the type only to restrict the list
        genesets_data = {geneset_type : self.annotation.genesets[geneset_type]}
      else :
        genesets_data = self.annotation.genesets

      query = self._query_to_regex(query)

      for k,v in genesets_data.items() :
        if limit and len(out) > limit :
          break

        ss = sorted(list(set(list(v.genesets['cat']))))

        for s in ss :
          if (all([q.search(k+' '+s) is not None for q in query ])) or not query:
            out.append(dict(id = k+'.'+s, name = ''))
      return out


    def _genesets_type (self, query, limit):

      out = []
      query = self._query_to_regex(query)
      genesets_data =  self.annotation.genesets
      for k,v in genesets_data.items() :
        if (all([ q.search(k) is not None for q in query ])) or not query:
          out.append(dict(id = k,name = v.description))

      return out


    @view_config(route_name="mistic.json.annotation.gs", request_method="GET", renderer="json")
    def genesets(self):
        level = int(self.request.GET.get('v', 3))
        query = self.request.GET.getall('q')
        query = tuple(sum([ q.split() for q in query ], []))
        limit = self.request.GET.get('l')

        try:
            limit = int(limit)
        except:
            limit = 100


        #out = self._genesets(query, limit)

        out = self._genesets_search[level](query, limit)

        #if limit is not None:
        #    out = out[:limit]
        return out





class AnnotationGene(Annotation):
    def __init__(self, request):
        super(AnnotationGene, self).__init__(request)
        self.gene_id = self.request.matchdict['gene_id']
        if self.gene_id not in self.annotation.genes:
            raise HTTPNotFound()

    @view_config(route_name="mistic.json.annotation.gene", request_method="GET", renderer="json")
    def gene(self):
        return self.gene_record(self.gene_id, set(self.request.GET.getall('gs')))

    @view_config(route_name="mistic.json.annotation.gene.name", request_method="GET", renderer="json")
    def name(self):
        return self.annotation.get_name(self.gene_id)

    @view_config(route_name="mistic.json.annotation.gene.symbol", request_method="GET", renderer="json")
    def symbol(self):
        return self.annotation.get_symbol(self.gene_id)

    @view_config(route_name="mistic.json.annotation.gene.gs", request_method="GET", renderer="json")
    def gs(self):
        gsid = self.request.matchdict['gsid']
        if not len(gsid):
            return sorted(self.annotation.get_geneset_ids(self.gene_id))
        else:
            return sorted(self.annotation.get_geneset_ids(self.gene_id, [ '.'.join(gsid) ]))



class Dataset(object):
    def __init__(self, request):
        self.request = request
        self.dataset = data.datasets.get(request.matchdict['dataset'])
        if self.dataset is None:
            raise HTTPNotFound()

    @view_config(route_name="mistic.json.dataset", request_method="GET", renderer="json")
    def index(self):
        return self.dataset.info

    @view_config(route_name="mistic.json.dataset.genes", request_method="GET", renderer="json")
    def genes(self):
        return self.dataset.genes

    @view_config(route_name="mistic.json.dataset.sampleinfo", request_method="GET", renderer="json")
    def sample_info(self):
        if not self.dataset.cannotation:
            return []
        anns = self.dataset.cannotation.data
        return [ (col, sorted(set(anns[col]) - set([""]))) for col in anns.columns ]


    @view_config(route_name="mistic.json.dataset.sampleinfo.search", request_method="GET", renderer="json")
    def sample_info_search(self):
      if not self.dataset.cannotation:
         return []
      out = []
      anns = self.dataset.cannotation.data
      d = dict([ (col, sorted(set(anns[col]) - set([""]))) for col in anns.columns ])
      query = self.request.GET.getall('q')

      if query ==['']:
        for k,v in d.items():
          for e in v:
              out.append(dict(id='%s.%s' %(k,e), key = k, values = e))
        return out


      query = sum([ q.split() for q in query ], [])
      query = [ re.compile(re.escape(q), re.I) for q in query if q != '' ]

      if query == []:
        return []

      for q in query:
        for k,v in d.items():
          keyFound = False
          if q.search(k):
              keyFound = True
          for e in v:
            if q.search(e) or keyFound:
              out.append(dict(id='%s.%s' %(k,e), key = k, values = e))

      return out


    @view_config(route_name="mistic.json.dataset.samples.enrich", request_method="POST", renderer="json")
    def sample_enrichment(self):
        if not self.dataset.cannotation:
            return []
        anns = self.dataset.cannotation.data

        samples = set(json.loads(self.request.POST['samples']))

        out = []

        for col in anns.columns:

            all_samples = set(anns.index[anns[col].map(lambda x: x not in ("", None))])
            all_samples = all_samples & set(self.dataset.samples)

            tst_samples = samples & all_samples

            col_vals = set(anns[col]) - set(("", None))
            for val in col_vals:
                val_samples = set(anns.index[anns[col] == val]) & set(self.dataset.samples)

                YY = len(val_samples & tst_samples)  #  samples with col == val
                YN = len(tst_samples) - YY           #  samples with col != val
                NY = len(val_samples - tst_samples)  # ~samples with col == val
                NN = len(all_samples) - YY - YN - NY # ~samples with col != val

                tab = [ [ YY, YN ], [ NY, NN ] ]
                odds, p_val = scipy.stats.fisher_exact(tab, alternative='greater')
                if p_val > 0.05:
                    continue
                if math.isnan(odds) or math.isinf(odds): odds = str(odds)
                out.append(dict(
                    key = col,
                    val = val,
                    p_val = p_val,
                    odds = odds,
                    tab = tab
                ))
        out.sort(key = lambda x: x['p_val'])

        return out

    @view_config(route_name="mistic.json.dataset.samples", request_method="GET", renderer="json")
    def samples(self):
        filters = self.request.GET.items()
        samples = set(self.dataset.cannotation.data.index) & set(self.dataset.samples)

        for k,v in filters:
            if k in self.dataset.cannotation.data.columns:
                samples = [ s for s in samples if self.dataset.cannotation.data[k][s] == v ]
        return sorted(samples)


    @view_config(route_name="mistic.json.dataset.search", request_method="GET", renderer="json")
    def search(self):
        query = self.request.GET.getall('q')
        query = sum([ q.split() for q in query ], [])
        query = [ re.compile(re.escape(q), re.I) for q in query if q != '' ]

        if query == []:
            return []

        limit = self.request.GET.get('l')

        try:
            limit = int(limit)
        except:
            limit = 100
        limit = min(limit, 100)

        def match_any(text):
            if text is None: return False
            for q in query:
                if q.match(text) is not None: return True
            return False

        def match_all(text):
            if text is None: return False
            for q in query:
                if q.match(text) is None: return False
            return True

        ann = self.dataset.annotation.data
        ann_in_ds = self.dataset.annotation_in_ds
        try:
            symbol_matches = set(ann.index[ann_in_ds & ann.symbol.map(match_any)])
        except KeyError:
            symbol_matches = set()

        try:
            id_matches = set(self.dataset.data.df.index[self.dataset.data.df.index.map(match_any)])
        except KeyError:
            id_matches = set()

        try:
            name_matches = set(ann.index[ann_in_ds & ann.name.map(match_all)])
        except KeyError:
            name_matches = set()

        out_ids = id_matches | symbol_matches
        additional_ids = name_matches - out_ids

        out = [
            dict(id = i,
                 symbol = self.dataset.annotation.get_symbol(i) if (self.dataset.annotation.get_symbol(i)!= None) else unicode(i),
                 name = self.dataset.annotation.get_name(i) if (self.dataset.annotation.get_name(i)!= None) else unicode(i))
            for i in out_ids ]
        out.sort(key = lambda r: r['symbol'])

        additional = [
            dict(id = i,
                 symbol = self.dataset.annotation.get_symbol(i) if (self.dataset.annotation.get_symbol(i)!= None) else unicode(i),
                 name = self.dataset.annotation.get_name(i) if (self.dataset.annotation.get_name(i)!= None) else unicode(i))
            for i in additional_ids ]

        additional.sort(key = lambda r: r['symbol'])

        return (out + additional)[:limit]

    @view_config(route_name="mistic.json.dataset.mds", request_method="GET", renderer="json")
    def mds(self):
        xform = self.request.GET.get('x')
        if xform not in self.dataset.transforms:
            xform = self.dataset.transforms[0]

        genes = json.loads(self.request.GET.get('genes'))

        mds_matrix, eigenvalues = self.dataset.calcMDS(genes, xform)
        return dict(id_samples = list(self.dataset.data.colnames), dimensions = map(list, mds_matrix), eigenvalues = list(eigenvalues))

    @view_config(route_name="mistic.json.dataset.mst", request_method="GET", renderer="json")
    def mst(self):
        return self.dataset.mst(self.request.matchdict['xform'])

    @view_config(route_name="mistic.json.dataset.mapped_mst", request_method="GET", renderer="json")
    def mapped_mst(self):
        mst = self.dataset.mst(self.request.matchdict['xform'])
        if mst is None:
            return None
        nodes, edges, pos = mst
        mapped_nodes = data.orthology.map_ids(nodes, self.dataset.annotation.id, self.request.matchdict['tgt_annotation'])
        mapped_nodes = [ list(x)[0] if len(x) == 1 else None for x in mapped_nodes ]

        return mapped_nodes, edges, pos

    @view_config(route_name="mistic.json.dataset.geneset.enrich", request_method="POST", renderer="json")
    def genesets_enrichment (self):

     genes = set(json.loads(self.request.POST['genes']))
     a = self.dataset.annotation

     from mistic.util import geneset
     gs_tab = geneset.genesetOverRepresentation(genes, a.genes, a.all_genesets())

     for r in gs_tab:
         x = r['id']
         info = a.geneset_info(x)
         info = info.replace({numpy.nan : ''})
         r['info'] = dict(info)
         r['name'] = info.get('name', '')
         r['desc'] = info.get('desc', '')
         x, r['id'] = x.rsplit(':', 1)

         if '.' in x:
           r['gs'], r['cat'] = x.split('.', 1)
         else:
           r['gs'], r['cat'] = x, ''

     return gs_tab


class DatasetSample(Dataset):
    def __init__(self, request):
        super(DatasetSample, self).__init__(request)
        self.sample = request.matchdict['sample_id']
        self.row = self.dataset.cannotation.get(self.sample)
        if self.row is None:
            raise HTTPNotFound()

    @view_config(route_name="mistic.json.sample", request_method="GET", renderer="json")
    def index(self):
        return dict(self.row)



class DatasetGene(Dataset):
    def __init__(self, request):
        super(DatasetGene, self).__init__(request)
        self.gene = request.matchdict['gene_id']
        self.row = self.dataset.data.r(self.gene)
        self.x = self.request.GET.get('x')

    @view_config(route_name="mistic.json.gene", request_method="GET", renderer="json")
    def index(self):
        return dict(
            id = self.gene,
            genesets = sorted(self.dataset.annotation.get_geneset_ids(self.gene)),
            name = self.dataset.annotation.get_name(self.gene))

    @view_config(route_name="mistic.json.gene.utest", request_method="GET", renderer="json")
    def utest(self):
        result = self.dataset.genecorr(self.gene, self.x)
        result.sort(key = lambda x: (x[2], x[0]))
        go = [ self.dataset.annotation.go.get(x[1], set()) for x in result ]
        all_go = set()
        for g in go:
            all_go.update(g)

        go_limit = set(self.request.GET.getall('go'))
        if len(go_limit):
            all_go = all_go & go_limit

        out = []
        corr_go = zip([ x[2] for x in result ], go)
        for g in all_go:
            r1 = [ i for i,(x,y) in enumerate(corr_go) if g in y ]
            u, prob = urank(r1, len(corr_go))
            # r1 = [ x for x,y in corr_go if g in y ]
            # r2 = [ x for x,y in corr_go if g not in y ]
            # u, prob = scipy.stats.mannwhitneyu(r1, r2)
            print g, len(r1)
            t = data.ontology.nodes.get(g)
            if t is None:
                desc = ''
            else:
                desc = t.desc
            out.append((prob, u, g, desc))
            print out[-1]
        out.sort()
        return out

    @view_config(route_name="mistic.json.gene.gorilla", request_method="GET", renderer="json")
    def gorilla(self):
        result = self.dataset.genecorr(self.gene, self.x)
        result.sort(key = lambda x: (x[2], x[0]))
        go = [ self.dataset.annotation.go.get(x[1], set()) for x in result ]
        all_go = set()

        for g in go:
            all_go.update(g)

        go_limit = set(self.request.GET.getall('go'))
        if len(go_limit):
            all_go = all_go & go_limit

        vec = numpy.zeros(len(result), numpy.intc)

        out = []
        for g in all_go:
            for i, j in enumerate(go):
                vec[i] = 1 if g in j else 0
            pvec, pmin, counts = gorilla.gorilla(vec)
            t = data.ontology.nodes.get(g)
            if t is None:
                desc = ''
            else:
                desc = t.desc
            out.append((pmin, counts, g, desc))
            print out[-1]
        out.sort()
        return out

    @view_config(route_name="mistic.json.gene.corr", request_method="GET", renderer="json")
    def corr(self):
        absthresh = self.request.GET.get('a')
        thresh = self.request.GET.get('t')

        return self.dataset.genecorr(self.gene, xform = self.x, absthresh = absthresh, thresh = thresh)

    @view_config(route_name="mistic.json.gene.expr", request_method="GET", renderer="json")
    def expr(self):
        return self.dataset.expndata(self.gene, self.x)

class Attr(object):
    def __init__(self, request):
        self.request = request

    @view_config(route_name="mistic.json.attr.set", request_method="POST", renderer="json")
    def set(self):
        return JSONStore.store(DBSession(), json.dumps(self.request.json_body))

    @view_config(route_name="mistic.json.attr.get", request_method="GET")
    def get(self):
        val = JSONStore.fetch(DBSession(), self.request.matchdict['id'])
        if val is None:
            raise HTTPNotFound()
        return Response(val, content_type='application/json')


