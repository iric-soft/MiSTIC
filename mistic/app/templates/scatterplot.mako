<%! import mistic.app.data as data %>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Pairwise scatterplot</%block>




<%block name="actions">
  ${parent.actions()}<button class="btn" id="static_url" href="">Static URL</button>
</%block>
<%block name="controls">
  <form class="form-inline">
    <label for="datasets">Dataset:</label>
    <select id="datasets">
      <option value="">Select a dataset</option>
%for d in data.datasets.all():
      <option value="${d.id}">${d.name}</option>
%endfor
    </select>
    <label for="gene1">Gene 1:</label>
    <input type="text" id="gene1">
    <label for="gene2">Gene 2:</label>
    <input type="text" id="gene2">
    <button class="btn" data-toggle="button" id="show_labels"> Toggle labels </button>
  </form>
  
  
     
</%block>




<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/scatterplot.js')}" type="text/javascript"></script>
<script type="text/javascript">
$(document).ready(function() {
  (function() {
    var opts = {};
    updateURLTarget = function(params) {
      _.extend(opts, params);
      if (opts.dataset !== null &&
          opts.gene1 !== null &&
          opts.gene2 !== null) {
        var url = "${request.route_url('mistic.template.scatterplot_static', dataset='_dataset_', gene1='_gene1_', gene2='_gene2_')}"
          .replace('_dataset_', opts.dataset)
          .replace('_gene1_', opts.gene1)
          .replace('_gene2_', opts.gene2);
        $('#static_url')
          .attr('disabled', false)
          .on('click.static_url', function() {
          window.location.href = url;
        });
      } else {
        $('#static_url')
          .attr('disabled', true)
          .off('click.static_url');
      }
    };
  })();

  
 
  
  current_graph = new scatterplot();

  resizeGraph = function() {
    $('div#graph').height($(window).height() - 124);

    current_graph.resize(
      $('div#graph').width(),
      $('div#graph').height());
  };

  current_dataset = null;
  current_gene1 = null;
  current_gene2 = null;

  var gene1_entry = new GeneDropdown({ el: $("#gene1") });
  var gene2_entry = new GeneDropdown({ el: $("#gene2") });
	

  gene1_entry.on('change', function(item) {
    current_gene1 = item;
    console.log(current_gene1.attributes);
    gene1_entry.$el.toggleClass('valid', item !== null);

    if (current_gene1 === null) { current_graph.setXData(undefined); return; }
    $.ajax({
      url: "${request.route_url('mistic.json.gene.expr', dataset='_dataset_', gene_id='_gene_id_')}".replace('_dataset_', current_dataset).replace('_gene_id_', current_gene1.id),
      dataype: 'json',
      success: function(data) {
        current_graph.setXData(data);
        updateURLTarget({ gene1: current_gene1.id });
      },
      error: function() {
        // inform the user something went wrong.
      }
    });
  });

  gene2_entry.on('change', function(item) {
    current_gene2 = item;
    console.log(current_gene2.attributes);
    gene2_entry.$el.toggleClass('valid', item !== null);

    if (current_gene2 === null) { current_graph.setYData(undefined); return; }
    $.ajax({
      url: "${request.route_url('mistic.json.gene.expr', dataset='_dataset_', gene_id='_gene_id_')}".replace('_dataset_', current_dataset).replace('_gene_id_', current_gene2.id),
      dataype: 'json',
      success: function(data) {
        current_graph.setYData(data);
        updateURLTarget({ gene2: current_gene2.id });
      },
      error: function() {
        // inform the user something went wrong.
      }
    });
  });

  $('#datasets').on('change', function(event) {
    current_dataset = event.target.value;
    if (current_dataset === '') {
      
      current_dataset = null;
      gene1_entry.url =
      gene2_entry.url = null;
      $("#gene1").attr('disabled', true);
      $("#gene2").attr('disabled', true);
     
    } else {
      
      $("#gene1").attr('disabled', false);
      $("#gene2").attr('disabled', false);
      gene1_entry.url =
      gene2_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
    }
    gene1_entry.$el.val('');
    gene2_entry.$el.val('');
    updateURLTarget({ dataset: current_dataset });
  });

  $('#datasets').change();

  $('div#graph').append(current_graph.svg);

  $(window).resize(resizeGraph);
  resizeGraph();
  
  $('#show_labels').on("click", function(event){
  	d3.selectAll("text.circlelabel").classed('invisible', !d3.selectAll("text.circlelabel").classed('invisible'));
  	return false;
  });
  
    
});
</script>
</%block>
