from pyramid.httpexceptions import HTTPFound, HTTPNotFound, HTTPBadRequest
from pyramid.view import view_config
from pyramid.response import Response
from pyramid.renderers import render_to_response

from mistic.app import data

import json



class Graph(object):
  def __init__(self, request):
    self.request = request

  @view_config(route_name="mistic.modal.datasets")
  def dataset_modal(self):
    datasets = data.datasets.all()

    incl = self.request.GET.getall('i')
    if len(incl):
      datasets = [ ds for ds in datasets if ds.id in incl ]

    excl = self.request.GET.getall('x')
    if len(excl):
      datasets = [ ds for ds in datasets if ds.id not in excl ]

    anot = self.request.GET.getall('anot')
    if len(anot):
      datasets = [ ds for ds in datasets if ds.annotation.id in anot ]

    args = dict(datasets = datasets)
    return render_to_response('mistic:app/templates/fragments/dataset_modal.mako', args, request = self.request)

  @view_config(route_name="mistic.modal.geneset_categories")
  def _modal(self):
    dataset = self.request.matchdict['dataset']
    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    args = dict(dataset = dataset)
    return render_to_response('mistic:app/templates/fragments/geneset_category_modal.mako', args, request = self.request)

  @view_config(route_name="mistic.template.root")
  def root(self):
    args = dict()
    return render_to_response('mistic:app/templates/root.mako', args, request = self.request)

  @view_config(route_name="mistic.template.corrdistrib")
  def corrdistrib(self):
    dataset = self.request.matchdict['dataset']

    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    args = dict(
      dataset = dataset,
      xform = _dataset.transforms[0],
    )
    return render_to_response('mistic:app/templates/corrdistrib.mako', args, request = self.request)

  @view_config(route_name="mistic.template.mds")
  def mds(self):
    dataset = self.request.matchdict['dataset']

    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    xform = self.request.GET.get('x')
    if xform not in _dataset.transforms:
      xform = _dataset.transforms[0]

    try:
      n_genes = int(self.request.GET.get('n'))
    except (ValueError, TypeError):
      n_genes = 500

    try:
      n_skip = int(self.request.GET.get('s'))
    except (ValueError, TypeError):
      n_skip = 0

    pairwise = self.request.GET.get('p') == 't'

    args = dict(
      dataset = _dataset,
      xform = xform,
      n_genes = n_genes,
      n_skip = n_skip,
      pairwise = pairwise,
    )

    return render_to_response('mistic:app/templates/mdsplot.mako', args, request = self.request)

  @view_config(route_name="mistic.template.corrgraph")
  def corrgraph(self):
    args = dict(dataset = None, gene = None)
    return render_to_response('mistic:app/templates/corrgraph.mako', args, request = self.request)

  @view_config(route_name="mistic.template.corrgraph.2")
  def corrgraph2(self):
    dataset = self.request.matchdict['dataset']

    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    gene = self.request.GET.get('gene')
    if gene is not None:
      _row = _dataset.data.r(gene)
      if _row == -1:
        raise HTTPNotFound()

    args = dict(dataset = _dataset, gene = gene)
    return render_to_response('mistic:app/templates/corrgraph.mako', args, request = self.request)

  @view_config(route_name="mistic.template.corrgraph_static")
  def corrgraph_static(self):
    dataset = self.request.matchdict['dataset']
    gene = self.request.matchdict['gene']
    go_term = self.request.GET.getall('go')

    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    _row = _dataset.data.r(gene)
    if _row == -1:
      raise HTTPNotFound()

    args = dict(
      dataset = dataset,
      gene = gene,
      go = None if len(go_term) == 0 else go_term[0]
    )
    return render_to_response('mistic:app/templates/corrgraph_static.mako', args, request = self.request)

  @view_config(route_name="mistic.template.scatterplot")
  def scatterplot(self):
    args = dict()
    return render_to_response('mistic:app/templates/scatterplot.mako', args, request = self.request)

  @view_config(route_name="mistic.template.scatterplot_static")
  def scatterplot_static(self):
    dataset = self.request.matchdict['dataset']
    gene1 = self.request.matchdict['gene1']
    gene2 = self.request.matchdict['gene2']

    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    _row1 = _dataset.data.r(gene1)
    if _row1 == -1:
      raise HTTPNotFound()
    _row2 = _dataset.data.r(gene2)
    if _row2 == -1:
      raise HTTPNotFound()

    args = dict(
      dataset = dataset,
      gene1 = gene1,
      gene2 = gene2,
    )
    return render_to_response('mistic:app/templates/scatterplot_static.mako', args, request = self.request)


  @view_config(route_name="mistic.template.pairplot")
  def pairplot(self):

    dataset = self.request.matchdict.get('dataset', None)
    genes = self.request.matchdict.get('genes', [])
    args = dict(
      dataset = dataset,
      genes = genes,
    )

    return render_to_response('mistic:app/templates/pairplot.mako', args, request = self.request)


  @view_config(route_name="mistic.template.clustering")
  def clustering(self):
    dataset = self.request.matchdict['dataset']
    xform = self.request.matchdict['xform']


    _dataset = data.datasets.get(dataset)

    if _dataset is None:
      print 'Not found'

      raise HTTPNotFound()

    mst = _dataset.mst(xform)

    if mst is None:
      raise HTTPNotFound()

    args = dict(
      dataset = self.request.matchdict['dataset'],
      xform = self.request.matchdict['xform'],
      nodes = mst[0],
      edges = mst[1],
      pos = mst[2]
    )

    return render_to_response('mistic:app/templates/clustering.mako', args, request = self.request)

  @view_config(route_name="mistic.template.mstplot", request_method="POST")
  def mstplot_post(self):
    dataset = self.request.matchdict['dataset']
    xform = self.request.matchdict['xform']

    geneset = set(json.loads(self.request.POST['geneset']))

    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    mst = _dataset.mst_subset(xform, geneset)

    if mst is None:
      raise HTTPNotFound()

    args = dict(
      dataset = self.request.matchdict['dataset'],
      xform = self.request.matchdict['xform'],
      nodes = mst[0],
      edges = mst[1],
      pos = mst[2]
    )

    if len(mst[0]) < 200:

      if _dataset.experiment=="ngs":
        return render_to_response('mistic:app/templates/mstplot_small.mako', args, request = self.request)
      else:
        if _dataset.experiment=="hts":
          return render_to_response('mistic:app/templates/mstplot_small_chemical.mako', args, request = self.request)
        else:
          return render_to_response('mistic:app/templates/mstplot_small.mako', args, request = self.request)
    else:
      return render_to_response('mistic:app/templates/mstplot.mako', args, request = self.request)



  @view_config(route_name="mistic.template.mstplot", request_method="GET")
  def mstplot_get(self):
    dataset = self.request.matchdict['dataset']
    xform = self.request.matchdict['xform']

    _dataset = data.datasets.get(dataset)
    if _dataset is None:
      raise HTTPNotFound()

    mst = _dataset.mst(xform)
    if mst is None:
      raise HTTPNotFound()

    args = dict(
      dataset = self.request.matchdict['dataset'],
      xform = self.request.matchdict['xform'],
      nodes = mst[0],
      edges = mst[1],
      pos = mst[2]
    )

    if len(mst[0]) < 200:
      return render_to_response('mistic:app/templates/mstplot_small.mako', args, request = self.request)
    else:
      return render_to_response('mistic:app/templates/mstplot.mako', args, request = self.request)

