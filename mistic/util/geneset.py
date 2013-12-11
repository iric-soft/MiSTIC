import numpy
import scipy.stats
import math
from mistic.util.json_helpers import *


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
