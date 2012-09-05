<%!
import mistic.app.data as data
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Correlation waterfall plot</%block>
<%block name="actions">
  <button class="btn" id="download">CSV</button>${parent.actions()}
</%block>
<%block name="controls">
</%block>

<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/corrgraph.js')}" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function() {
<%
   ds = data.datasets.get(dataset)
   if go is not None:
     hl = ds.annotation.gene_set([go])
   else:
     hl = None
%>
  current_graph = new corrgraph([], $('#graph'));

  current_graph.setData(${json.dumps(ds.genecorr(gene, xform='rank')['data'])|n});
%if hl is not None:
  current_graph.markGenes(${json.dumps(hl)|n});
%endif

  resizeGraph = function() {
    current_graph.elem.height($(window).height() - 124);
    current_graph.draw();
  };

  resizeGraph();
  $(window).resize(resizeGraph);
});
</script>
</html>
</%block>
