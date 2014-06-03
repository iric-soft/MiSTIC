<%!
import mistic.app.data as data
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">MDS Plot</%block>
<%block name="style">
${parent.style()}

rect.bar.selected {
  fill: #cc7400;
}

rect.bar:hover {
  fill: #005799;
  cursor: pointer;
}

rect.bar.selected:hover {
  fill: #995700;
}

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
        <div id="dimension_barchart"></div>
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

    pt.setSelectionDelegate(sel);

    current_graph.addElem(pt);
    current_graph.update();

    var mds_data = null;
    var plot_dimensions = [ 0, 1 ];

    var select_dimensions = function(dim1, dim2) {
        plot_dimensions = [ dim1, dim2 ];

        pt.x = mds_data.dimensions[dim1];
        pt.y = mds_data.dimensions[dim2];
        pt.keys = sample_ids;

        current_graph.config.axes.x.label = 'Dimension ' + (dim1+1);
        current_graph.config.axes.y.label = 'Dimension ' + (dim2+1);

        current_graph.fitElems();
        current_graph.update();

        var svg = d3.select("#dimension_barchart")
            .selectAll('.bar')
            .classed('selected', function(d, i) { return i == dim1 || i == dim2; });
    };

    var dimension_barchart = function() {
        if (mds_data === null) return;

        var ht = mds_data.eigenvalues;
        ht = ht.slice(0, 20);
        console.log(ht);
        var margin = { top: 30, right: 10, bottom: 30, left: 16 };
        var width = 300;
        var height = 100;

        var x = d3.scale.ordinal()
            .domain(d3.range(1,ht.length+1))
            .rangeRoundBands([0, width], .1);
        var y = d3.scale.linear()
            .domain([0, d3.max(ht) ])
            .range([height, 0]);

        var xAxis = d3.svg.axis().scale(x).orient("bottom").innerTickSize(2).outerTickSize(0);
        var yAxis = d3.svg.axis().scale(y).orient("left").ticks(5).innerTickSize(2).outerTickSize(0);

        var svg = d3.select("#dimension_barchart")
            .append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)

        svg.append('text')
            .attr('x', width/2 + margin.left)
            .attr('y', 26)
            .attr('text-anchor', 'middle')
            .attr({ 'style': 'font: 12px helvetica; font-weight: 400;' })
            .text('Dimension eigenvalues');

        svg = svg.append("g")
            .attr("transform", "translate(" + [margin.left, margin.top] + ")");

        svg.append("g")
            .attr("class", "axis-x axis")
            .attr("transform", "translate(0," + height + ")")
            .call(xAxis);
        svg.append("g").attr("class", "axis-y axis").call(yAxis);

        svg.selectAll('.axis text').attr({ 'style': 'font: 10px helvetica; font-weight: 100' });
        svg.selectAll('.axis-x text').attr({ 'text-anchor': 'end', 'dy': '-2px', 'transform': 'translate(0,7)rotate(-90)' });
        svg.selectAll('.axis-y text').attr({ 'text-anchor': 'end', 'dy': '4px' });
        svg.selectAll('.axis path, .axis line').attr({ 'fill': 'none', 'stroke': '#aaa', 'shape-rendering': 'crispEdges' });

        svg.selectAll(".bar")
            .data(ht)
          .enter()
            .append("rect").classed('bar', true)
            .attr('fill', '#0074cc')
            .attr("x", function(d, i) { return x(i+1); })
            .attr("y", function(d, i) { return y(d); })
            .attr("width", x.rangeBand())
            .attr("height", function(d) { return height - y(d); })
            .on("click", function(d, i) {
                if (d3.event.shiftKey) {
                    if (i < plot_dimensions[0]) {
                        select_dimensions(i, plot_dimensions[1]);
                    } else if (i > plot_dimensions[0] || i != plot_dimensions[1]) {
                        select_dimensions(plot_dimensions[0], i);
                    }
                } else {
                    select_dimensions(i, i+1);
                }
            });
    };

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

    $.ajax({
        url: "${request.route_url('mistic.json.dataset.mds', dataset=dataset, xform=xform, N=N_genes)}",
        data: {},
        async: true,
        dataType: 'json',
        success: function(data) {
            mds_data = data;

            dimension_barchart();

            select_dimensions(0, 1);
        }
    });



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
