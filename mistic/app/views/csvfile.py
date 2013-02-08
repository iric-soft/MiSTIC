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


  @view_config(route_name="mistic.csv.corrds")
  def corr_csv_all_dataset (self):
    
    _gene = self.request.matchdict['gene']
    _dataset_name = self.request.matchdict['dataset']
    _dataset = data.datasets.get( _dataset_name)
    
    if _dataset is None:
      raise HTTPNotFound()
      
    _experiment = _dataset.experiment
    _symbol =_dataset.annotation.symbol.get(_gene, '')
        
    datasets = [dataset for dataset in  data.datasets.all() if dataset.experiment==_experiment]
    
    symbols = [dataset.symbols for dataset in  datasets]
    symbols = list(set([item for sublist in symbols for item in sublist]))
    symbols.sort()
    
    results = {}
    for dataset in datasets :  
      
      row = dataset.data.r(_gene)
      if row == -1:
        try : 
          idd =  [y for x in dataset.annotation.symbol.items() for y in x]
          d = dict([(str(k), v) for k,v in zip (idd[1::2], idd[::2])])
          row = dataset.data.r(d.get(str(_gene)))
          
        except Exception, e:
          print e, _gene
          raise HTTPNotFound()
      
      spearman = dataset.data.rowcorr(row, transform = RankTransform())
      pearson  = dataset.data.rowcorr(row, transform = LogTransform())

      result = [
                (i1, r1,
                 dataset.annotation.symbol.get(r1, ''),
                 dataset.annotation.desc.get(r1, ''),
                 r, s)
                for (i1, r1, r), (i2, r2, s) in zip(pearson, spearman) ]
      
      results[dataset.info.get('id')] = dict([(str(r[2]), r) for r in result])
      
    header = [  ]
    for k in results.keys(): 
      header = header + ['%s ident' %k, '%s symbol'%k, '%s desc'%k  ,'%s pearson'%k, '%s spearman'%k]
    
    res = []
    for symbol in symbols :
      rr = []
      for k in results.keys(): 
        rs = results[k].get(symbol, ['']*6)
        rr= rr + [rs[1], rs[2], rs[3], rs[4], rs[5]]
      res.append(rr)
   
    
    
    resp = Response(
      content_type = 'text/csv',
      content_disposition = 'attachment;filename=' + _dataset_name + '_' + _gene + '.csv')

    w = csv.writer(resp.body_file)
    w.writerow(header)
    w.writerows(res)

    return resp