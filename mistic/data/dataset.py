import sys
import os
import math
import numpy
import csv
import itertools
import exceptions



class AnscombeTransform(object):
  def __init__(self):
    pass
  def __call__(self, matrix):
    return 2 * numpy.sqrt(matrix + 3.0 / 8.0)



class LogTransform(object):
  def __init__(self, scale = 1024, bias = 1, base = 2):
    self.params = (scale, bias, base)
  def __call__(self, matrix):
    print matrix
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
  def __call__(self, matrix):
    o = (numpy.random.ranf(matrix.shape) - .5) * 0.001
    return numpy.log2(matrix + 0.1 + o).argsort().argsort().astype(numpy.int)



class DataSet(object):
  def __init__(self, colnames, rownames, data):
    self.colnames = colnames
    self.rownames = rownames
    self.data = numpy.array(data)
    
    self.colname_to_col = dict([ (k, i) for i, k in enumerate(self.colnames) ])
    self.rowname_to_row = dict([ (k, i) for i, k in enumerate(self.rownames) ])

  def filter(self, rowfilter):
    keep = [ bool(rowfilter(row, name)) for row, name in zip(self.data, self.rownames) ]
    self.data = self.data[numpy.array(keep),:]
    self.rownames = [ name for name, flag in zip(self.rownames, keep) if flag ]

  def _corr(self, transform = None):
    if transform is None:
      data = self.data
    else:
      data = transform(self.data)
      
    return numpy.corrcoef(data)

  def rowcorr(self, rownum, transform = None):
    row = self.data[rownum,:]
    print 'rownum', rownum
    if transform is not None: row = transform(row)
    out = []
    for i, r in enumerate(self.rownames):
      print i, r
      row2 = self.data[i,:]
      if transform is not None: row2 = transform(row2)
      print row, row2
      c = numpy.corrcoef(row, row2)[0,1]
      
      if math.isnan(c): c = 0.0
      out.append((i, r, c))
    return out

  def row(self, rownum, transform = None):
    row = self.data[rownum,:]
    if transform is not None: row = transform(row)
    return row

  def r(self, rowname):
    return self.rowname_to_row.get(rowname, -1)

  def c(self, colname):
    return self.colname_to_col.get(colname, -1)

  def _write(self, csv_writer):
    csv_writer.writerow([''] + self.colnames)
    for rowname, vals in itertools.izip(self.rownames, self.data):
      csv_writer.writerow([rowname] + map(repr, vals))

  def writeTSV(self, file):
    if isinstance(file, basestring):
      file = open(file, 'wb')
    return self._write(csv.writer(file, dialect = csv.excel_tab))

  def writeCSV(self, file):
    if isinstance(file, basestring):
      file = open(file, 'wb')
    return self._write(csv.writer(file, dialect = csv.excel_tab))

  @classmethod
  def _read(cls, csv_reader):
    def F(x):
      try:
        return float(x)
      except:
        return None

    colnames = csv_reader.next()[1:]
    rownames = []
    vals = []
    for row in csv_reader:
      rownames.append(row[0])
      vals.append(map(F, row[1:]))

    return cls(colnames, rownames, vals)

  @classmethod
  def readTSV(cls, file):
    if isinstance(file, basestring):
      file = open(file, 'rbU')
    return cls._read(csv.reader(file, dialect = csv.excel_tab))

  @classmethod
  def readCSV(cls, file):
    if isinstance(file, basestring):
      file = open(file, 'rbU')
    return cls._read(csv.reader(file, dialect = csv.excel))




import unittest

class DataSetTest(unittest.TestCase):
  def setUp(self):
    self.dataset = DataSet.readTSV(os.path.join(os.path.split(__file__)[0], '..', 'datasets', 'bodymap.txt'))

  def test_log_rowcorr(self):
    log_row_corr = self.dataset.rowcorr(self.dataset.r('RPS14'), LogTransform())
    print log_row_corr
