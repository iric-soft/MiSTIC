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
  <form class="form-inline">

    <div class="accordion" id="accordion">
      <div class="accordion-group">
        <div class="accordion-heading">
          <h4 class="accordion-title">
            <a class="accordion-toggle" data-toggle="collapse" href="#selection">Selection</a>
          </h4>
        </div>

        <div id="selection" class="accordion-body collapse in">
          <div class="accordion-inner">
            <button id="clear_all" class="btn">Clear all</button>
          </div>
        </div>
      </div>

      <div class="accordion-group">
        <div class="accordion-heading">
          <h4 class="accordion-title">
            <a class="accordion-toggle" data-toggle="collapse" href="#locate_gene">Locate gene</a>
          </h4>
        </div>

        <div id="locate_gene" class="accordion-body collapse in">
          <div class="accordion-inner">
            <span id="genelist"></span>
            <label for="gene">Gene:</label>
            <input type="text" id="gene">
          </div>
        </div>
      </div>

      <div class="accordion-group">
        <div class="accordion-heading">
          <h4 class="accordion-title">
            <a class="accordion-toggle" data-toggle="collapse" href="#locate_geneset">Locate geneset</a>
          </h4>
        </div>

        <div id="locate_geneset" class="accordion-body collapse in">
          <div class="accordion-inner">
            <div id="geneset_selector"></div>
          </div>
        </div>
      </div>

    </div>
  </form>
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
<script src="${request.static_url('mistic:app/static/js/lib/geneset_category_selector.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/geneset_selector.js')}" type="text/javascript"></script>

<script type="text/javascript">
<%
  ds = data.datasets.get(dataset)
  a = ds.annotation
  info = dict([
   (g, dict(
     sym = a.get_symbol(g),
     name = a.get_name(g)
   )) for g in nodes ])
%>

$(document).ready(function() {
  var nodes = ${json.dumps(nodes)|n};
  var edges = ${json.dumps(edges)|n};
  var pos   = ${json.dumps(  pos)|n};
  var info  = ${json.dumps( info)|n};

  current_graph = new mstplot();

  $('div#graph').append(current_graph.svg);

  var doResize = function() {
    var graph = $('div#graph');
    var container = graph.closest('.container-fluid');
    var enclosing_div = graph.parent();
    var height = $(window).height()
      - container.offset().top
      - container.children("#graph-header").height()
      - container.children("#graph-footer").height()
      - 14;
    var width = graph.width();

    graph.height(height);

    current_graph.resize(width, height);
  };

  $(window).resize(doResize);
  doResize();

  current_graph.setData(nodes, edges, info, pos);
  current_graph.draw();

  $('#clear_all').on('click', function() {
    current_graph.selected_ids = {};
    current_graph.updateLabels();
  });

  var gene_entry = new GeneDropdown({ el: $("#gene") });
  gene_entry.setSearchURL("${request.route_url('mistic.json.dataset.search', dataset=ds.id)}");

  gene_entry.on('change', function(item) {
    if (item === null) return;
    current_graph.selected_ids[item.id] = true;
    current_graph.updateLabels();
  });

  var geneset_selector = new GenesetSelector({
    el: $("#geneset_selector"),
    dataset: "${ds.id}",
    url: "${request.route_url('mistic.json.annotation.gs', annotation=ds.annotation.id)}"
  });

  geneset_selector.on('GenesetSelector:change', function(item) {
      if (item === null) return;
      console.log('item', item);
      $.ajax({
        url: "${request.route_url('mistic.json.annotation.gene_ids', annotation=ds.annotation.id)}",
        data: { filter_gsid: item.id },
        dataype: 'json',
        success: function(data) {
          _.each(data, function(item) {
            current_graph.selected_ids[item] = true;
            current_graph.updateLabels();
          });
        },
        error: function() {
          // inform the user something went wrong.
        }
      });
  });
});
</script>
</%block>
