<%!
import json
import mistic.app.data as data
import scipy.stats
%>

<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">MST</%block>
<%block name="actions">
  ${parent.actions()}
</%block>

<%block name="pagecontent">

<div class="container-fluid">
  <div class="row-fluid">
    <div class="span12">
      <form class="form-inline">
        <div class="btn-group">
          <%block name="controls_buttons">
          <button class="btn" id="select_all">Select all</button>
          <button class="btn" id="clear_selection">Clear selection</button>
          <button class="btn" id="scatterplot">Scatterplot</button>
          <button class="btn" id="show_labels">Toggle labels</button>
        </div>
        <div class="btn-group">
          <button class="btn" id="dealWithLabels" data-toggle="button">Avoid overlapping labels</button>
        </div>
      </form>
    </div>
  </div>

  <div class="row-fluid" id="document-graph">
    <div class="span5" id="graph-right">
      <div id="go_table"></div>
      <div id="part2"></div>
    </div>
    <div class="span7" id="graph"></div>
  </div>
</div>
</%block>

<%block name="subcontent"></%block>

</%block>


<%block name="style">
${parent.style()}

#go_table {
  max-height: 400px;
  overflow-y: visible;
  overflow-x: auto;
  font-family: helvetica;
  font-size: 10.5px;
  padding-bottom:10px;
  border-bottom : 1px solid #ddd;
}

div#graph-right {
  overflow-y: auto;
}

div#more-information, .information{
   font-family: helvetica,arial,sans-serif;
   font-size: 11px;
   color: #cc7400;
   font-weight:bold;
   float: right;
}

div#more-information a  {
  text-decoration:none;
  color: grey;
}
div#more-information a:hover  {
  cursor : default;
}

th, td {
  white-space: nowrap;
  padding: 0px 5px;
  text-align: left;
}

tr {
  cursor: pointer;
}

rect {
  fill: #0074cc;
}
text {
 fill: #fff;
}

rect.selected {
  fill: #cc7400;
}
text.selected {
  fill: #fff;

}

</%block>

<%block name="pagetail">
${parent.pagetail()}

<%
  ds = data.datasets.get(dataset)
  a = ds.annotation

  E = [ dict(source=e[0][0], target=e[0][1], weight=e[1]) for e in edges ]
  V = [ dict(
    id    = n,
    name  = a.get_symbol(n, n),
    title = a.get_name(n, ''),
  ) for n in nodes ]
%>

<script type="text/javascript">
require([
    "jquery", "underscore", "backbone", "d3",
    "gene_dropdown", "geneset_selector",
    "node", "math", "colour", "utils",
    "mstplot", "domReady!",
], function(
    $, _, Backbone, d3,
    gene_dropdown, geneset_selector,
    node, math, colour, utils,
    mstplot, doc) {

    require(["dt_plugins"]);

    var json = {
        "nodes": ${json.dumps(V)|n},
        "links": ${json.dumps(E)|n},
        "gstab": {},
    };

    var updateEnrichmentTable = function() {

        $('#go_table').html('');

        var table = d3.select('#go_table')
            .insert('table', ':first-child')
            .attr('id', 'gotable');

        var thead = table.append('thead');
        var tbody = table.append('tbody');
        var tfoot = table.append('tfoot');

        var thr = thead.selectAll("tr")
            .data([ 1 ])
            .enter()
            .append("tr");

        var th = thr.selectAll('th')
            .data([ 'P-value', 'Odds',  'Type', 'Cat', 'ID', 'Name' ])
            .enter()
            .append('th')
            .text(function(d) { return d; });


        var thr = tfoot.selectAll("tr")
            .data([ 1 ])
            .enter()
            .append("tr");

        var th = thr.selectAll('th')
            .data([ 'P-value', 'Odds',  'Type', 'Cat', 'ID', 'Name' ])
            .enter()
            .append('th')
            .text(function(d) { return d; });


        var tr = tbody.selectAll('tr')
            .data(json.gstab);

        tr.enter()
            .append('tr')
            .on('click', function(d) {

                getAnnotationContent(d);
                var self = this;
                d3.selectAll('tr').classed('selected', function() { return this === self; });
                var sel = {}
                for (var i = 0; i < d.genes.length; ++i) {
                    sel[d.genes[i]] = true;
                }

                d3.select('#graph').selectAll('rect').classed('selected', function(d) { return sel[d.node.id]; });
                utils.info.clear();
                d3.select('#graph').selectAll('rect.selected').each(function(d) {
                    utils.info.toggle(d.node.name);
                });
            });

        var td = tr.selectAll('td')
            .data(function(d) { return [
                { value: (typeof(d.p_val) === 'string') ? d.p_val : d.p_val.toExponential(2) },
                { value: (typeof(d.odds)  === 'string') ? d.odds  : d.odds.toFixed(2) },
                { value: d.gs },
                { value: d.cat },
                { value: d.id },
                { value: d.name, title: d.desc },
            ];});

        td.enter()
            .append('td')
            .text(function(d) { return d.value; })
            .attr('title',   function(d) {return d.title; })
            .attr('classed', function(d) {return d.class; })
        ;
        $('#gotable').dataTable({ "aoColumnDefs": [{ "sType": "scientific", "aTargets": [ 0 ], 'aaSorting':["asc"] },
                                                   { "sType": "numeric", "aTargets": [ 1 ]},
                                                  ],

                                  "bPaginate" : true,
                                  "iDisplayLength": 10,
                                  "sPaginationType": "full_numbers",
                                  "bLengthChange": false,
                                  "bFilter": true,
                                  "bSort": true,

                                  "bInfo": true,

                                }).columnFilter({sPlaceHolder: "tfoot",
                                                 aoColumns:[null,null, {type:'text', bRegex:true},{type:'text', bRegex:true},{type:'text', bRegex:true},{type:'text', bRegex:true}]});


        console.debug('w');
    }



    var width =($(document).width()-60)/12*7; //was width:1024
    var height =($(document).height()-($(document).height()/5));  //was width:780

    var svg = d3.select("#graph").append("svg")
        .attr("width", width)
        .attr("height", height)
        .attr('version', '1.1')
        .attr('baseProfile', 'full')
        .attr("xmlns", "http://www.w3.org/2000/svg")
        .attr("xmlns:xmlns:xlink", "http://www.w3.org/1999/xlink");

    var clickOnNode = function(d) {

        d3.selectAll('tr.selected').classed('selected', false);
        d3.select(this).classed('selected', !d3.select(this).classed('selected'));
        var sibling = d3.select(this)[0][0].nextSibling;
        d3.select(sibling).classed('selected', !d3.select(sibling).classed('selected'));

        if (!d3.select(this).classed('selected')){ hideMore(); }

        utils.info.toggle((_.isUndefined(d.name) ? d.node.name : d.name));

        if (d3.select(this).classed('selected')){
            getContent(d);
        }
    }

    var clickOnLink = function(d) {var url = "${request.route_url('mistic.template.pairplot', dataset=dataset, genes=[])}";
                                   url += '/' + d.source.id;
                                   url += '/' + d.target.id;
                                   window.open(url);
                                  }


    var labelAnchors= [];
    for(var i = 0; i < json.nodes.length; i++) {
        var node = json.nodes[i];
        labelAnchors.push({ node : node  });
        labelAnchors.push({ node : node  });
    }

    var labelAnchorLinks= [];
    for(var i = 0; i < json.nodes.length; i++) {
        labelAnchorLinks.push({
            source : i * 2,
            target : i * 2 + 1,
            weight :1
        });
    }

    var grav = 0.2; // 0.2;
    var charge = -150; // -150;
    var distance = 50;

    var force;
    var force2;

    var initForce = function() {
        force = d3.layout.force()
            .gravity(grav)
            .charge(charge)
            .distance(distance)
            .size([width, height])
            .nodes(json.nodes)
            .links(json.links);

        force.start();
    }

    var initForceLabel = function() {

        force = d3.layout.force()
            .gravity(grav)
            .charge(charge)
            .size([width, height])
            .nodes(json.nodes)
            .links(json.links)
            .linkDistance(50)
            .linkStrength(function(x) {
                return x.weight * 10;
            });

        force2 = d3.layout.force()
            .gravity(0)
            .charge(-150)
            .size([width, height])
            .nodes(labelAnchors)
            .links(labelAnchorLinks)
            .linkDistance(0)
            .linkStrength(8)
            .on('end', function() {
                console.log('force2 ended!');
            });

        force2.start();

        force2.on("tick", function() {
            updateAnchors();
        });

        force.on('end', function() {
            force2
                .charge(-500)
                .distance(1)
                .gravity(0.5)
                .alpha(0.05);
            force2.start();
            console.log('forced ended!');
        });

        force.start();
    }

    var dealWithLabels = false;
    console.debug('Deal with labels: ' +dealWithLabels);

    initForce ();
    initForceLabel();

    var graph = svg.append('g').attr('class', 'graph');

    var link = graph.selectAll(".link")
        .data(json.links)
        .enter().append("line")
        .attr("stroke-width", 2)
        .attr("stroke", function(d) { return colour.YlGnBl(1-d.weight); })
        .on('click', clickOnLink);

    var anchorLink = svg.selectAll("line.anchorLink").data(labelAnchorLinks).enter().append("svg:line")
        .attr("class", "anchorLink").style("stroke", "#999").style("stroke-width", Number(dealWithLabels));

    var node = svg.selectAll("g.node").data(force.nodes()).enter().append("svg:g")
        .attr("class", "node");

    node.append("svg:circle").attr("r", 5).style("fill", "#000").style("stroke", "#FFF").style("stroke-width", 0);
    node.call(force.drag);

    var anchorNode = svg.selectAll("g.anchorNode").data(labelAnchors).enter().append("svg:g")
        .attr("class", function(d, i) {return  i % 2 == 0 ? "anchorNode fixed" : "anchorNode moving"});
    anchorNode.append("svg:circle").attr("r", 0).style("fill", "#FFF");
    anchorNode.append("svg:rect").attr('height', 15).attr('x', 0).attr('y', 0)
        .style("stroke", "#000")
        .style("stroke-width", 1)
        .on('click', clickOnNode )
        .append("title")
        .text(function(d) { return d.node.title; });

    anchorNode.append("svg:text")
        .attr('dy',10)
        .attr('dx',2.5)
        .text(function(d) {return d.node.name;})
        .style("font-family", "Arial").style("font-size", 10);

    anchorNode.each(function(d, i) {
        var w = d3.select(this).select('text')[0][0].getBBox().width;
        d3.select(this).select('rect').attr('width',( w==0 ? 0 : w+5 ));

        if (!(i % 2 == Number(dealWithLabels))) {
            d3.select(this).style('display','none');
        }

    });

    anchorNode.selectAll('rect').call(force.drag);

    var resetForceParameters =function() {
        force.gravity(0.2);
        force.charge(-150);
        force.distance(50);
    }


    var updateLink = function() {
        this.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });
    }

    var updateNode = function() {
        this.attr("transform", function(d) { return "translate(" + (_.isUndefined(d.x) ? d.node.x : d.x) + "," + (_.isUndefined(d.y) ? d.node.y : d.y) + ")"; });
    }


    var  updateAnchors = function(){
        anchorNode.each(function(d, i) {

            if(i % 2 == 0) {
                d.x = d.node.x;
                d.y = d.node.y;
            }
            else {
                var b = this.childNodes[1].getBBox();

                var diffX = d.x - d.node.x;
                var diffY = d.y - d.node.y;

                var dist = Math.sqrt(diffX * diffX + diffY * diffY);

                var shiftX = b.width * (diffX - dist) / (dist * 2);
                var shiftY = b.height * (diffY - dist) / (dist * 2);

                shiftX = Math.max(-b.width, Math.min(0, shiftX));
                shiftY = Math.min(b.height, Math.max(0, shiftY));

                this.childNodes[0].setAttribute("transform", "translate(" + shiftX + "," + shiftY + ")");
                this.childNodes[1].setAttribute("transform", "translate(" + shiftX + "," + shiftY + ")");
                this.childNodes[2].setAttribute("transform", "translate(" + shiftX + "," + shiftY + ")");
            }
        });
        anchorNode.call(updateNode);
        anchorLink.call(updateLink);

    }


    force.on("tick", function() {

        node.call(updateNode);
        anchorNode.call(updateNode);
        link.call(updateLink);

        force2.start();

        var xlo, xhi, ylo, yhi;

        xlo = xhi = json.nodes[0].x;
        ylo = yhi = json.nodes[0].x;

        for (var i = 1; i < json.nodes.length; ++i) {
            xlo = Math.min(xlo, json.nodes[i].x);
            ylo = Math.min(ylo, json.nodes[i].y);
            xhi = Math.max(xhi, json.nodes[i].x);
            yhi = Math.max(yhi, json.nodes[i].y);

        }

        var xfrac = (xhi - xlo) / width;
        var yfrac = (yhi - ylo) / height;

        if (xfrac < .75 && yfrac < .75) {
            if (grav > 0.05) grav *= .99;
            charge *= 1.01;
            force.gravity(grav);
            force.charge(charge);
        }

        if (xfrac > 1.0 || yfrac > 1.0) {
            grav *= 1.11;
            charge *= .90;
            force.gravity(grav);
            force.charge(charge);
        }

    });


    getAccordionGroup = function(parentId, id, title, content) {
        h = '<div class="accordion-group">';
        h = h + '<div class="accordion-heading">';
        h = h + '<a class="accordion-toggle" data-toggle="collapse" data-parent="#'+parentId+'" href="#a'+id+'">';
        h = h + '<div id="title"><h5>'+title+'</h5></div>';
        h = h + '</a></div><div id="a'+id+'" class="accordion-body collapse"><div class="accordion-inner" style="max-height:300px; overflow-y:auto">';
        h = h + content;
        h = h + '</div></div></div>'

        return h;
    }


        <%block name="getExtraContent">
        getContent = function(d) {
            if (_.isUndefined(d.name)) {  d = d.node; }
            var ebLink = 'http://www.ensembl.org/Human/Search/Results?q='+d.name+';facet_feature_type=;site=ensembl;facet_species=Human';
            var gcLink = 'http://www.genecards.org/cgi-bin/carddisp.pl?gene='+d.name+'&search='+d.name+'';
            var egLink = 'http://www.ncbi.nlm.nih.gov/gene?cmd=search&term='+d.name+'[sym] AND human[ORGN]';
            var wkLink = 'http://en.wikipedia.org/wiki/'+d.name;
            var urlEnsembl = 'http://beta.rest.ensembl.org/lookup/symbol/homo_sapiens/'+d.name+'?content-type=application/json';
            var urlNCBI  = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=_id_&retmode=txt';
            var urlEnsemblId = 'http://beta.rest.ensembl.org/xrefs/id/_id_?content-type=application/json';

            var links = {'Ensembl':ebLink, 'GeneCards':gcLink, 'EntrezGene': egLink, 'Wikipedia': wkLink};
            var infos = ['Ensembl','EntrezGene']

            var part2 = $("#part2");
            part2.html('').append('<p><div class="accordion" id="info"></div>');

            h = d.name +' : '+d.title;
            c = '<ul id="links" class="source-links" style="padding:5px;"><li>GO TO : </li></ul>';
            $('#part2 > .accordion').append(getAccordionGroup('info','ttle', h, c ))

            _.each(_.pairs(links), function(p) {
                h = '<li><a href="'+p[1]+'" target="_blank"> <strong>'+p[0]+'</strong></a></li>';
                $('#links').append(h);
            });
            _.each(infos, function(p) {
                $('#part2 > .accordion').append(getAccordionGroup('info',p, p,''))
            });
            $('.accordion-body:first').addClass('collapse in');


            $.ajax({type: 'GET',
                    url: urlEnsembl ,
                    success: function(data) {
                        var eid = data['id']

                        p = '<pre>';
                        _.each(_.pairs(data), function(a) {
                            p = p +a[0]+' : '+a[1]+'<br>';
                        });
                        p = p + '</pre>';

                        $('#aEnsembl > .accordion-inner').append(p);

                        egid = '';
                        $.get(urlEnsemblId.replace('_id_', eid), function(r){
                            egid =  _.where(r, {dbname:"EntrezGene"})[0].primary_id;

                            $.get(urlNCBI.replace('_id_', egid), function(r){
                                $('#aEntrezGene > .accordion-inner').append('<pre>'+r+'</pre>');

                            });
                        });

                    },
                    beforeSend : function() {
                        $("#aEnsembl > .accordion-inner").append('<div id="loading"><img src="${request.application_url}/static/img/ajax-loader.gif"/> </div>');
                        $("#aEntrezGene > .accordion-inner").append('<div id="loading"><img src="${request.application_url}/static/img/ajax-loader.gif"/> </div>');
                    },
                    complete: function() {
                        $("div#loading").remove();
                    },

                    error: function() {},
                    dataType: 'json',
                    async: true
                   });


        };



    getAnnotationContent = function(d) {
        var a = d.info;
        a = _.omit(a, ['name', 'cat', 'id']);
        $('#part2').html('');
        $('#part2').append('<div class="accordion" id="info"></div>');
        h = '';
        _.each(_.pairs(a), function(i) {
            if (i[0]=='name'){
                h = h+ "<span style='font-weight:bold'>"+i[0] + "</span>: " + i[1]+'<br>' ;
            }
            else {

                h = h + "<span style='font-weight:bold'>"+i[0] + "</span>: " ;
                if (i[0]=='image'){
                    h = h +"<img  src='"+i[1]+"' alt='[structure not found/available]'>";
                }
                else {
                    if (i[0]=='url'){
                        h = h +"<a href='"+i[1]+"'>"+i[1] +"</a>";
                    }
                    else {
                        h = h + i[1];
                    }
                }
                h = h +"<br>"
            }

            ;});


        h = h + "<p>";
        h = h + '<table class="table table-condensed" <thead><tr>';
        h = h + '<th></th><th>In cluster</th><th>Not in cluster</th>';
        h = h + '</tr></thead>';
        h = h + '<tbody>';
        h = h + '<tr><th>In gene set</th><td>'+d.tab[0][0]+'</td> <td>'+d.tab[1][0]+'</td></tr>';
        h = h + '<tr><th>Not in gene set</th><td>'+d.tab[0][1]+'</td> <td>'+d.tab[1][1]+'</td></tr>';
        h = h + '</tbody>';
        h = h + '</table></div></div>';
        $('#part2 > .accordion').append(getAccordionGroup('info', '1', d.name.replace(/_/g, ' '), h))
        $('.accordion-body:first').addClass('collapse in');

    };






    </%block>

    hideMore = function() {
        d3.select('#part2').html('');
        return false;
    };

    $('#select_all').on('click', function(event) {
        d3.selectAll('tr.selected').classed('selected', false);
        d3.select('#graph').selectAll('rect').classed('selected', true);
        utils.info.clear();
        graph.selectAll('rect.selected').each(function(d){
            utils.info.add(d.node.name);

        });
        return false;
    });


    var showName = false;
    $('#show_labels').on("click", function(event){
        showName = !showName;

        var cls = dealWithLabels ? 'g.moving' : 'g.fixed';

        if (showName) {d3.select('#graph').selectAll(cls).selectAll('text').each(function(d) {d3.select(this).text(d.node.name);});}
        if (!showName){d3.select('#graph').selectAll(cls).selectAll('text').each(function(d) {d3.select(this).text(d.node.title);});}

        d3.select('#graph').selectAll(cls).each(function(d) {
            var w = d3.select(this).select('text')[0][0].getBBox().width ;
            d3.select(this).select('rect').attr('width',( w==0 ? 0 : w+5 ));
        });


        resetForceParameters ();
        force.start();
        return false;

    });

    $('#dealWithLabels').on('click', function(event) {

        dealWithLabels = !dealWithLabels;
        var cls = dealWithLabels ? 'g.moving' : 'g.fixed';
        var txt = dealWithLabels ? 'Do not avoid overlapping labels' : 'Avoid overlapping labels';
        var linkStroke = dealWithLabels ? 1 : 0;
        $(this).text(txt);
        d3.select('#graph').selectAll('.anchorNode').style('display', 'none');
        d3.select('#graph').selectAll('.anchorLink').style('stroke-width', linkStroke);
        d3.select('#graph').selectAll(cls).style('display', 'inline');

        event.preventDefault();
    });

    $('#clear_selection').on('click', function(event) {
        d3.selectAll('tr.selected').classed('selected', false);
        d3.select('#graph').selectAll('rect.selected').classed('selected', false);
        utils.info.clear();
        return false;
    });

    $('#scatterplot').on('click', function(event) {
        var ids = [];
        d3.selectAll('tr.selected').classed('selected', false);
        d3.select('#graph').selectAll('rect.selected').each(function(d) {
            ids.push(d.node.id);
        });
        if (ids.length > 1) {
            var url = "${request.route_url('mistic.template.pairplot', dataset=dataset, genes=[])}";
            for (var i = 0; i < ids.length; ++i) {
                url += '/' + ids[i];
            }
            window.open(url);
        }
        return false;
    });



    $(document).keyup(function(e) {
        if (e.keyCode == 27) {  hideMore(); }
    });


    $(document).ready(function() {
        updateEnrichmentTable();

        $.ajax({
            url: "${request.route_url('mistic.json.dataset.geneset.enrich', dataset=dataset)}",
            dataType: 'json',
            type: 'POST',
            data: {
                genes: JSON.stringify(_.pluck(json.nodes, 'id'))
            },
            error: function(req, status, error) {
                console.log('got an error', status, error);
            },
            beforeSend : function() {
                $("#go_table .dataTables_empty").append('<div id="loading"><img src="${request.static_url('mistic:app/static/img/ajax-loader.gif')}"/></div>');
            },
            success: function(data) {
                json.gstab = data;
                updateEnrichmentTable();
            },
            complete: function() {
                $("div#loading").remove();
            }
        });
    });

    var resizeGraph = function() {
        var ht = $(window).height()-$("#graph").offset().top - 14;
        $("#graph").height(ht);
        $("#graph-right").height(ht);

        svg
            .attr("width",  width  = $("#graph").width())
            .attr("height", height = $("#graph").height());

        force.size([width, height]);
        force2.size([width, height]);

        force.start();
    };

    $(window).resize(resizeGraph);
    resizeGraph();
});
</script>
</%block>
