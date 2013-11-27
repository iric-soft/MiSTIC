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
<table class="dataset-table">
  <thead>
    <tr>
      %for term in terms:
      <th>${term}</th>
      %endfor
      <th>n</th>
    </tr>
  </thead>
  <tbody>
    %for ds in datasets:
    <tr data-dataset="${ds.id}">
      %for term in terms:
      <td>${ds.tags.get(term, '')}</td>
      %endfor
      <td>${ds.numberSamples}</td>
    </tr>
    %endfor
  </tbody>
</table>
