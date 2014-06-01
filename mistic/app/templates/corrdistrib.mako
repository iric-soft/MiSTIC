<%!
import mistic.app.data as data
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Plot test</%block>
<%block name="style">
${parent.style()}

#info {
  background-color: white;
  border: 1px solid #aaa;
  margin-top: 5px;
  padding: 10px;
}

#info table {
  width: 100%;
}

#info table td {
  padding: 2px 2em;
}
</%block>

<%block name="controls">
  <div id="info"></div>
</%block>

<%block name="pagetail">
${parent.pagetail()}

<script type="text/javascript">
require([
    "jquery", "underscore", "d3",
    "math",
    "plotbase",
    "domReady!"
], function(
    $, _, d3,
    math,
    plotbase,
    doc) {

    var current_graph = new plotbase.plotbase({
        title: "Random correlation distribution",
        inner: 5,
        outer: 10,
        axes: {
          x: { odp: [0,0], label: "correlation" },
          y: { odp: [0,0], label: "density" },
        }
    });
    $("#graph").append(current_graph.svg);

    var resizeGraph = function() {
        var h = $(window).height()-$("#graph").offset().top - 14;
        var w = $("#graph").width();
        $("#graph").height(h)
        current_graph.resize(w, h);
    };

    $(window).resize(resizeGraph);
    resizeGraph();

    $.ajax({
        url: "${request.route_url('mistic.json.dataset.randomcorr', dataset = dataset, xform = xform, N = 10000)}",
        dataType: 'json',
        success: function(data) {
            var density = math.smooth.kde(data.corr, -1.0, +1.0, 100, math.pdf.gauss(0.0, 0.02));
            current_graph.addElem(new plotbase.e_smoothline(density.x, density.y));

            var density = math.smooth.kde(data.permuted, -1.0, +1.0, 100, math.pdf.gauss(0.0, 0.02));
            current_graph.addElem(new plotbase.e_smoothline(density.x, density.y, { stroke: 'blue' }));

            var density = math.smooth.kde(data.gauss, -1.0, +1.0, 100, math.pdf.gauss(0.0, 0.02));
            current_graph.addElem(new plotbase.e_smoothline(density.x, density.y, { stroke: 'green' }));

            current_graph.fitElems();
            current_graph.update();
            var table_data = [
                [ '<b>Sample count:</b>', '<code>'+data.n_samples+'</code>' ],
                [ '&nbsp;',               '', ],
                [ '<b>Observed:</b>',     '', ],
                [ '5th percentile:',      '<code>'+d3.format('+.2f')(data.r_pc._05)+'</code>' ],
                [ 'Median:',              '<code>'+d3.format('+.2f')(data.r_pc._50)+'</code>' ],
                [ '95th percentile:',     '<code>'+d3.format('+.2f')(data.r_pc._95)+'</code>' ],
                [ '&nbsp;',               '', ],
                [ '<b>Permuted:</b>',     '', ],
                [ '5th percentile:',      '<code>'+d3.format('+.2f')(data.rperm_pc._05)+'</code>' ],
                [ 'Median:',              '<code>'+d3.format('+.2f')(data.rperm_pc._50)+'</code>' ],
                [ '95th percentile:',     '<code>'+d3.format('+.2f')(data.rperm_pc._95)+'</code>' ],
            ];


            var table = d3.select('#info')
                .append('table');

            var tbody = table.append('tbody');

            var tr = tbody.selectAll('tr').data(table_data);

            tr.enter().append('tr')

            var td = tr.selectAll('td').data(function(d) { return d; })

            td.enter().append('td').html(function(d) { return d; });
        ;

        },
        error: function() {
            // inform the user something went wrong.
        }
    });
});
</script>
</%block>
