<%!
import json
import mistic.app.data as data
import pickle
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">MST Clustering</%block>
<%block name="actions">
  ${parent.actions()}
</%block>
<%block name="controls">
  <form class="form-inline">
    <label for="datasets">Dataset colour:</label>
    <select id="dataset_cmp">
      <option value="">None</option>
%for d in data.datasets.all():
      <option value="${d.id}">${d.name}</option>
%endfor
    </select>
    <label for="goterm">GO colour:</label> <input type="text" id="goterm"></input></label>
    <label for="gene1">Locate:</label>
    <input type="text" id="gene">
    <button class="btn btn-primary" id="bp_go">BP</button>
    <button class="btn btn-primary" id="mf_go">MF</button>
    <button class="btn btn-primary" id="cc_go">CC</button>
  </form>
</%block>
<%block name="style">
${parent.style()}

path.arc:hover {
  fill: #346;
}

path.arc.highlight {
  fill: #f00;
}
path.axis.selected {
  stroke-width:3.5;
}


</%block>
<%block name="pagetail">
<form id="genesetform" target="_blank" method="post" action="${request.route_url('mistic.template.mstplot', dataset=dataset, xform=xform)}">
<input id="geneset" type="hidden" name="geneset" value=""></input>
</form>

${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/djset.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/node.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/arcplot.js')}" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function() {
<%
  my_annotation = data.datasets.get(dataset).annotation.id
%>
  var nodes = ${json.dumps(nodes)|n};
  var edges = ${json.dumps(edges)|n};

  cluster_roots = Node.fromMST(nodes, edges);

  current_graph = new arcplot();

  current_graph.setData(cluster_roots);

  current_graph.draw();

  var gene_entry = new GeneDropdown({ el: $("#gene") });
  gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset=dataset)}";

  var go_entry = new GODropdown({ el: $("#goterm") });

  go_entry.on('change', function(item) {
    if (item === null) {
      current_graph.removeColour();
    } else {
      $.ajax({
        url: "${request.route_url('mistic.json.annotation.gene_ids', annotation=my_annotation)}",
        data: { go: item.id },
        dataype: 'json',
        success: function(data) {
          var gene_set = {};
          for (var i = 0; i < data.length; ++i) { gene_set[data[i]] = true; }
                              console.log(JSON.stringify(gene_set));
          current_graph.colourByClusterMatch(
            [ gene_set, current_graph.root.getContent() ],
            function (a,b,c,d) {
              return Math.max(0.0, stats.kappa(a, b, c, d));
            },
            function (a,b) {
              return a > b;
            },
            Red4);
        },
        error: function() {
          // inform the user something went wrong.
        }
      });
    }
  });

  $('#dataset_cmp').on('change', function(event) {
    var val = $('#dataset_cmp').val();
    if (val == '') {
      current_graph.removeColour();
    } else {
      $.ajax({
        url: "${request.route_url('mistic.json.dataset.mapped_mst', dataset='_dataset_', xform=xform, tgt_annotation=my_annotation)}".replace('_dataset_', val),
        dataype: 'json',
        success: function(data) {
          var node_content = [];
          _.each(Node.fromMST(data[0], data[1]), function(root) {
            var new_root = root.collapse(current_graph.options.cluster_minsize);
            new_root.collapseUnbranched();
            var n, p;
            for (p = new PostorderTraversal(new_root); (n = p.next()) !== null; ) {
              node_content.push(n.getContent());
            }
          });

          current_graph.colourByClusterMatch(
            node_content,
            function (a,b,c,d) {
              return Math.max(0.0, stats.kappa(a, b, c, d));
            },
            function (a,b) {
              return a > b;
            },
            YlGnBl);
        },
        error: function() {
        }
      });
    }
  });

  var go_colour = function(go_ns) {
    var req = $.ajax({
      url: "${request.route_url('mistic.json.annotation.genes', annotation=my_annotation)}",
      data: { go_ns: go_ns },
      dataype: 'json',
      success: function(data) {
        var go_term_genes = {};
        for (var i = 0; i < data.length; ++i) {
          var d = data[i];
          for (var j = 0; j < d.go.length; ++j) {
            if (!_.has(go_term_genes, d.go[j])) { go_term_genes[d.go[j]] = {}; }
            go_term_genes[d.go[j]][d.id] = true;
          }
        }
        var go_ids = _.keys(go_term_genes);
        var go_clusters = new Array(go_ids.length);
        var go_info = new Array(go_ids.length);
        for (var i = 0; i < go_ids.length; ++i) {
          go_clusters[i] = go_term_genes[go_ids[i]];
          go_info[i] = { id: go_ids[i] };
        }

        go_clusters.push(current_graph.root.getContent());
        current_graph.colourByClusterNumber(
                            go_clusters,
                            function (a,b,c,d) {
                              if (a < 2 || b < 0 || c < 0 || d < 1) return undefined;
                              return stats.chi2_yates(a, b, c, d);
                            },
                            function (a,b) {
                              return a > b;
                            },
                            go_info);
        current_graph.goLabels();
        $('#all_go').button('compute...');
      },
      error: function() {
        // inform the user something went wrong.
      }
    });
    return req;
  };

  $('#bp_go').click(function (event) {
  	if ($('#bp_go').hasClass("clicked")) {
  		$('#bp_go').removeClass("clicked")
  	}
  	else {
    	$('#bp_go').button('loading');
    	go_colour('biological_process').done(function() { $('#bp_go').button('reset'); });
    	event.preventDefault();
    	$('#bp_go').addClass("clicked")
    }
  });
  $('#mf_go').click(function (event) {
   	if ($('#mf_go').hasClass("clicked")) {
  		$('#mf_go').removeClass("clicked")
  	}
  	else { 
    	$('#mf_go').button('loading');
    	go_colour('molecular_function').done(function() { $('#mf_go').button('reset'); });
    	event.preventDefault();
    	$('#mf_go').addClass("clicked")
    }
    
  });
  $('#cc_go').click(function (event) {
  	if ($('#cc_go').hasClass("clicked")) {
  		$('#cc_go').removeClass("clicked")
  	}
  	else {
    	$('#cc_go').button('loading');
    	go_colour('cellular_component').done(function() { $('#cc_go').button('reset'); });
    	event.preventDefault();
    	$('#cc_go').addClass("clicked")
    }
  });
  
  
 
  gene_entry.on('change', function(item) {
    console.log (item.id);
    if (item !== null) {
      current_graph.zoomTo(item.id);
    } else {
      current_graph.zoomTo(null);
    }
    return false;
  });

  current_graph.on('click:cluster', function(selection) {
    $('#geneset').val(JSON.stringify(selection));
    $('#genesetform').submit();
  });

  $('div#graph').append(current_graph.svg);
});
</script>
</%block>
