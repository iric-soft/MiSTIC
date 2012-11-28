<%!
import mistic.app.data as data
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Multi-way scatterplot</%block>


<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/scatterplot.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/pairplot.js')}" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function() {
<%
   ds = data.datasets.get(dataset)
   gene_data = [ ds.expndata(gene) for gene in genes ]
%>

  current_graph = new pairplot(undefined, undefined, $('#graph'));

%for d in gene_data:
  current_graph.addData(${json.dumps(d)|n});
%endfor

  resizeGraph = function() {
    $('div#graph').height($(window).height() - 124);

    current_graph.resize(
      $('div#graph').width(),
      $('div#graph').height());
  };

  $('div#graph').append(current_graph.svg);

  resizeGraph();
  $(window).resize(resizeGraph);
  
  $(".circlelabel").remove();
 
 
 
 
  

});
</script>
</%block>
