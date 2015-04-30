<%!
import mistic.app.data as data
import json

%>
<%
terms = []
for ds in datasets:
  for k,v in ds.tags.iteritems():
    if k not in terms:
      terms.append(k)
%>
<% ff = dict([(f.split(':')[0], int(f.split(':')[1])) for f in favorite]) %>

<table class="dataset-table">
  <thead>
    <tr>
      <th></th>
      <th>Dataset</th>
%for term in terms:
      <th>${term}</th>
%endfor
      <th>n</th>
    </tr>
  </thead>
  <tbody>
%for ds in datasets:
    <tr data-dataset="${ds.id}">
    <td><span style="display:none">${ff.get(ds.id, 0)}</span> 
      %if ff.get(ds.id, 0)>0 : 
        &#x2736
      %endif</td>
    <td>${ds.name}</td>
  %for term in terms:
      <td>${ds.tags.get(term, '')}</td>
  %endfor
      <td>${ds.numberSamples}</td>
    </tr>
%endfor
  </tbody>
</table>
