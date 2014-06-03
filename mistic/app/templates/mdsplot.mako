<%!
import mistic.app.data as data
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">MDS Plot</%block>
<%block name="style">
${parent.style()}

#controls {
  overflow-y: scroll;
  margin-top: 5px;
}

</%block>

<%block name="controls">
<div id="controls" class="span3">
  <div class="accordion-group">
    <div class="accordion-heading">
      <h4 class="accordion-title">
        <a class="accordion-toggle" data-toggle="collapse"  href="#sample_menu">Samples</a>
      </h4>
    </div>

    <div id="sample_menu" class="accordion-body collapse in ">
      <div class="accordion-inner">
        <h5>Highlight groups</h5>
        <div id="current_selection"></div>
        <br>
        <div class="btn-group">
          <button type="button" class="btn" id="new_group">New group</button>
          <button type="button" class="btn" id="clear_all">Clear all</button>
        </div>
        <hr>
        <div id="sample_characteristic">
          <div class="input-append">
            <input id="sample_annotation" type="text" style="text-overflow : ellipsis;" autocomplete="off" placeholder="Select a characteristic">
            <div class="btn-group">
              <button id="sample_annotation_drop" class="btn dropdown-toggle" data-toggle="dropdown">
                <span class="caret"></span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="accordion-group">
    <div class="accordion-heading">
      <h4 class="accordion-title">
        <a class="accordion-toggle" data-toggle="collapse"  href="#options_menu">Options</a>
      </h4>
    </div>

    <div id="options_menu" class="accordion-body collapse ">
      <div class="accordion-inner">
        <div class="btn-group">
          <button type="button" class="btn" id="show_labels">Show labels</button>
          <button type="button" class="btn" id="clear_labels">Clear labels</button>
        </div>
      </div>
    </div>
  </div>

  <div class="accordion-group">
    <div class="accordion-heading">
      <h4 class="accordion-title">
        <a class="accordion-toggle" data-toggle="collapse" href="#sample_enrichment_panel">Sample term enrichment</a>
      </h4>
    </div>
    
    <div id="sample_enrichment_panel" class="accordion-body collapse">
      <div class="accordion-inner">
        <div id="sample_enrichment"></div>
      </div>
    </div>
  </div>

</div>
</%block>

<%block name="info">
</%block>

<%block name="pagetail">
<%include file="mistic:app/templates/fragments/tmpl_point_group.mako"/>
${parent.pagetail()}

<script type="text/javascript">
<%
  ds = data.datasets.get(dataset)
%>

require([
    "jquery", "underscore", "d3",
    "math",
    "plotbase",
    "point_group", "point_group_view",
    "sample_annotation_dropdown",
    "domReady!"
], function(
    $, _, d3,
    math,
    plotbase,
    pg, pgv,
    sad,
    doc) {

    var sample_annotation_entry = new sad.SampleAnnotationDropdown({
        url: "${request.route_url('mistic.json.dataset.sampleinfo.search', dataset=dataset)}",
        el: $('#sample_annotation')
    });

    var group_colours = d3.scale.category20();
    var next_group = 0;

    $('#clear_all').on('click', function(event) { 
        pgc.reset();
        event.preventDefault();
    });

    $('#new_group').on('click', function(event) { 
        var g = new pg.PointGroup({
            style: { fill: group_colours(next_group % 20) }
        });
        pgc.add(g);
        ++next_group;
        event.preventDefault();
    });

    var current_graph = new plotbase.plotbase({
        title: "MDS plot (${ds.name})",
        inner: 5,
        outer: 10,
        axes: {
          x: { odp: [0,0], label: "Dimension 1" },
          y: { odp: [0,0], label: "Dimension 2" },
        }
    });

    $("#graph").append(current_graph.svg);

    var resizeGraph = function() {
        var h = $(window).height()-$("#graph").offset().top - 14;
        var w = $("#graph").width();
        $("#graph").height(h)
        $("#controls").height(h)
        current_graph.resize(w, h);
    };

    $(window).resize(resizeGraph);
    resizeGraph();

    var scatterplot_shim = function() {
    };

    var sample_ids = null;
    $.ajax({
        url: "${request.route_url('mistic.json.dataset.samples', dataset=dataset)}",
        data: {},
        async: false,
        dataType: 'json',
        success: function(data) {
            sample_ids = data;
        }
    });

    scatterplot_shim.prototype.legendSymbol = function(node, pg) {
        var attrs = _.extend({}, plotbase.e_grouped_points.defaults, pg.get("style"));

        if (attrs.fill === null)      attrs.fill = "none";
        if (attrs.fill === undefined) attrs.fill = "#aaa";

        var g = node.append('g').classed('node', true);
        g.append('path').attr(attrs);
    };

    scatterplot_shim.prototype.clearBrush = function() {
        current_graph.clearBrush();
    };

    scatterplot_shim.prototype.setSelection = function(keys) {
        sel.setSelection(keys);
    };

    scatterplot_shim.prototype.getSelection = function() {
        return _.keys(sel.getSelection());
    };

    var shim = new scatterplot_shim();

    var pgc = new pg.PointGroupCollection();
    var pgc_view = new pgv.PointGroupListView({ groups: pgc, graph: shim, el: $("#current_selection") })

    var sel = new plotbase.selection();

    var pt = new plotbase.e_grouped_points(
      [],
      [],
      [],
      [],
      pgc
    );

    var mds_data = null;
    $.ajax({
        url: "${request.route_url('mistic.json.dataset.mds', dataset=dataset, xform=xform, N=N_genes)}",
        data: {},
        async: true,
        dataType: 'json',
        success: function(data) {
            pt.x = data[0];
            pt.y = data[1];
            pt.keys = sample_ids;
            current_graph.fitElems();
            current_graph.update();
        }
    });


    pt.setSelectionDelegate(sel);

    current_graph.addElem(pt);
    current_graph.fitElems();
    current_graph.update();

    current_graph.updatePlotArea();
    pt.reflectSelection([ 'id1', 'id3' ]);

    $('#sample_annotation_drop').on('click', function() {
        sample_annotation_entry.$el.val('');
        sample_annotation_entry.update();
        sample_annotation_entry.$el.focus();
        return false;
    });
    
    sample_annotation_entry.on("change", function(item) {
        if (item === null) return;
        var val = item.id.split('.');
        
        var l1 = _.initial(val).join('.');
        var l2 = val[val.length-1];
        var kv = {};
        kv[l1] = l2
        $.ajax({
            url:  "${request.route_url('mistic.json.dataset.samples', dataset=dataset)}",
            data: kv,
            datatype: 'json',
            success: function(data) {
                shim.setSelection(data);
            }
        });
    });

    var updateEnrichmentTable = function(data) {
        $('#sample_enrichment').html('');
        if (!data.length) return;
        var s = ['Number of selected points with annotations : '+eval(data[0].tab[0].join('+'))+'/'+($('.selected').length/$('.scatterplot').length)].join(' ');
        $('#sample_enrichment').html(s);
        
        var table = d3
            .select('#sample_enrichment')
            .insert('table', ':first-child');

        var thead = table.append('thead');
        var tbody = table.append('tbody');

        var thr = thead.selectAll("tr")
            .data([ 1 ])
            .enter()
            .append("tr")

        var th = thr.selectAll('th')
            .data([ 'P-val', 'Odds', 'Selected', 'Key : Value' ])
            .enter()
            .append('th')
            .text(function(d) { return d; });

        var tr = tbody.selectAll('tr')
            .data(data)

        tr.enter()
            .append('tr');

        var td = tr.selectAll('td')
            .data(function(d) { 
                var title = '\t\tIn Selection |  Not in Selection\nIn Category\t\t'+ d.tab[0][0]+' | '+d.tab[1][0]+'\nNot in Category\t'+d.tab[0][1]+' | '+d.tab[1][1];
                return [
                    { value: d.p_val.toExponential(1), title:title },
                    { value: typeof(d.odds) === "string" ? d.odds : d.odds.toFixed(1) , title:title },
                    { value: d.tab[0][0]+'/'+ (parseInt(d.tab[1][0])+ parseInt(d.tab[0][0])), title:title},
                    { value: d.key +' : '+d.val, title:title },
                    
                ];
            });

        td.enter()
            .append('td')
            .text(           function(d) { return d.value; })
            .attr('title',   function(d) { return d.title; })
            .attr('classed', function(d) { return d.class; });

        $('#sample_enrichment table')
            .dataTable({
                "aoColumnDefs": [
                    { "sType": "scientific", "aTargets": [ 0 ], 'aaSorting':["asc"] },
                    { "sType": "numeric", "aTargets": [ 1 ]}
                ],
                "bPaginate" : false,
                "iDisplayLength": 10,
                "sPaginationType": "full_numbers",
                "bLengthChange": false,
                "bFilter": false,
                "bSort": true,
                "bInfo": false
            });
    }

    var _selection = { active: false, pending: undefined };

    var selectionSearch = function(selection) {
        
        if (_selection.active) {
            _selection.pending = selection;
        } else {
            if (_.isUndefined(selection) || !selection.length) {
                updateEnrichmentTable([])
                return;
            }
            _selection.active = true;
            _selection.pending = undefined;
            $.ajax({
                url: "${request.route_url('mistic.json.dataset.samples.enrich', dataset=dataset)}",
                dataType: 'json',
                type: 'POST',
                data: { samples: JSON.stringify(selection) },
                error: function(req, status, error) {
                    console.log('got an error', status, error);
                },
                success: function(data) {
                    updateEnrichmentTable(data);
                },
                complete: function() {
                    _selection.active = false;
                    window.setTimeout(function() {
                        if (!_selection.active && _selection.pending !== undefined) selectionSearch(_selection.pending);
                    }, 0);
                }
            });
        }
    }

    sel.on('selection-changed', function(selection) {
        selectionSearch(_.keys(selection));
        $('#sample_enrichment_panel').collapse('show');
    });
});
</script>
</%block>
