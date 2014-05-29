<%!
import mistic.app.data as data
import json

%>

<%
  ds = data.datasets.get(dataset)
  a = ds.annotation
%>
<form>
<fieldset>
<ul class="geneset-type-list">
%for gs_id, gs in sorted(a.genesets.items()):
  <li><label class="checkbox"><input type="checkbox" data-geneset-type="${gs_id}"> <b>${gs.name}</b></label>
    <ul class="geneset-cat-list">
%for cat_id in gs.categories:
      <li><label class="checkbox"><input type="checkbox" data-geneset-cat="${gs_id}:${cat_id}"> ${cat_id}</li></label>
%endfor
    </ul>
  </li>
%endfor
</ul>
</fieldset>
</form>
