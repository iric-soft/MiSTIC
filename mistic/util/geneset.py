import scipy.stats

def genesetOverRepresentation(identifiers, background, geneset_ids):
  """
  Compute a table of over-representation of genesets for a given set of identifiers.

  :param:  identifiers:       the list of gene ids to test for go over-representation.
  :param:  background         the background list of gene ids
  :param:  geneset_ids:       a dictionary mapping go ids to sets of gene ids.
  :return:                    list of dicts containing over-represented geneset ids.
  """
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

    tab = [ [ YY, YN ], [ NY, NN ] ]

    odds, p_val = scipy.stats.fisher_exact(tab)

    if odds < 1 or p_val > 0.05:
      continue

    gs_tab.append(dict(
      id = gsid,
      tab = tab,
      p_val = p_val,
      odds = odds,
      genes = sorted(gsid_genes)
    ))

  gs_tab.sort(key = lambda d: d['p_val'])
  return gs_tab
