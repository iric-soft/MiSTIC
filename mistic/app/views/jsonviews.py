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

import pickle
import os


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
                namespace = node.namespace,
                desc = node.desc)

            if (any([ q.match(r['id'])     is not None for q in query ]) or
                all([ q.search(r['desc'])  is not None for q in query ])):
                out.append(r)
        out.sort(key = lambda r: r['id'])
        out = out[:limit]
        print out
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
            namespace = self.node.namespace,
            desc = self.node.desc)

    @view_config(route_name="mistic.json.go.desc", request_method="GET", renderer="json")
    def desc(self):
        return self.node.desc



class Annotation(object):
    def __init__(self, request):
        self.request = request
        self.annotation = data.annotations.get(request.matchdict['annotation'])
        if self.annotation is None:
            raise HTTPNotFound()

    @view_config(route_name="mistic.json.annotation.gene_ids", request_method="GET", renderer="json")
    def gene_ids(self):
        return self.annotation.gene_set(self.request.GET.getall('go'))

    @view_config(route_name="mistic.json.annotation.genes", request_method="GET", renderer="json")
    def genes(self):
        result = self.annotation.gene_set(self.request.GET.getall('go'))
        go_ns = set(self.request.GET.getall('go_ns'))
        if len(go_ns) == 0:
            go_ns = set(('biological_process', 'molecular_function', 'cellular_component'))

        return [ dict(id = gene,
                      symbol = self.annotation.symbol.get(gene),
                      desc = self.annotation.desc.get(gene),
                      go = sorted([
                        go
                        for go in self.annotation.go.get(gene, set())
                        if data.ontology.nodes[go].namespace in go_ns
                        # if go in data.ontology.nodes and data.ontology.nodes[go].namespace in go_ns
                      ]))
                 for gene in result ]



class AnnotationGene(Annotation):
    def __init__(self, request):
        super(AnnotationGene, self).__init__(request)
        self.gene = self.request.matchdict['gene_id']
        if self.gene not in self.annotation.genes:
            raise HTTPNotFound()

    @view_config(route_name="mistic.json.annotation.gene", request_method="GET", renderer="json")
    def gene(self):
        return dict(id = self.gene,
                    desc = self.annotation.desc.get(self.gene),
                    go = sorted(self.annotation.go.get(self.gene, ())))

    @view_config(route_name="mistic.json.annotation.gene.desc", request_method="GET", renderer="json")
    def desc(self):
        return self.annotation.desc.get(self.gene)

    @view_config(route_name="mistic.json.annotation.gene.go", request_method="GET", renderer="json")
    def go(self):
        return sorted(self.annotation.go.get(self.gene, ()))



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

    @view_config(route_name="mistic.json.dataset.samples", request_method="GET", renderer="json")
    def samples(self):
        return self.dataset.samples
      
       
    @view_config(route_name="mistic.json.dataset.search", request_method="GET", renderer="json")
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
        additional = []

        for i, gene in enumerate(self.dataset.genes):
            r = dict(
                id = gene,
                idx = i,
                symbol = self.dataset.annotation.symbol.get(gene, ''),
                desc = self.dataset.annotation.desc.get(gene, '')
            )

            if (any([ q.match(r['symbol']) is not None for q in query ]) or
                any([ q.match(r['id'])     is not None for q in query ])):
                out.append(r)
            elif all([ q.search(r['desc'])  is not None for q in query ]):
                additional.append(r)

        out.sort(key = lambda r: r['symbol'])
        additional.sort(key = lambda r: r['symbol'])
        return (out + additional)[:limit]

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



class DatasetGene(Dataset):
    def __init__(self, request):
        super(DatasetGene, self).__init__(request)
        self.gene = request.matchdict['gene_id']
        self.row = self.dataset.data.r(self.gene)
        if self.row == -1:
            raise HTTPNotFound()

        self.x = self.request.GET.get('x')

    @view_config(route_name="mistic.json.gene", request_method="GET", renderer="json")
    def index(self):
        return dict(
            id = self.gene,
            go = sorted(self.dataset.annotation.go.get(self.gene)),
            desc = self.dataset.annotation.desc.get(self.gene))

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
