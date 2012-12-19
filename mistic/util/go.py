import scipy.stats

def goOverRepresentation(identifiers, go_to_identifiers, ontology):
  """
  Compute a list of over-represented GO terms for a given set of identifiers.

  :param:  identifiers:       the list of gene ids to test for go over-representation.
  :param:  go_to_identifiers: a dictionary mapping go ids to sets of gene ids.
  :param:  ontology:          a parsed form of the GO OBO file
  :return:                    list of dicts containing over-represented GO terms.
  """
  go_tab = []

  identifiers = set(identifiers)
  all_identifiers = set()

  for go_ids in go_to_identifiers.itervalues():
    all_identifiers.update(go_ids)

  identifiers = identifiers & all_identifiers

  for go, go_ids in go_to_identifiers.iteritems():
    genes_with_go_term = go_ids & identifiers

    YY = len(genes_with_go_term)

    if YY == 1:
      continue

    YN = len(identifiers) - YY
    NY = len(go_ids - identifiers)
    NN = len(all_identifiers) - YY - YN - NY

    tab = [ [ YY, YN ], [ NY, NN ] ]

    odds, p_val = scipy.stats.fisher_exact(tab)

    if odds < 1 or p_val > 0.05:
      continue

    go_tab.append(dict(
      id = go,
      ns = ontology.nodes[go].namespace,
      desc = ontology.nodes[go].desc,
      tab = tab,
      p_val = p_val,
      odds = odds,
      genes = sorted(genes_with_go_term)
    ))

  go_tab.sort(key = lambda d: d['p_val'])
  return go_tab
