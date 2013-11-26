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
<div class="modal-dialog">
  <div class="modal-content">
    <div class="modal-header">
      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
      <h4 class="modal-title">Dataset selector</h4>
    </div>
    <div class="modal-body">
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
    </div>
    <div class="modal-footer">
      <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
    </div>
  </div>
</div>
