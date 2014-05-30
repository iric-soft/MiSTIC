import sys
import os
import math
import numpy
import csv
import itertools
import exceptions
import csv
import pandas
import random
import logging

logger = logging.getLogger(__name__)



class AnscombeTransform(object):
  def __init__(self):
    pass
  def __call__(self, matrix):
    return 2 * numpy.sqrt(matrix + 3.0 / 8.0)



class LogTransform(object):
  def __init__(self, scale = 1000, bias = 1, base = 10):
    self.params = (scale, bias, base)

  def __call__(self, matrix):
    
    scale, bias, base = self.params
    if base == 2:
      return numpy.log2(matrix * scale + bias)
    elif base == 10:
      return numpy.log10(matrix * scale + bias)
    elif base == numpy.e:
      return numpy.log(matrix * scale + bias)
    else:
      return numpy.log(matrix * scale + bias) / numpy.log(base)
   


class RankTransform(object):
  def __init__(self):
    pass

  def rankRow(self, row):
    idx = [ i for i, j in enumerate(row) if not numpy.isnan(j) ]
    idx.sort(key = lambda x: row[x])

    mean = (len(idx) - 1) / 2.0
    sd = math.sqrt((len(idx) * len(idx) - 1) / 12.0)

    i = 0
    rv = 0.0
    while i < len(idx):
      j = i
      v = 0.0
      while j < len(idx) and row[idx[i]] == row[idx[j]]:
        v += rv
        rv += 1.0
        j += 1
      v = v / (j-i)
      v = (v - mean) / sd
      while i < j:
        row[idx[i]] = v
        i += 1

  def __call__(self, matrix):
    r = matrix.copy()
    if hasattr(r, 'values'):
      d = r.values
    else:
      d = r
    if len(d.shape) == 1:
      self.rankRow(d)
    else:
      for i in range(len(d)):
        self.rankRow(d[i])
        
    if hasattr(r, 'values'):
        if isinstance(r, pandas.DataFrame) : 
          d = pandas.DataFrame(d, index=matrix.index, columns=matrix.columns, dtype=float)
         
        elif isinstance(r, pandas.Series) : 
          d = pandas.Series(d, index=matrix.index, dtype=float)
         
        else: 
          print 'matrix is %s ' % r.__class__
    return d
    

class DataSet(object):
  @property
  def rownames(self):
    return list(self.df.index)

  @property
  def colnames(self):
    return list(self.df.columns)

  def __init__(self, df):
    self.df = df

  def filter(self, rowfilter):
    self.df = self.df[
      [ bool(rowfilter(row, index)) for index, row in self.df.iterrows() ]
    ]

  def _corr(self, transform = None):
    if transform is None:
      data = self.df
    else:
      data = transform(self.df)

    data = numpy.ma.masked_array(data, numpy.isnan(data))
    return numpy.ma.corrcoef(data)

  def randompaircorr(self, N = 10000, transform = None, permute = False):
    logging.info('randompaircorr begin')
    out = []

    if transform is None:
      data = self.df
    else:
      data = transform(self.df)
    if isinstance(data, pandas.DataFrame):
      data = data.values

    if permute:
      data = numpy.random.permutation(data.T).T

    logging.info('transform done')

    for i in xrange(N):
      if i % 1000 == 0:
        logging.info('...{0}'.format(i))
      a, b = random.sample(xrange(data.shape[0]), 2)

      ra = data[a]
      rb = data[b]

      z = numpy.corrcoef(ra, rb)

      if numpy.isnan(z[0,1]):
        c = 0.0
      else:
        c = z[0,1]

      out.append(c)

    logging.info('correlation done')
    return out

  def rowcorr(self, rownum, transform = None):
    row = self.df.iloc[rownum]

    if transform is not None: row = transform(row)
    
    out = []
    
    for i, r in enumerate(self.df.index):
      row2 = self.df.iloc[i]

      if transform is not None: row2 = transform(row2)
      
      c = row.corr(row2)
      if numpy.isnan(c) : 
        c = 0.0
        
      out.append((i, r, c))
    return out

  def rowcorr_numpy(self, rownum, transform = None):
    row = self.df.values[rownum,:]

    if transform is not None: row = transform(row)
    row = numpy.ma.masked_array(row, numpy.isnan(row))

    out = []
    
    for i, r in enumerate(self.df.index):
      row2 = self.df.values[i,:]

      if transform is not None: row2 = transform(row2)
      row2 = numpy.ma.masked_array(row2, numpy.isnan(row2))
      
     
      z = numpy.ma.corrcoef(row, row2)
     
      if z.mask[0,1] or numpy.isnan(z[0,1]):
        c = 0.0
      else:
        c = z[0,1]

        
      out.append((i, r, c))
    return out

  def row(self, rownum, transform = None):
    row = self.df.values[rownum,:]
    if transform is not None:
      row = transform(row)
    return row

  def hascol(self, colname):
    return colname in self.df.columns

  def hasrow(self, rowname):
    return rowname in self.df.index

  def r(self, rowname):
    try:
      return self.df.index.get_loc(rowname)
    except KeyError:
      return -1

  def c(self, colname):
    try:
      return self.df.columns.get_loc(colname)
    except KeyError:
      return -1

  def writeTSV(self, file):
    self.df.to_csv(file, mode='w', encoding='utf-8', sep='\t')

  def writeCSV(self, file):
    self.df.to_csv(file, mode='w', encoding='utf-8', sep=',')

  @classmethod
  def readTSV(cls, file):
    x = pandas.read_table(file, header=0, converters={ 0: str })
    y = pandas.DataFrame(x.values[:,1:], columns = x.columns[1:], index = x[x.columns[0]], dtype=float)
    return cls(y)

  @classmethod
  def readCSV(cls, file):
    x = pandas.read_csv(file, header=0, converters={ 0: str })
    y = pandas.DataFrame(x.values[:,1:], columns = x.columns[1:], index = x[x.columns[0]], dtype=float)
    return cls(y)



import unittest

class DataSetTest(unittest.TestCase):
  def setUp(self):
    self.dataset = DataSet.readTSV(os.path.join(os.path.split(__file__)[0], '..', 'datasets', 'bodymap.txt'))

  def test_log_rowcorr(self):
    log_row_corr = self.dataset.rowcorr(self.dataset.r('RPS14'), LogTransform())
    print log_row_corr
