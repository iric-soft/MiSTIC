<%!
import json
import mistic.app.data as data
import numpy
import pybel
%>

<%inherit file="mistic:app/templates/mstplot_small.mako"/>

<%block name="controls_buttons">
 ${parent.controls_buttons()}
    <a href="#document-tanimoto" role="button" class="btn" data-toggle="modal">Tanimoto</a>
</%block>

<%block name="style">
${parent.style()}

#tanimoto_table { 
  overflow-y: visible;
  overflow-x: hidden;
  font-family: helvetica; 
  font-size: 11px;    
  max-height:800px;
}

#tanimoto_table  tr.selected {
  background-color: #d4c6ba;
  font-weight:bold;
}

#tanimoto_chord {
  overflow: hidden;
}

#tanimoto_table tr:hover {
  background-color: #d4c6ba;
}

#part2 {
  overflow-y: hidden;
  overflow-x: hidden;
  font-family: helvetica; 
  font-size: 10.5px; 
}

.modal {
  position: fixed;
  top: 30%;
  left: 30%;
  z-index: 1050;
  width: 1050px;
  margin: -300px 0 0 -280px;
  overflow: hidden;
  background-color: #ffffff;
  border: 1px solid #999;
  border: 1px solid rgba(0, 0, 0, 0.3);
  *border: 1px solid #999;
  -webkit-border-radius: 6px;
     -moz-border-radius: 6px;
          border-radius: 6px;
  -webkit-box-shadow: 0 3px 7px rgba(0, 0, 0, 0.3);
     -moz-box-shadow: 0 3px 7px rgba(0, 0, 0, 0.3);
          box-shadow: 0 3px 7px rgba(0, 0, 0, 0.3);
  -webkit-background-clip: padding-box;
     -moz-background-clip: padding-box;
          background-clip: padding-box;
}
.modal-body {
  max-height: 600px;
  padding: 15px;
  overflow:hidden;
}

#document-tanimoto input {
  width:70px;
  font-size:10.5px;
}

#document-tanimoto label {
  font-size:10.5px;
}

#tanimoto-value {
  font-size:10.5px;
}

</%block>


<%block name="graph">

<%
  ds = data.datasets.get(dataset)
  a = ds.annotation
  
  molecules = []
  names = {}
 
  for n in nodes: 
    try:
      molecules.append(pybel.readstring( 'smi', str(a.attrs.get(n, {}).get('smi'))))
    except:
      print a.attrs.get(n, {})  
      
  tanimoto =  [[ mol1.calcfp() | mol2.calcfp() for mol1 in molecules] for mol2 in molecules]
  d = dict(zip(nodes,tanimoto))
  d.update({'header': nodes})
  tanimoto_tab = d 
  
  A = [ dict(
    id    = n,
    name  = a.attrs.get(n, {}).get('name') or n,
    #formula = a.attrs.get(n, {}).get('formula') or '',
    #can = a.attrs.get(n, {}).get('can') or '',
    #smile = a.attrs.get(n, {}).get('smi') or '',
    index = nodes.index(n),
    mean = numpy.mean(tanimoto[nodes.index(n)]),
    sum = numpy.sum(tanimoto[nodes.index(n)]),
  ) for n in nodes if n in tanimoto_tab.keys()]
%>


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
  

 <div class="modal hide fade" id="document-tanimoto">
  <div class='modal-body'>
     <div class="row-fluid" id="document-tanimoto">
    <div class="span5" id="tanimoto_table" ></div>
    <div class="span1" id="tanimoto_search" ></div>
     <form class="form-inline">
       <label for="search1">Compound1:</label>
       <input type="text" id="search1" >
       <label for="search2">Compound2:</label>
       <input type="text" id="search2" ">
       <span id="tanimoto-value"></span>
     </form>
    <div class="span6" id="tanimoto_chord" ></div>
  </div>
   </div>
  </div>
 </div>


<script>

var matrix=${[[(tanimoto[i][j] if i!=j else 0) for j in range(len(tanimoto[i]))] for i in range(len(tanimoto))]};
var title= ${json.dumps(nodes)|n};
var ann= ${json.dumps(A)|n};
var range = ["#000000", "#e3dfd3", "#93b8a9", "#4c7869", "#FFDD89", "#ba873f", "#5aa3bd", "#e34245",
             "#383535", "#d6a446", "#8596ab", "#b54536", "#13213b", "#b53f86", "#4a4948", "#8f332c",
             "#ed7e3d", "#8a728f", "#413f57",  "#e68384", "#e6eda4","#8bb056", "#cc3535", "#4ea7ad",
             "#f2a69e", "#8cc9b3", "#806667", "#3260ba", "#8a7c6e", "#f26671", "#583059", "#59280e",
             "#a17b55", "#b06e3f", "#558dad", "#e8e099", "#d9b571", "#cc9c82", "#73877b", "#995057",
             ];

</script>

</%block>


<%block name="getExtraContent">

getContent = function(d) {
  
  var content = "";
  
  png_url = "${request.application_url}"+"/images/compounds/"+d.name+".png"
  
  if (d.title!='') {
      var dt = d.title.toLowerCase().replace(' ','&nbsp;');
      content = "<h4>"+d.title+"</h4>" +'<p><a href=http://en.wikipedia.org/wiki/'+ dt +' target="_blank">Wikipedia</a>';
      url = 'http://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/'+d.title+'/property/MolecularFormula/JSON'
      content = content + "<p>Formula : "+ d.formula +                               
                "<p><img height=200px src='"+png_url+"' alt='[structure not found/available]'>"
                
      $('#part2').html(content);
   
      $.ajax({type: 'GET',
                url: url,
                success: function(json) { 
                      cid = json.PropertyTable.Properties[0].CID;
                      //mlf = json.PropertyTable.Properties[0].MolecularFormula;
                      // "<p><img height=200px src='http://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/"+d.title+"/PNG' alt='[structure not found/available]'>"+
                      pubchem = "http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid="+cid;
                      pubchem_assay = "http://pubchem.ncbi.nlm.nih.gov/assay/assay.cgi?cid="+cid;
                      content = content + "<p><a href="+pubchem+" target='_blank'>Pubchem</a>&nbsp;&nbsp;"+
                                "<a href="+pubchem_assay+" target='_blank'>Pubchem_BioAssay</a>"; 
                      if (d.actions!=''){
                        content = content +  "<p>Action : "+ d.actions 
                    }
                      d3.select('#part2').html(content);
     
                },
                error: function() {console.log("Not found :"+d.title);},
                dataType: 'json',
                async: true
            });
           
   }
  else  {
  
    content ="<p>Formula : "+ d.formula + "<p><img height=200px src='"+png_url+"' alt='[structure not found/available]'>"        
    d3.select('#part2').html(content);
  }
};



</%block>


<%block name="pagetail">
${parent.pagetail()} 


<script>

var chord = d3.layout.chord()
    .padding(.05)
    .sortSubgroups(d3.descending)
    .matrix(matrix);

var fill = d3.scale.ordinal()
    .domain(d3.range(6))
    .range(range);


var table = d3.select('#tanimoto_table').insert('table', ':first-child');
var thead = table.append('thead');
var tbody = table.append('tbody');

var valueCell = 1;
var maxNodes = 40;

var th = thead.selectAll("th")
    .data([ 'ID', 'Value', 'Formula', 'Mean', 'Name' ])
    .enter()
    .append("th")
    .text(function(d) { return d; });

var tr = tbody.selectAll('tr').data(chord.groups)


tr.enter()
    .append('tr');
  
if (title.length >= maxNodes) {

tr.style("color", function(d) {return 'black'; })
  .on("click", function(d) { 
       
       d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
       d3.selectAll('#tanimoto_table tbody tr').each(function(){
                 d3.select(this.cells[valueCell]).text('');} );

       d3.select(this).classed('selected','true');                                    
       tr = d3.selectAll('#tanimoto_table tbody tr')[0]; 
       var mx = matrix[d.index];
       mx[d.index] = 1.00;
                                
       d3.selectAll(tr).each(function(d,i) {  
       d3.select(this.cells[valueCell])
               .append("text")
                .text(mx[i].toFixed(2));   }); 

    });
} 
else {
tr.style("color", function(d) {return range[d.index]; })
  .on("mouseover", function(d) {
                           fade(d.index,.03)
                           d3.select(this).classed('selected','true');
                                           
                           tr = d3.selectAll('#tanimoto_table tbody tr')[0]; 
                           var mx = matrix[d.index];
                           mx[d.index] = 1.00;
                                
                          d3.selectAll(tr).each(function(d,i) {  
                             d3.select(this.cells[valueCell])
                                      .append("text")
                                      .text(mx[i].toFixed(2));   });})
                                      
    .on("mouseout", function(d) {fade(d.index,1);
                                  d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
                                  d3.selectAll('#tanimoto_table tbody tr').each(function(){
                                        d3.select(this.cells[valueCell]).text('');} ) })
    ;
}
var td = tr.selectAll('td')
    .data(function(d) {return [
      [ 'compound_id', ann[d.index].id],
      [ 'value',''],  
      [ 'formula', ann[d.index].formula ],
      [ 'mean', ann[d.index].mean.toFixed(2) ],  
      [ 'name', ann[d.index].name.toLowerCase()],
          
    ];})
    
    ;

td.enter()
    .append('td')
    .text(function(d) { return d[1]; })
    .attr('title', function(d) {return d[1];})
    ;
 
 
if (title.length < maxNodes) {
  var inr = 0.31;
  var dnm = 2.22;
  
  if (title.length>20) {inr=0.21; dnm=3;}


  var width = Math.min(200 +20 * title.length, 1050);
  var height = Math.min(200 +20 * title.length, 850);
  var innerRadius = Math.min(width, height) * inr;
  var outerRadius = innerRadius * 1.1;

  var svg = d3.select("#tanimoto_chord")
      .append("svg")
      .attr("width", width)
      .attr("height", height)
      .append("g")
      .attr("transform","translate(" + width / dnm + "," + height/dnm  + ")");

  svg.append("g")
        .selectAll("path")
        .data(chord.groups)
        .enter().append("path")
        .style("fill", function(d) { return fill(d.index); })
        .style("stroke", function(d) { return fill(d.index); })
        .attr("d", d3.svg.arc().innerRadius(innerRadius).outerRadius(outerRadius))
        .on("mouseover", function(d) {
                              fade(d.index,.03);
                              tr = d3.selectAll('#tanimoto_table tbody tr')[0][d.index];
                              d3.select(tr).classed('selected',true);
                                                            
                              tr = d3.selectAll('#tanimoto_table tbody tr')[0]; 
                              var mx = matrix[d.index];
                              mx[d.index] = 1.00;
                                
                              d3.selectAll(tr).each(function(d,i) {  
                                       d3.select(this.cells[valueCell])
                                         .append("text")
                                         .text(mx[i].toFixed(2));   });
                              
                              })
        .on("mouseout", function(d) {fade(d.index,1);
                                     d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
                                     d3.selectAll('#tanimoto_table tbody tr').each(function(){
                                        d3.select(this.cells[valueCell]).text('');}); 
        });

  svg.append("g")
        .attr("class", "chord")
        .selectAll("path")
        .data(chord.chords)
        .enter().append("path")
        .style("fill", function(d) { return fill(d.target.index);})
        .attr("d", d3.svg.chord().radius(innerRadius))
        .style("opacity", 1)
        .on("mouseover", function(d) {
                                  // highlight selected rows in table (source target)
                                  tr = d3.selectAll('#tanimoto_table tbody tr')[0][d.source.index];
                                  d3.select(tr).classed('selected',true);
                                  tr = d3.selectAll('#tanimoto_table tbody tr')[0][d.target.index];
                                  d3.select(tr).classed('selected',true);
                               
                                  //display value in table
                                  var idx = [d.source.index, d.target.index]
                                  var val = matrix[d.source.index][d.target.index].toFixed(2);
                                  
                                  tr = d3.selectAll('#tanimoto_table tbody tr.selected')[0];
                                  d3.selectAll(tr).each(function() { 
                                       d3.select(this.cells[valueCell])
                                         .append("text")
                                         .text(val);   });
   
                                  //highlight chord
                                  d3.selectAll('g.chord path').style('opacity',0.03); 
                                  d3.select(this).style('opacity', 1);})
                                      
        .on("mouseout", function() { d3.selectAll('g.chord path').style('opacity',1);
                                     d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
                                     d3.selectAll('#tanimoto_table tbody tr').each(function(){
                                                              d3.select(this.cells[valueCell]).text('');});  })
        .append("title")
        .text(function(d) { return title[d.source.index]+"-"+title[d.target.index]+" :  "+ d.source.value.toFixed(2) ; })
        ;
       
     
  if (title.length < 25) {
  
    var ticks = svg.append("g").selectAll("g")
      .data(chord.groups)
    .enter().append("g").selectAll("g")
      .data(groupTicks)
    .enter().append("g")
      .attr("transform", function(d) {
        return "rotate(" + (d.angle * 180 / Math.PI - 90) + ")"
            + "translate(" + outerRadius + ",0)";
      });

    ticks.append("line")
      .attr("x1", 1)
      .attr("y1", 0)
      .attr("x2", 5)
      .attr("y2", 0)
      .style("stroke", "#000");
 
    ticks.append("text")
      .attr("x", 8)
      .attr("dy", ".35em")
      .attr("transform", function(d) { return d.angle > Math.PI ? "rotate(180)translate(-16)" : null; })
      .style("text-anchor", function(d) { return d.angle > Math.PI ? "end" : null; })
      .text(function(d) { return d.label });
  }

}
// Returns an array of tick angles and labels, given a group.
 function groupTicks(d) {
   var k = (d.endAngle - d.startAngle) / d.value;
   return d3.range(0, d.value, 0.1).map(function(v, i) {
     return {
      angle: v * k + d.startAngle,
      label: i % 5 ? null : v.toFixed(1)
     };
   });
 }


function fade2(opacity) {
    return function(g, i) {
        svg.selectAll("g.chord path")
                .filter(function(d) {
                    return d.source.index != i && d.target.index != i;
                })
                .style("opacity", opacity);
    };
}

function fade(i, opacity) {
   svg.selectAll("g.chord path")
       .filter(function(d) {
           return d.source.index != i && d.target.index != i;
        })
      .style("opacity", opacity);
   
}

function highlightCompound(idx) {
  fade(idx,.03);
  tr = d3.selectAll('#tanimoto_table tbody tr')[0][idx];
  d3.select(tr).classed('selected',true);
  tr = d3.selectAll('#tanimoto_table tbody tr')[0]; 
  var mx = matrix[idx];
  mx[idx] = 1.00;
  d3.selectAll(tr).each(function(d,i) { 
       d3.select(this.cells[valueCell])
            .append("text")
            .text(mx[i].toFixed(2));   });
}


function highlightPairCompounds(idx1, idx2) {
 // highlight selected rows in table (source target)
  tr = d3.selectAll('#tanimoto_table tbody tr')[0][idx1];
  d3.select(tr).classed('selected',true);
  tr = d3.selectAll('#tanimoto_table tbody tr')[0][idx2];
  d3.select(tr).classed('selected',true);
                               
  //display value in table
  var idx = [idx1, idx2]
  var val = matrix[idx1][idx2].toFixed(2);
                                  
  tr = d3.selectAll('#tanimoto_table tbody tr.selected')[0];
  d3.selectAll(tr).each(function() { 
        d3.select(this.cells[valueCell])
           .append("text")
           .text(val);   });
   
 return (val);
}

function blendCompounds() {
  d3.selectAll('g.chord path').style('opacity',1);
  d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
  d3.selectAll('#tanimoto_table tbody tr').each(function(){d3.select(this.cells[valueCell]).text('');});  
}


var search1_entry = d3.select('#search1');
var search2_entry = d3.select('#search2');

var i1 = -1;
var i2 = -1; 

function showSearched (i1,i2){
  d3.select("#tanimoto-value").html('');
  blendCompounds();
  var val = '';
  if (i1!=-1 && i2!=-1) {val = highlightPairCompounds(i1, i2); }
  if (i1!=-1 && i2==-1) {highlightCompound(i1); }
  if (i1==-1 && i2!=-1) {highlightCompound(i2); }
  if (i1==-1 && i2==-1) { blendCompounds();}  
  d3.select("#tanimoto-value").html(val);

}

search1_entry.on('keypress', function() {
 i1 = title.indexOf(this.value);
 showSearched (i1,i2)
  
});

search2_entry.on('change', function() {
 i2 = title.indexOf(this.value);
 showSearched (i1,i2)
  
});




</script>

</%block>


