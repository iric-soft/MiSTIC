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
         <a class="accordion-toggle" data-toggle="collapse"  href="#gs_dropdown">Geneset enrichment</a></h4>
       </div>

       <div id="gs_dropdown" class="accordion-body collapse in">
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
       <div class="accordion-heading"><h4 class="accordion-title">
         <a class="accordion-toggle" data-toggle="collapse"  href="#extract_peak">Extract peaks </a></h4>
       </div>

       <div id="extract_peak" class="accordion-body collapse">
          <div class="accordion-inner">
              <form class="form-horizontal">
                  <div class="control-group">
                      <label class="control-label" for="inputEmail">Number of genes in a peak:</label>
                      <div class="controls">
                          Min: <input class="input-mini" type="text" id="min_elt" value="5">
                          Max: <input class="input-mini" type="text" id="max_elt" value="200">
                      </div>
                  </div>
                  <div class="control-group">
                      <label class="control-label" for="inputEmail">Height of a peak: </label>
                      <div class="controls">
                          Min: <input class="input-mini" type="text" id="min_h" value="0">
                          Max: <input class="input-mini" type="text" id="max_h" value="1">
                          <button class="btn" type="button" id="extract_view_btn">View</button>
                          <button class="btn" type="button" id="extract_save_btn">Save</button>
                      </div>
                  </div>
              </form>
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
              <label for="filter_genes">Minimum genes to start a peak: </label>
              <input class="input-mini" id="filter_genes" value='5' type='text' style='width:30px;height:17px'></input>
              <button class="btn" type="button" id="reload_btn">Reload</button>
            </div>
            <li class="divider"></li>

            <div>
              <label for="odds">Set odds ratio: </label>
              <input id="odds" value='2' size=3 disabled type='text' style='width:10px;height:17px'></input>
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

  var current_graph;

  if (nodes.length < 25000) {
    $("#filter_genes").val(5);
    current_graph = new arcplot($('#graph'), {
      cluster_minsize: ${int(ds.config.get('icicle.cluster_minsize', 5))}
    });
  } else {
    if (nodes.length > 100000) {
      $("#filter_genes").val(15);
      current_graph = new arcplot($('#graph'), {
        cluster_minsize: ${int(ds.config.get('icicle.cluster_minsize', 15))}
      });
    } else {
      $("#filter_genes").val(10);
      current_graph = new arcplot($('#graph'), {
        cluster_minsize: ${int(ds.config.get('icicle.cluster_minsize', 10))}
      });
    }
  }


  current_graph.setData(cluster_roots);
  current_graph.setGraphInfo(["Minimum genes to create a peak: ".concat($("#filter_genes").val()), "Dataset: ${dataset}",  "Transform: ${xf}"]);

  var gene_entry = new GeneDropdown({ el: $("#gene") });

  //url = "${request.route_url('mistic.json.dataset.search', dataset=dataset)}".replace('${request.host}', mistic.url);
  //gene_entry.setSearchURL(url);

  gene_entry.setSearchURL("${request.route_url('mistic.json.dataset.search', dataset=dataset)}");

  newGSDropdown = function (elem, suff) {
    return  new GODropdown({
        el: $("#"+elem),
        url: "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+ suff
     });
  }

  clickGSDropdown = function (elem, entry) {
     $("#"+elem+"_drop").on('click', function() {

        if (level1_entry.$el.val()=='' & level2_entry.$el.val()==''){
            level2_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=2;";
            level3_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3;";
        }
        entry.$el.val('');
        entry.update();
        entry.$el.focus();
    });
  }

  var level1_entry = newGSDropdown ('level1', '?v=1');
  var level2_entry = newGSDropdown ('level2', '?v=2');
  var level3_entry = newGSDropdown ('level3', '?v=3');

  clickGSDropdown ('level1', level1_entry);
  clickGSDropdown ('level2', level2_entry);
  clickGSDropdown ('level3', level3_entry);

  $('#clear_input').on('click', function() {
    level1_entry.$el.val('');
    level2_entry.$el.val('');
    level3_entry.$el.val('');
    level2_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=2;";
    level3_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3;";
  });

  level1_entry.on('change', function() {
    level2_entry.$el.val('');
    level3_entry.$el.val('');
    gstype = $("#level1").val().split(':')[0];
    level2_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=2;q=ty:"+gstype;
    level3_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3;q=ty:"+gstype;
  });

   level2_entry.on('change', function() {
    level3_entry.$el.val('');
    gsid = $("#level2").val();
    level3_entry.url = "${request.route_url('mistic.json.annotation.gs', annotation=my_annotation)}"+"?v=3;q=id:"+gsid;
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
          current_graph.colourByClusterMatch(
            [ gene_set, current_graph.root.getContent() ],
            function (a,b,c,d) {
               return fisher.exact_nc_w (a, b, c, d);
            },
            function (a,b) {
              return a > b;
            },
            Red4, 'Fisher exact weight');
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
            YlGnBl, 'Kappa coefficient');

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
                            go_info, 'Chi2 yates');
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
      exit_var = current_graph.zoomTo(item.id);
      console.debug(exit_var);
      if (exit_var == -1 ) {
            s = '<p><div class="alert alert-error"><button type="button" class="close" data-dismiss="alert">&times;</button>';
            s = s + '<strong>Warning!</strong> '+item.id+'is not found in any cluster.</div>'
            $("#locate_gene > .accordion-inner").append(s);

      }

    } else {
      current_graph.zoomTo(null);
    }
    return false;
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

  var getParmExtract = function() {
      return {
          w: $("#min_elt").val(),
          W: $("#max_elt").val(),
          h: $("#min_h").val(),
          H: $("#max_h").val()
      };
  };

  $('#extract_view_btn').click(function(event){
      var parm = getParmExtract();

      $.ajax({
          url: "${request.route_url('mistic.json.dataset.extract', dataset=dataset, xform=xform)}",
          data: parm,
          dataype: 'json',
          success: function(data) {
              dic_gene = [];
              for (var i = 0; i < data.peaks.length; ++i) {
                  var d = data.peaks[i];
                  var gene_ids = d.split(";");
                  gene_ids.pop(); //delete last empty element
                  for (var j = 0; j < gene_ids.length; ++j) {
                      dic_gene[gene_ids[j]] = true;
                  }
              }
              current_graph.colourByFullyCoveredCluster(
                dic_gene,
                'Exact peaks'
              );
              },
          error: function() {
            // inform the user something went wrong.
          }
     });
  });

  $('#extract_save_btn').click(function(event){
      var param = "?"
      param = param.concat("w=".concat($("#min_elt").val()));
      param = param.concat("&W=".concat($("#max_elt").val()));
      param = param.concat("&h=".concat($("#min_h").val()));
      param = param.concat("&H=".concat($("#max_h").val()));
      var url = "${request.route_url('mistic.json.dataset.extractSave', dataset=dataset, xform=xform)}";
      url = url.concat(param);
      window.open(url)

  });

  $('#reload_btn').click(function(event){
      console.log("Start Reload")
      current_graph.setClusterMinSize($("#filter_genes").val());
      current_graph.setGraphInfo(["Minimum genes to create a peak: ".concat($("#filter_genes").val()), "Dataset: ${dataset}",  "Transform: ${xf}"]);
      current_graph.setData(cluster_roots);
      current_graph.draw();
      resizeGraph();
      console.log("End Reload")
  });


  $(window).resize(resizeGraph);
  resizeGraph();
});
</script>
</%block>
