import lxml.etree
import lxml.etree
import sys
import json

def intOrNone(x):
    if x == '':
        return None
    return int(x)

doc = lxml.etree.parse(open('msigdb_v4.0.xml'))
root = doc.getroot()

msigdb_info = open('info.txt', 'w')
msigdb_entrez_id = open('entrez_id.txt', 'w')
msigdb_official_symbol = open('official_symbol.txt', 'w')

for geneset in root.xpath('/MSIGDB/GENESET'):

    print >>msigdb_info, geneset.get('SYSTEMATIC_NAME'), json.dumps(dict(
        name = geneset.get('STANDARD_NAME'),
        desc = geneset.get('DESCRIPTION_BRIEF'),
        pmid = intOrNone(geneset.get('PMID')),
        org = geneset.get('ORGANISM'),
        cat = '/'.join([ x for x in [ geneset.get('CATEGORY_CODE'), geneset.get('SUB_CATEGORY_CODE') ] if x ])
    ))

    print >>msigdb_entrez_id, geneset.get('SYSTEMATIC_NAME'), json.dumps(dict(
        ids =geneset.get('MEMBERS_EZID').split(','),
    ))

    print >>msigdb_official_symbol, geneset.get('SYSTEMATIC_NAME'), json.dumps(dict(
        ids =geneset.get('MEMBERS_SYMBOLIZED').split(','),
    ))
