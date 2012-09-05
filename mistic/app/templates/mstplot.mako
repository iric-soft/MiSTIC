<%!
import json
import mistic.app.data as data
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">MST</%block>
<%block name="actions">
  ${parent.actions()}
</%block>
<%block name="controls">
</%block>
<%block name="style">
${parent.style()}

path.arc:hover {
  fill: #346;
}

</%block>
<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/djset.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/node.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/mstplot.js')}" type="text/javascript"></script>

<script type="text/javascript">
<%
  ds = data.datasets.get(dataset)
  a = ds.annotation
  info = dict([
   (g, dict(
     sym = a.attrs.get(g, {}).get('symbol'),
     name = a.attrs.get(g, {}).get('name'),
     ch =  a.attrs.get(g, {}).get('chromosome')
   )) for g in nodes ])
%>
$(document).ready(function() {
  var nodes = ${json.dumps(nodes)|n};
  var edges = ${json.dumps(edges)|n};
  var pos   = ${json.dumps(  pos)|n};
  var info  = ${json.dumps( info)|n};

  current_graph = new mstplot();

  current_graph.setData(nodes, edges, info, pos);
  current_graph.draw();

  $('div#graph').append(current_graph.svg);
});
</script>
</%block>
