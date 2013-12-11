import numpy
import scipy.stats
import math
from mistic.util.json_helpers import *

def chi2_yates(((a,b),(c,d))):
  if any([ x < 0 for x in (a,b,c,d) ]):
    return None

  a,b,c,d = float(a),float(b),float(c),float(d)
  t = a+b+c+d
  ea = (a+b) * (a+c) / t
  eb = (b+a) * (b+d) / t
  ec = (c+a) * (c+d) / t
  ed = (d+b) * (d+c) / t

  if any([ x == 0.0 for x in (ea,eb,ec,ed) ]):
    return None

  return (
    math.pow(abs(a - ea) - 0.5, 2) / ea +
    math.pow(abs(b - eb) - 0.5, 2) / eb +
    math.pow(abs(c - ec) - 0.5, 2) / ec +
    math.pow(abs(d - ed) - 0.5, 2) / ed
  )

def genesetOverRepresentation(identifiers, background, geneset_ids):
  """
  Compute a table of over-representation of genesets for a given set of identifiers.

  :param:  identifiers:       the list of gene ids to test for go over-representation.
  :param:  background         the background list of gene ids
  :param:  geneset_ids:       a generator mapping go ids to sets of gene ids.
  :return:                    list of dicts containing over-represented geneset ids.
  """
  dir ()
  gs_tab = []
  background = set(background)
  identifiers = set(identifiers) & background
  
  for gsid, gsid_genes in geneset_ids:
    gsid_genes = set(gsid_genes)
    genes_in_geneset = gsid_genes & identifiers

    YY = len(genes_in_geneset)
    YN = len(identifiers) - YY
    NY = len(gsid_genes - identifiers)
    NN = len(background) - YY - YN - NY

    _tab = [ [ YY, YN ], [ NY, NN ] ]
    tab = numpy.array(_tab, dtype=numpy.int64)

    if tab[1,0] > 0 and tab[0,1] > 0:
        odds = tab[0,0] * tab[1,1] / float(tab[1,0] * tab[0,1])
    else:
        odds = numpy.inf

    if odds < 1:
      continue

    chi2 = chi2_yates(_tab)
    if chi2 < 2.5:
      continue

    odds, p_val = scipy.stats.fisher_exact(tab)

    if p_val > 0.05:
      continue
    
    gs_tab.append(dict(
      id = gsid,
      tab = _tab,
      p_val = safeFloat(p_val),
      odds = safeFloat(odds),
      genes = sorted(gsid_genes)
    ))

  gs_tab.sort(key = lambda d: d['p_val'])
  return gs_tab



__all__ = [
  'genesetOverRepresentation',
]
