import sys
import os
import math
import numpy
import csv
import itertools
import exceptions
import csv
import pandas



class AnscombeTransform(object):
  def __init__(self):
    pass
  def __call__(self, matrix):
    return 2 * numpy.sqrt(matrix + 3.0 / 8.0)



class LogTransform(object):
  def __init__(self, scale = 1024, bias = 1, base = 2):
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

    mean = (len(idx) + 1) / 2.0
    sd = math.sqrt((len(idx) * len(idx) - 1) / 12.0)

    rank_vals = [ (i - mean) / sd for i in range(1, len(idx) + 1) ]

    for i, r in zip(idx, rank_vals):
      row[i] = r



  def __call__(self, matrix):
    o = (numpy.random.ranf(matrix.shape) - .5) * 0.001

    if hasattr(matrix, 'values'):
      df = numpy.log2(matrix + 0.1 + o)
      d = df.values
      r = df
    else:
      d = numpy.log2(matrix + 0.1 + o)
      r = d

    if len(d.shape) == 1:
      self.rankRow(d)
    else:
      for i in range(len(d)):
        self.rankRow(d[i])

    return r
    

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

  def rowcorr(self, rownum, transform = None):
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
    return cls(pandas.read_csv(file, header=0, index_col=0, sep='\t'))

  @classmethod
  def readCSV(cls, file):
    return cls(pandas.read_csv(file, header=0, index_col=0, sep=','))



import unittest

class DataSetTest(unittest.TestCase):
  def setUp(self):
    self.dataset = DataSet.readTSV(os.path.join(os.path.split(__file__)[0], '..', 'datasets', 'bodymap.txt'))

  def test_log_rowcorr(self):
    log_row_corr = self.dataset.rowcorr(self.dataset.r('RPS14'), LogTransform())
    print log_row_corr
