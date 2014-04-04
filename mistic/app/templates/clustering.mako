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
  
  <div class="accordion" id="accordion">
     <div class="accordion-group">     
       <div class="accordion-heading"><h4 class="accordion-title">
            <a class="accordion-toggle" data-toggle="collapse"  href="#dataset_menu">Dataset comparison</a></h4>
       </div>
       
       <div id="dataset_menu" class="accordion-body collapse in">
         <div class="accordion-inner">    
           
               <select id="dataset_cmp">
                    <option value="">Choose a dataset for comparison </option>
            %for d in data.datasets.all():
                    <option value="${d.id}">${d.name}</option>
            %endfor
            </select>
                 
              </div>
            </div>
          </div>
          
          
    <div class="accordion-group">     
       <div class="accordion-heading"><h4 class="accordion-title">
         <a class="accordion-toggle" data-toggle="collapse"  href="#locate_gene">Locate  </a></h4>
      </div>
  
   <div id="locate_gene" class="accordion-body collapse in">
       <div class="accordion-inner">  
    
    
    <label for="gene1"></label>
    <input type="text" id="gene">
  
    </div>
      </div>
    </div>
          
          
   <div class="accordion-group">     
       <div class="accordion-heading"><h4 class="accordion-title">
         <a class="accordion-toggle" data-toggle="collapse"  href="#go_colour">Geneset enrichment</a></h4>
      </div>
  
   <div id="go_colour" class="accordion-body collapse in">
       <div class="accordion-inner">  
           
            
            <div class="input-append btn-group"  style='margin-left:0px;'>
                <input type="text" id="level1" placeholder='Restrict geneset search to this type'>
                <a id='level1_drop' class="btn btn-default dropdown-toggle" data-toggle="dropdown" style='float:none;margin;0px; left:-4px;'> 
                <span class="caret"></span>
                </a>
            </div>
           <div class="input-append btn-group"  style='margin-left:0px;'>
                 <input type="text" id="level2" placeholder='Restrict geneset search to this category'>
                <a id='level2_drop' class="btn btn-default dropdown-toggle" data-toggle="dropdown" style='float:none;margin;0px; left:-4px;'> 
                <span class="caret"></span>
                </a>
            </div>
           
           <div class="input-append btn-group" style='margin-left:0px;'>
                <input type="text" id="level3" placeholder='Search for a geneset'>
                <a id='level3_drop' class="btn btn-default dropdown-toggle" data-toggle="dropdown" style='float:none;margin;0px; left:-4px;'> 
                <span class="caret"></span>
                </a>
            </div>
         
         
          <a id='clear_input' href="#" style='text-decoration:none;'>Clear all</a>
         
          
      </div>
      </div>
    </div>
  
  
  <div class="accordion-group">
       <div class="accordion-heading">
         <h4 class="accordion-title">
           <a class="accordion-toggle" data-toggle="collapse"  href="#options_menu">More options</a>
         </h4>
       </div>

      <div id="options_menu" class="accordion-body collapse ">
        <div class="accordion-inner">
           <ul id="options" class="nav nav-list">
            <li><a id='clear_plot' href="#">Clear plot</a></li>
          
            <li class="divider"></li>
            
            <div>
            <label for="odds">Set odds ratio: </label>          
            <input id="odds" value='2' size=3 disabled type='text' style='width:10px;height:10px'></input>
           </div>
          </ul>
        </div>
      </div>
     </div>
   </div>
  
    
  </form>

</%block>
<%block name="style">
${parent.style()}



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
  ds = data.datasets.get(dataset)
  my_annotation = ds.annotation.id
  #print dir(ds.annotation)
  #print [(k,v.description) for k,v in ds.annotation.genesets.items()]
  #print ds.annotation.genesets['CNV']
  
  if xform == 'log': 
    xf = 'log%(base)s(%(scale)s * RPKM + %(biais)s)' % dict(zip(['scale','biais','base'],ds._makeTransform(xform).params))
  else : 
    xf = xform 

 

%>

  resizeGraph = function() {
    current_graph.elem.height($(window).height()-100);
    current_graph.resize();
  };
  

  var nodes = ${json.dumps(nodes)|n};
  var edges = ${json.dumps(edges)|n};

  cluster_roots = Node.fromMST(nodes, edges);

  current_graph = new arcplot($('#graph'), {
    cluster_minsize: ${int(ds.config.get('icicle.cluster_minsize', '5'))}
  });

  current_graph.setData(cluster_roots);
  current_graph.setGraphInfo(["Dataset: ${dataset}", 
                              "Transform: ${xf}"]); 
 

  var gene_entry = new GeneDropdown({ el: $("#gene") });
  gene_entry.setSearchURL("${request.route_url('mistic.json.dataset.search', dataset=dataset)}");

  var go_entry = new GODropdown({
    el: $("#goterm"),
    url: "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"
  });
  
  
  var level1_entry = new GODropdown({
    el: $("#level1"),
    url: "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=1"
  });
  
  var level2_entry = new GODropdown({
    el: $("#level2"),
    url: "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=2"
  });
  
  var level3_entry = new GODropdown({
    el: $("#level3"),
    url: "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3"
  });
  
  $('#clear_input').on('click', function() {
    level1_entry.$el.val('');
    level2_entry.$el.val('');
    level3_entry.$el.val('');
    level2_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=2;";
    level3_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3;";
  });
  
  
  $('#level1_drop').on('click', function() {
    level1_entry.$el.val('');
    level1_entry.update();
    level1_entry.$el.focus();
  });
  
  level1_entry.on('change', function() {
    level2_entry.$el.val('');
    level3_entry.$el.val('');
    gstype = $("#level1").val().split(':')[0];
    level2_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=2;q="+gstype;
    level3_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3;q="+gstype;
  });
  
   level2_entry.on('change', function() {
    level3_entry.$el.val('');
    gsid = $("#level2").val();
    level3_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3;q="+gsid;
  });
  
  
  
   $('#level2_drop').on('click', function() {
    level2_entry.$el.val('');
    level2_entry.update();
    level2_entry.$el.focus();
  });
  
   $('#level3_drop').on('click', function() { 
    level3_entry.$el.val('');
    level3_entry.update();
    level3_entry.$el.focus();
  });
  
  
  level3_entry.on('change', function(item) {
    if (item === null) {
      current_graph.removeColour();
    } else {
      $.ajax({
        url: "${request.route_url('mistic.json.annotation.gene_ids', annotation=my_annotation)}",
        data: { filter_gsid: item.id },
        dataype: 'json',
        success: function(data) {
          $("#dataset_cmp").val($("#dataset_cmp option:first").val());
          var gene_set = {};
          for (var i = 0; i < data.length; ++i) { gene_set[data[i]] = true; }
                              console.log(JSON.stringify(gene_set));
          current_graph.colourByClusterMatch(
            [ gene_set, current_graph.root.getContent() ],
            function (a,b,c,d) {
               return fisher.exact_nc_w (a, b, c, d);
            },
            function (a,b) {
              return a > b;
            },
            Red4);
            current_graph.dezoom();
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
          $('#goterm').val('');
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
            // function (a, b, c, d, cur_max) {
            //   return fisher.exact_w (a, b, c, d, cur_max);
            // },
            function (a, b, c, d, ignored) {
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

  
 
  gene_entry.on('change', function(item) {
   
    if (item !== null) {
      current_graph.zoomTo(item.id);
    } else {
      current_graph.zoomTo(null);
    }
    return false;
    event.preventDefault();
  });

  current_graph.on('click:cluster', function(selection) {
    $('#geneset').val(JSON.stringify(selection));
    $('#genesetform').submit();
  });

  $('#clear_plot').on("click", function(event){
    current_graph.removeColour();
    current_graph.zoomTo(null);
    current_graph.dezoom();
    $('#gene').val('');
    $('#goterm').val('');
    
  });


  $(window).resize(resizeGraph);
  resizeGraph();  
});
</script>
</%block>
