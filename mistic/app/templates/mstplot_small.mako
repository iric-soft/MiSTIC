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
   
        <div class="btn-group-pull-right">
            <%block name="controls_buttons">
               <button class="btn btn-primary" id="select_all">Select all</button>
               <button class="btn btn-primary" id="clear_selection">Clear selection</button>
               <button class="btn btn-primary" id="scatterplot">Scatterplot</button>
               <button class="btn btn-primary" id="mdsplot">MDSplot</button>
               <button class="btn btn-primary" id="show_labels">Toggle labels</button>
               
               
            </%block>  
        </div>
    </form>
   

    </div>
  </div>
    
  <div class="row-fluid">
  <div class="span12">
    <div class="span12 information"> Selection :</div>
    <div class="span12" id="more-information"> </div>
    </div></div>

 <div class="row-fluid" id="document-graph">
   <div class="span7" id="graph"></div>
   <div class="span5" id="graph-right">
      <div class="span12" id="go_table"></div>

      <div class="span12" id="part2"></div>
   </div>
 </div>
  
    
<%block name="subcontent"></%block>
  
</%block>


<%block name="style">
${parent.style()}

div#more-information, .information{
   color: #cc7400;
   font-weight:bold;
   padding: 10px 0px 0px 0px;
   float: right;
   overflow:hidden;
}


th, td {
  white-space: nowrap;
  padding: 0px 5px;
  text-align: left;
}

rect {
  fill: #0074cc;
}
text {
 fill: #fff;
}
#go_table {
overflow-x : auto;
}
<%block name="style2"/>

</%block>

<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/djset.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/node.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/mstplot.js')}" type="text/javascript"></script>

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

var json = {
  "nodes": ${json.dumps(V)|n},
  "links": ${json.dumps(E)|n},
  "gstab": {},
};


var updateNodeStatus = function (nodes, selected, clear) {
    
    if (clear) {
        d3.select('#graph').selectAll('rect').classed('selected', false).style('fill',  '#0074cc');
        info.clear();
    }    
   if (!_.isNull(nodes)) {
    nodes.classed('selected', selected).style('fill',  selected ? '#cc7400' : '#0074cc');  
    nodes.each(function(d) {info.toggle(d.name);});
   }
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


    var tr_header = [ 'P-value', 'Odds',  'Name', 'Type','Cat', 'ID' ];
    var th = thr.selectAll('th')
        .data(tr_header)
        .enter()
        .append('th')
        .text(function(d) { return d; });

    var thr = tfoot.selectAll("tr")
        .data([ 1 ])
        .enter()
        .append("tr");

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
            
         
            selected_nodes = d3.select('#graph').selectAll('rect').filter(function (d,i ) {return sel[d.id]});
            updateNodeStatus(selected_nodes, true, true);
           
            
       
    });

    var td = tr.selectAll('td')
        .data(function(d) { return [
        { value: (typeof(d.p_val) === 'string') ? d.p_val : d.p_val.toExponential(2) },
        { value: (typeof(d.odds)  === 'string') ? d.odds  : d.odds.toFixed(2) },
        { value: d.name, title: d.desc },
        { value: d.gs },
        { value: d.cat },
        { value: d.id },
        
        ];});

    td.enter()
        .append('td')
        .text(function(d) { return d.value; })
        .attr('title',   function(d) {return d.title; })
        .attr('classed', function(d) {return d.class; })
        ;
    $('#gotable').dataTable({ "aoColumnDefs": [{ "sType": "scientific", "aTargets": [ 0 ],  'aaSorting':["asc"] },
                                               { "sType": "numeric", "aTargets": [ 1 ]},
                                               ],
                         
                          "bPaginate" : true,
                          "iDisplayLength": 10,
                          "sPaginationType": "full_numbers",
                          "bLengthChange": false,
                          "bFilter": true,
                          "bSort": true,
                          "bInfo": true,
                          "sDom": '<toolbar>T<"clear">frtip' ,
                          "oTableTools": defineStandardTableTools ("${request.static_url('mistic:app/static/swf/copy_csv_xls.swf')}", 'mistic_geneset_enrichment', 'visible'),
                          
                      
          
    }).columnFilter({sPlaceHolder: "tfoot", 
                    aoColumns:[null,
                               null, 
                               {type:'text', bRegex:true},
                               {type:'text', bRegex:true},
                               {type:'text', bRegex:true},
                               {type:'text', bRegex:true}]});
    
   
   
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
 
      updateNodeStatus(d3.select(this), !d3.select(this).classed('selected'), false);
      d3.selectAll('tr.selected').classed('selected', false);
      d3.select(this).classed('selected') ?  getContent(d) : hideMore(); 
      
    }
    
var clickOnLink = function(d) {
       var url = "${request.route_url('mistic.template.pairplot', dataset=dataset, genes=[])}";     
       url += '/' + d.source.id;
       url += '/' + d.target.id;
       window.open(url); 
}


var grav = 0.2; //0.2;
var charge = -150 ;//-150;
var distance = 50;

var force;

var initForce = function(){
    force = d3.layout.force().gravity(grav).charge(charge).distance(distance).size([width, height]).nodes(json.nodes).links(json.links);
    force.start();
}


initForce ();

var graph = svg.append('g').attr('class', 'graph');

var link = graph.selectAll(".link")
    .data(json.links)
    .enter().append("line")
    .attr("stroke-width", 2)
    .attr("stroke", function(d) { return YlGnBl(1-d.weight); })
    .on('click', clickOnLink);

var node = svg.selectAll("g.node").data(force.nodes()).enter().append("svg:g")
          .attr("class", "node")
          .attr('style', 'font-family: helvetica; font-size: 10px; font-weight: 400')
          .attr('fill', '#fff');
          
node.append("svg:circle")
    .attr("r", 5)  
    .attr("x", 0)
    .attr("y", 0)
    .style("fill", "#000")
    .style("stroke", "#FFF")
    .style("stroke-width", 0);

node.append("rect")
    .attr('height', 15)
    .attr('x', 5)
    .attr('y', -6)
    .attr('fill', '#0074cc')
    .attr('stroke', '#000')
    .on('click', clickOnNode)
    .append("title")
    .text(function(d) { return d.title+" "+d.chr; });


    
node.append("svg:text")
    .attr("dx", 10)
    .attr("dy", 6)
    .attr("pointer-events", "none")
    .text(function(d) { return d.name});
    
node.each(function(d) {
    var w = d3.select(this).select('text')[0][0].getBBox().width + 8;
    d3.select(this).select('rect').attr('width', w);
});

node.call(force.drag);

var updateLink = function() {
  this.attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });
}

var updateNode = function() {
    this.attr("transform", function(d) { return "translate(" + (_.isUndefined(d.x) ? d.node.x : d.x) + "," + (_.isUndefined(d.y) ? d.node.y : d.y) + ")"; });
} 

force.on("tick", function() {
  
  node.call(updateNode);
  link.call(updateLink);
  
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
  var urlEnsembl = 'http://rest.ensembl.org/lookup/symbol/homo_sapiens/'+d.name+'?content-type=application/json';
  var urlNCBI  = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gene&id=_id_&retmode=txt'; 
  var urlEnsemblId = 'http://rest.ensembl.org/xrefs/id/_id_?content-type=application/json';
  
  var links = {'Ensembl':ebLink, 'GeneCards':gcLink, 'EntrezGene': egLink, 'Wikipedia': wkLink};
  var infos = ['Ensembl','EntrezGene']
  
  var part2 = $("#part2");
  part2.html('').append('<p><div class="accordion" id="info"></div>');
  
  h = 'Gene : ' + d.name +' : '+d.title;
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
                    h = h +"<a href='"+i[1]+"' target='_blank'>"+i[1] +"</a>";
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
  $('#part2 > .accordion').append(getAccordionGroup('info', '1', 'Geneset: '+d.name.replace(/_/g, ' '), h))
  $('.accordion-body:first').addClass('collapse in');
  
};






</%block>

hideMore = function() {
  d3.select('#part2').html('');
  return false;
};

$('#select_all').on('click', function(event) {
  d3.selectAll('tr.selected').classed('selected', false);
  updateNodeStatus(d3.select('#graph').selectAll('rect'), true, true);
  return false;
});

$('#clear_selection').on('click', function(event) {
  d3.selectAll('tr.selected').classed('selected', false);
  updateNodeStatus(null, false, true);
  return false;
});


var showName = false;
$('#show_labels').on("click", function(event){
   
    showName = !showName; 
    d3.select('#graph').selectAll('text').each(function(d) {showName ? d3.select(this).text(d.title) :d3.select(this).text(d.name) ;});
   
    d3.select('#graph').selectAll('.node').each(function(d) {
       var w = d3.select(this).select('text')[0][0].getBBox().width + 8;
       d3.select(this).select('rect').attr('width',w); 
      });

    return false;
    
  });






$('#scatterplot').on('click', function(event) {
  var ids = [];
  d3.selectAll('tr.selected').classed('selected', false);
  d3.select('#graph').selectAll('rect.selected').each(function(d) {
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


$('#mdsplot').on('click', function(event) {
  var ids = [];
  d3.selectAll('tr.selected').classed('selected', false);
  d3.select('#graph').selectAll('rect.selected').each(function(d) {
    ids.push(d.id);
  });
  if (ids.length > 1) {
    var url = "${request.route_url('mistic.template.mds', dataset=dataset, genes=[])}";
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
        data: { genes: JSON.stringify(_.pluck(json.nodes, 'id')) },
        error: function(req, status, error) {
          console.log('got an error', status, error);
        },
        beforeSend : function() {
        $("#go_table .dataTables_empty").append('<div id="loading"><img src="${request.application_url}/static/img/ajax-loader.gif"/> </div>');
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









</script>
</%block>
