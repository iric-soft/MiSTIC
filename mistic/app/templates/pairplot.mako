<%! import mistic.app.data as data %>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Multi-way scatterplot</%block>



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
    <span id="genelist"></span>
    <label for="gene">Gene:</label>
    <input type="text" id="gene">
   
 
  
    <button class="btn" style="display:inline; float:right;" data-toggle="button" id="show_labels"> Toggle labels  </button> 
   </form>
  
</%block>


<%block name="pagetail">
${parent.pagetail()}


<script src="${request.static_url('mistic:app/static/js/lib/scatterplot.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/pairplot.js')}" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function() {
  (function() {
    var opts = {};
    updateURLTarget = function(params) {
      _.extend(opts, params);
      if (opts.dataset !== null) {
        var url = "${request.route_url('mistic.template.pairplot_static', dataset='_dataset_', genes=[])}"
          .replace('_dataset_', opts.dataset);
        _.each(current_graph.data, function(x) { url += '/' + x.gene; });
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

  current_graph = new pairplot(undefined, undefined, $('#graph'));

  current_dataset = undefined;

  var gene_entry = new GeneDropdown({ el: $("#gene") });

  $('body').on('click.remove', 'i.icon-remove-sign', function(event) {
    var badge = $(event.target).closest('span.badge');
    var badge_idx = parseInt(badge.attr('data-idx'));
    current_graph.removeData(function(d, i) { return i === badge_idx; });
    badge.remove();
  });

  gene_entry.on('change', function(item) {
    if (item === null) return;

    $.ajax({
      url: "${request.route_url('mistic.json.gene.expr', dataset='_dataset_', gene_id='_gene_id_')}".replace('_dataset_', current_dataset).replace('_gene_id_', item.id),
      dataype: 'json',
      success: function(data) {
        var gene_list = $('#genelist');
        
        current_graph.addData(data);
        gene_entry.$el.val('');
        var label = $('<span>')
          .addClass('badge')
          .css({ 'margin': '0px 5px' })
          .attr({ 'data-idx': current_graph.data.length - 1 })
          .html(item.get('symbol') !== '' ? item.get('symbol') : item.id);
        label.append($('<i>')
          .addClass('icon-white icon-remove-sign')
          .css({ 'cursor': 'pointer', 'margin-right': -8, 'margin-left': 4 }));
        $('#genelist').append(label);
        updateURLTarget();
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
      gene_entry.url = null;
      $("#gene").attr('disabled', true);
    } else {
     $("#gene").attr('disabled', false);
      gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
    }
    gene_entry.$el.val('');

    $('#genelist').empty();
    current_graph.removeData(function() { return true; });
    updateURLTarget({ dataset: current_dataset });
  });

  $('#datasets').change();

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
  	return false;
  });
  
 
  

});
</script>
</%block>
