from collections import OrderedDict
import json
import re
import sys

ann = {}
fopen = open(sys.argv[1], 'r')

header =  fopen.readline().strip('\r\n').split('\t')[1:]

for row in fopen:
	k,v = row.strip('\r\n').split('\t', 1)
	v = v.split('\t')	
  	ann[k] = [(header[i],v[i].strip(' ')) for i in range(len(v))]

for k in ann.keys():
	
  	attrs = OrderedDict(ann[k])
	print k, json.dumps(attrs)


