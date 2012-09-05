from pyramid.httpexceptions import HTTPFound, HTTPNotFound, HTTPBadRequest
from pyramid.view import view_config
from pyramid.response import Response
from pyramid.renderers import render_to_response

from mistic.data.dataset import *
from mistic.app import data

import csv


class CSVData(object):
  def __init__(self, request):
    self.request = request

  @view_config(route_name="mistic.csv.corr")
  def corrcsv(self):
    _dataset = self.request.matchdict['dataset']
    _gene = self.request.matchdict['gene']

    dataset = data.datasets.get(_dataset)
    if dataset is None:
      raise HTTPNotFound()

    row = dataset.data.r(_gene)
    if row == -1:
      raise HTTPNotFound()

    spearman = dataset.data.rowcorr(row, transform = RankTransform())
    pearson  = dataset.data.rowcorr(row, transform = LogTransform())

    result = [
      (i1, r1,
       dataset.annotation.symbol.get(r1, ''),
       dataset.annotation.desc.get(r1, ''),
       r, s)
      for (i1, r1, r), (i2, r2, s) in zip(pearson, spearman) ]

    header = [ 'idx', 'ident', 'symbol', 'desc', 'pearson', 'spearman' ]

    resp = Response(
      content_type = 'text/csv',
      content_disposition = 'attachment;filename=' + _dataset + '_' + _gene + '.csv')

    w = csv.writer(resp.body_file)
    w.writerow(header)
    w.writerows(result)

    return resp
