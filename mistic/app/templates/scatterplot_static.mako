<%!
import mistic.app.data as data
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Pairwise scatterplot</%block>

<%block name="controls">
<div class="btn-group pull-right">
     <button class="btn" data-toggle="button" id="show_labels">
        Toggle labels 
      </button>
</%block>


<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/scatterplot.js')}" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function() {
<%
   ds = data.datasets.get(dataset)
   gene1_data = ds.expndata(gene1)
   gene2_data = ds.expndata(gene2)
%>

  current_graph = new scatterplot();

  var gene1_data = ${json.dumps(gene1_data)|n};
  var gene2_data = ${json.dumps(gene2_data)|n};

  current_graph.setXData(gene1_data);
  current_graph.setYData(gene2_data);

  resizeGraph = function() {
    $('div#graph').height($(window).height() - 124);

    current_graph.resize(
      $('div#graph').width(),
      $('div#graph').height());
  };

  $('div#graph').append(current_graph.svg);

  resizeGraph();
  $(window).resize(resizeGraph);
  
  $('#show_labels').on("click", function(event){
  d3.selectAll("text.circlelabel").classed('invisible', !d3.selectAll("text.circlelabel").classed('invisible'));
  });
  
});
</script>
</%block>
