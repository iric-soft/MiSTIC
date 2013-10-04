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
<%block name="controls">
  <form class="form-inline">
   
    <div class="btn-group-pull-right">
    <%block name="controls_buttons">
      <button class="btn btn-primary" id="select_all">Select all</button>
      <button class="btn btn-primary" id="clear_selection">Clear selection</button>
      <button class="btn btn-primary" id="scatterplot">Scatterplot</button>
      <button class="btn btn-primary" data-toggle="button"  id="show_labels">Toggle labels</button>
    </%block>  
    </div>
    
  </form>
</%block>

<%block name="style">
${parent.style()}

#go_table {
  max-height: 400px;
  max-width: 500px;
  overflow-y: visible;
  overflow-x: hidden;
  font-family: helvetica; 
  font-size: 10.5px; 
  float: right;
}

div#more-information {
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

tr:hover {
  background-color: #f0f0f0;
}

tr.selected {
  background-color: #cc7400;
  color: #fff;
}

rect.selected {
  fill: #cc7400;
}

#part2 {
  overflow-y: hidden;
  overflow-x: hidden;
  font-family: helvetica; 
  font-size: 10.5px; 
  width: 400px;
}
</%block>

<%block name="graph">

 <div class="row-fluid">
 	 <div class="span12" id="more-information"></div>
 </div>

 <div class="row-fluid" id="document-graph">
   <div class="span7" id="graph"></div>
   <div class="span5" id="graph-right">
      <div class="span12" id="go_table"></div>
      <div class="span12" id="spacer" style='height:100px;'></div>
      <div class="span12" id="part2"></div>
   </div>
 </div>
  
    
</%block>


<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/djset.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/node.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/mstplot.js')}" type="text/javascript"></script>


<%
  ds = data.datasets.get(dataset)
  a = ds.annotation
 
  enrichment_tab = []
  for k in a.others.keys():
    a_others = a.others.get(k)	
    a_others_genes = a.others_genes.get(k)
    all_terms = set()
 
    for n in nodes : 
      all_terms.update(a_others.get(n, set()))
   
    for g in all_terms:
      if g=="": continue
      
      genes_with_terms = [n for n in nodes if g in a_others.get(n, set()) ]
      YY = len(genes_with_terms)
      if YY == 1: continue
      YN = len(nodes) - YY
      NY = len(a_others_genes[g]) - YY
      NN = len(a.genes) - YY - YN - NY
      tab = [ [ YY, YN ], [ NY, NN ] ]
             
      odds, p_val = scipy.stats.fisher_exact(tab)
      if odds < 1 or p_val > 0.05: continue
  
      enrichment_tab.append(dict(
            id = g,
            ns = "",
            desc = "",
            tab = tab,
            p_val = p_val,
            odds = odds,
            genes = genes_with_terms,
            kind = k
        ))

  
  all_go = set()
  for n in nodes:
    all_go.update(a.go.get(n, set()))
    
  for g in all_go:
    genes_with_go_term = [
      n for n in nodes 
      if g in a.go.get(n, set()) or g in a.go_indirect.get(n, set()) ]
    
    YY = len(genes_with_go_term)
    if YY == 1: continue
    YN = len(nodes) - YY
    NY = len(a.go_genes[g] | a.go_genes_indirect[g]) - YY
    NN = len(a.genes) - YY - YN - NY
    tab = [ [ YY, YN ], [ NY, NN ] ]
    
  
    odds, p_val = scipy.stats.fisher_exact(tab)
    if odds < 1 or p_val > 0.05: continue
    ns = data.ontology.nodes[g].namespace if g in data.ontology.nodes.keys() else ''
    nsdict = {'molecular_function':'[MF]', 'biological_process':'[BP]', 'cellular_component':'[CC]', '':''}
    
    enrichment_tab.append(dict(
          id = g,
          ns = nsdict[ns],
          desc = data.ontology.nodes[g].desc if g in data.ontology.nodes.keys() else '',
          tab = tab,
          p_val = p_val,
          odds = odds,
          genes = genes_with_go_term, 
          kind = "GO" ))


  enrichment_tab.sort(key = lambda d: d['p_val'])

  E = [ dict(source=e[0][0], target=e[0][1], weight=e[1]) for e in edges ]
  V = [ dict(
    id    = n,
    name  = a.attrs.get(n, {}).get('symbol') or n,
    title = a.attrs.get(n, {}).get('name') or '',
    chr = a.attrs.get(n, {}).get('chr') or '',
    formula = a.attrs.get(n, {}).get('formula') or '',
    can = a.attrs.get(n, {}).get('can') or '',
    smile = a.attrs.get(n, {}).get('smi') or '',
    actions = a.attrs.get(n, {}).get('actions') or '',
    type = ds.type,
  ) for n in nodes ]
 
%>

<script type="text/javascript">

var json = {
  "nodes": ${json.dumps(V)|n},
  "links": ${json.dumps(E)|n},
  "enrichmenttab": ${json.dumps(enrichment_tab)|n},
};

var table = d3.select('#go_table').insert('table', ':first-child');
var thead = table.append('thead');
var tbody = table.append('tbody');

var th = thead.selectAll("th")
    .data([ 'P-value', 'Odds', 'Type', 'Term', 'Description' ])
    .enter()
    .append("th")
    .text(function(d) { return d; });

var tr = tbody.selectAll('tr')
    .data(json.enrichmenttab)

tr.enter()
    .append('tr')
    .on('click', function(d) {
      var self = this;
      d3.selectAll('tr').classed('selected', function(d2) { return this === self; });
      var sel = {}
      for (var i = 0; i < d.genes.length; ++i) {
        sel[d.genes[i]] = true;
      }
      graph.selectAll('rect').classed('selected', function(d) { return sel[d.id]; });
      clearInformation();
      graph.selectAll('rect.selected').each(function(d) {
          addInformation(d.name);
         
          } );
    })
    ;

var td = tr.selectAll('td')
    .data(function(d) { return [
      [ 'p_val', d.p_val.toExponential(2) ],
      [ 'odds', d.odds.toFixed(2) ],
      [ 'type', d.kind ],
      [ 'term', d.id ],
      [ 'desc', d.desc +" "+d.ns],
      
    ];});

td.enter()
    .append('td')
    .text(function(d) { return d[1]; })
    .attr('title', function(d) {return d[1];})
    ;
 

var width =($(document).width()-60)/12*7; //was width:1024
var height =($(document).height()-($(document).height()/5));  //was width:780

var svg = d3.select("#graph").append("svg")
    .attr("width", width)
    .attr("height", height);

var grav = .20;
var charge = -150; //was -150
var force = d3.layout.force()
    .gravity(grav)
    .charge(charge)
    .distance(50)
    .size([width, height]);

force
   .nodes(json.nodes)
   .links(json.links)
   .start();

force.on("tick", function() {
  link.attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });

  node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

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
    grav *= 1.01;
    charge *= .99;
    force.gravity(grav);
    force.charge(charge);
  }

});

var graph = svg
    .append('g')
    .attr('class', 'graph');

var link = graph.selectAll(".link")
    .data(json.links)
  .enter().append("line")
    .attr("stroke-width", 2)
    .attr("stroke", function(d) { return YlGnBl(1-d.weight); })
    .on('click', function(d) {   
      window.open("${request.route_url('mistic.template.scatterplot_static', dataset=dataset, gene1='_g1_', gene2='_g2_')}".replace('_g1_', d.source.id).replace('_g2_',d.target.id));
     
    });

var node = graph.selectAll(".node")
    .data(json.nodes)
  .enter().append("g")
    .attr('style', 'font-family: helvetica; font-size: 10px; font-weight: 400')
    .attr('fill', '#fff')
    .call(force.drag);

node.append("circle")
    .attr("x", 0)
    .attr("y", 0)
    .attr("r", 5)
    .attr("fill", "#000");

node.append("rect")
    .attr('height', 15)
    .attr('x', 5)
    .attr('y', -6)
    .attr('fill', '#0074cc')
    .attr('stroke', '#000')
    .on('click', function(d) {
      d3.selectAll('tr.selected').classed('selected', false);
      d3.select(this).classed('selected', !d3.select(this).classed('selected'));
      
      if (!d3.select(this).classed('selected')){ hideMore(); }
      addInformation(d.name);

      if (d3.select(this).classed('selected')){  
        getContent(d);
       }   
    })
    .append("title")
    .text(function(d) { return d.title+" "+d.chr; });

<%block name="getExtraContent">
getContent = function(d) {
 
  d3.select('#part2').html("<h4>"+d.title +"</h4>"+
           '<p><a href=http://www.genecards.org/cgi-bin/carddisp.pl?gene='+d.name+'&search='+d.name+' target="_blank">GeneCards</a>'+
           '&nbsp;&nbsp;<a href=http://en.wikipedia.org/wiki/'+d.name+' target="_blank">Wikipedia</a>');
};

</%block>

hideMore = function() {
  d3.select('#part2').html('');
  return false;
};


node.append("text")
    .attr("dx", 10)
    .attr("dy", 6)
    .attr("pointer-events", "none")
    .text(function(d) { return d.name});


node.each(function(d) {
    var w = d3.select(this).select('text')[0][0].getBBox().width + 8;
    d3.select(this).select('rect').attr('width', w);
});



$('#select_all').on('click', function(event) {
  d3.selectAll('tr.selected').classed('selected', false);
  graph.selectAll('rect').classed('selected', true);
  clearInformation();
  graph.selectAll('rect.selected').each(function(d){
         addInformation(d.name); 
         
         });
  return false;
});


var showName = false;
 $('#show_labels').on("click", function(event){
    showName = !showName;
    if (showName) {
      graph.selectAll('text').each(function(d) { d3.select(this).text(d.name);  });
    }
    if (!showName){
      graph.selectAll('text').each(function(d) { d3.select(this).text(d.title);  });
    }
    
    node.each(function(d) {
        var w = d3.select(this).select('text')[0][0].getBBox().width + 8;
        d3.select(this).select('rect').attr('width', w); });
    return false;
  });


$('#clear_selection').on('click', function(event) {
  d3.selectAll('tr.selected').classed('selected', false);
  graph.selectAll('rect.selected').classed('selected', false);
  clearInformation();
  return false;
});

$('#scatterplot').on('click', function(event) {
  var ids = [];
  d3.selectAll('tr.selected').classed('selected', false);
  graph.selectAll('rect.selected').each(function(d) {
    ids.push(d.id);
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

</script>
</%block>
