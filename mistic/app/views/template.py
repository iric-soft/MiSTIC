from pyramid.httpexceptions import HTTPFound, HTTPNotFound, HTTPBadRequest
from pyramid.view import view_config
from pyramid.response import Response
from pyramid.renderers import render_to_response
from pyramid.security import authenticated_userid
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

  @view_config(route_name="mistic.template.root")
  def root(self):
   
    args = dict(user=authenticated_userid(self.request))
    return render_to_response('mistic:app/templates/root.mako', args, request = self.request)

  @view_config(route_name="mistic.template.corrgraph")
  def corrgraph(self):
    args = dict()
    return render_to_response('mistic:app/templates/corrgraph.mako', args, request = self.request)

 

  @view_config(route_name="mistic.template.scatterplot")
  def scatterplot(self):
    args = dict()
    return render_to_response('mistic:app/templates/scatterplot.mako', args, request = self.request)

 


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

