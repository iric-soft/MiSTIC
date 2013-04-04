<%!
import mistic.app.data as data
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Correlation waterfall plot</%block>
<%block name="style">
${parent.style()}
</%block>
<%block name="actions">
  <button class="btn" id="download">CSV</button>
  <button class="btn" id="download-all">CSV [all]</button>${parent.actions()}
  <button class="btn" id="static_url">Static URL</button>
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
    <label for="gene">Gene:</label> <input type="text" id="gene"></input></label>
    <label for="nlabel"># labels:</label> <input type="text" style="width:20px;" id="nlabel"  autocomplete='off' value=10></input></label>
    <button class="btn" id="plot">Plot</button>
    <label for="goterm">GO Term:</label> <input type="text" autocomplete='off' id="goterm"></input></label>
  </form>
</%block>

<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/corrgraph.js')}" type="text/javascript"></script>
<script type="text/javascript">
$(document).ready(function() {
  (function() {
    var opts = {};
    var url_button = function(btn, url) {
      if (url === null) {
        btn
          .attr('disabled', true)
          .off('click.url');
      } else {
        btn
          .attr('disabled', false)
          .on('click.url', function() { window.location.href = url; });
      }
    };

    updateURLTarget = function(params) {
      var url;
      _.extend(opts, params);
      if (opts.dataset !== null && opts.gene !== null) {
        url = "${request.route_url('mistic.csv.corr', dataset = '_dataset_', gene = '_gene_')}"
          .replace('_dataset_', opts.dataset)
          .replace('_gene_', opts.gene);
        url_button($('#download'), url);
        
        url = "${request.route_url('mistic.csv.corrds',  dataset = '_dataset_', gene = '_gene_')}"
          .replace('_dataset_', opts.dataset)
          .replace('_gene_', opts.gene);
        url_button($('#download-all'), url);
        
        url = "${request.route_url('mistic.template.corrgraph_static', dataset = '_dataset_', gene = '_gene_')}"
          .replace('_dataset_', opts.dataset)
          .replace('_gene_', opts.gene);
        if (opts.go !== undefined) {
          url += '?go=' + opts.go;
        }
        url_button($('#static_url'), url);
      } else {
        url_button($('#download'), null);
        url_button($('#download-all'), null);
        url_button($('#static_url'), null);
      }
    };
  })();

  var dataset_annotation = ${json.dumps(dict([ (ds.id, ds.annotation.id) for ds in data.datasets.all() ]))|n};
  
  var current_dataset = null;
  var current_gene = null;
  var current_go_term = null;
  var current_graph = new corrgraph([], $('#graph'));
  
  resizeGraph = function() {
    current_graph.elem.height($(window).height() - 124);
    current_graph.resize();
  };

  var gene_entry = new GeneDropdown({ el: $("#gene") });
  
  
  gene_entry.on('change', function(item) {
    current_gene = item;
    gene_entry.$el.toggleClass('valid', item !== null);
    $('#plot').toggleClass('btn-primary', item !== null);
    $('#plot').attr('disabled', item === null);
  });

  var go_entry = new GODropdown({ el: $("#goterm") });

  go_entry.on('change', function(item) {
    current_go_term = item;
    go_entry.$el.toggleClass('valid', item !== null);
    updateURLTarget({ go: item === null ? undefined : item.id });

    if (item === null) {
      current_graph.markGenes(undefined);
    } else {
      $.ajax({
        url: "${request.route_url('mistic.json.annotation.gene_ids', annotation='_annotation_')}".replace('_annotation_', dataset_annotation[current_dataset]),
        data: { go: current_go_term.id },
        dataype: 'json',
        success: function(data) {
          current_graph.markGenes(data);
        },
        error: function() {
          // inform the user something went wrong.
        }
      });
    }
  });

  $('#datasets').on('change', function(event) {
    current_dataset = event.target.value;
    if (current_dataset === '') {
      current_dataset = null;
      gene_entry.url = null;
      $("#gene").attr("disabled", true);
      $("#goterm").attr("disabled", true);
      
    } 
    else {
      $("#gene").attr("disabled", false);
      $("#goterm").attr("disabled", false);
      gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
    }
    gene_entry.$el.val('');
  });

  $('#plot').click(function (event) {
    //console.log('plot');
    if (current_dataset !== null && current_gene !== null) {
      $('#plot').button('loading');
      
      var dataset_expt = ${json.dumps(dict([ (ds.id, ds.experiment) for ds in data.datasets.all() ]))|n};
      var expt = dataset_expt[current_dataset]
      var xform  = 'none'
      if (expt=='ngs') {xform='log'}
      
      var req = $.ajax({
        url: mistic.url + '/datasets/' + current_dataset + '/genes/' + current_gene.id + '/corr',
        data: {x: xform},
        dataype: 'json',
        
        success: function(data) {
          var nlabel = $("#nlabel").val();
          current_graph.annotation = current_dataset.genes;
          console.log('annotation: ' +current_graph.annotation);
          current_graph.setLabelNb(nlabel);
          if (expt=='hts' || expt=='ngs,hts') { current_graph.setDescAsLabel (true); }
          
          current_graph.setData(data.data);
          console.log(data.data);
          current_graph.draw();
          updateURLTarget({ dataset: current_dataset, gene: current_gene.id });
          console.log('end');
          
        },
        error: function() {
          // inform the user something went wrong.
        }
      });
      req.done(function() { $('#plot').button('reset'); });
    }
    event.preventDefault();
  });

  $('#datasets').change();
  gene_entry.trigger('cthange', null);
  updateURLTarget({ dataset: null });

  $(window).resize(resizeGraph);
  resizeGraph();
});
</script>
</%block>
