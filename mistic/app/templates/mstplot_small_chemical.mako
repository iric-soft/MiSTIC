<%!
import json
import mistic.app.data as data
import numpy
import pybel
%>

<%inherit file="mistic:app/templates/mstplot_small.mako"/>

<%block name="controls_buttons">
 ${parent.controls_buttons()}
 <div class='btn-group' style='border:1px solid #B8B8B8 ; border-radius:5px;padding:10px;'>
    <a id='tanimoto-button' href="#document-tanimoto" role="button" class="btn">Tanimoto</a>
  </div>
</%block>

<%block name="style2">

#tanimoto_table { 
  overflow-y: visible;
  overflow-x: hidden;
  font-family: helvetica; 
  font-size: 11px;    
 
}

#tanimoto_table  tr.selected {
  background-color: #d4c6ba;
  font-weight:bold;
}

#tanimoto_chord {
  overflow: hidden;
  padding-left:10px;
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
  border: 1px solid #999999;
  border: 1px solid rgba(0, 0, 0, 0.3);
  *border: 1px solid #999999;
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

#modal-tanimoto {
  width:800px;
}

#div-tanimoto input {
  width:100px;
  font-size:10.5px;
}

#tanimoto-value {
  font-size:10.5px;
}

</%block>

<%block name="subcontent">

 <div class="modal fade hide" id="modal-tanimoto" >
  <div class='modal-body'>
     <div class="row-fluid" id="div-tanimoto">
         <div class="span12" id="tanimoto_search" >
            <form class="form-inline">
                <input type="text" id="search1" placeholder="Enter Compound #1" >
                <input type="text" id="search2" placeholder="Enter Compound #2" >
                Tanimoto value = <span id="tanimoto-value">__</span>
                
            </form>
            
          </div> 
      </div>  <!-- close row-fluid -->

      <div class="row" >
        <div class="span4" id="tanimoto_table" ></div>
        <div class="span8" id="tanimoto_chord" ></div>
      </div> <!--close row-fluid -->
   </div><!--close modal-body-->
  </div><!--close modal-->


</%block>


<%block name="getExtraContent">

getContent = function(d) {

  var content = "";
  var part2 = $("#part2");
  part2.html('').append('<p><div class="accordion" id="info"></div>');
  
  var png_url = "${request.application_url}"+"/images/compounds/"+d.name+".png"
  var image = "<img height=200px src='"+png_url+"' alt='[structure not found/available]'>"
  c = '<ul id="links" class="source-links" style="padding:5px;"><li>GO TO : </li></ul>';
  $('#part2 > .accordion').append(getAccordionGroup('p0','0', d.title, image))
  $('#part2 > .accordion').append(getAccordionGroup('p1','1', 'Links', c))
  $('#part2 > .accordion').append(getAccordionGroup('p2','2', 'More', '<div id="more">Formula : '+ d.formula+'</div>'))
  
  if (d.title!='') {
      var dt = d.title.toLowerCase().replace(' ','&nbsp;');
      
      url = 'http://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/'+d.title+'/property/MolecularFormula/JSON'
      
       
      //$('#part2').html(content);
      
     
      var wlinks =  '<a href=http://en.wikipedia.org/wiki/'+ dt +' target="_blank"><strong>Wikipedia</strong></a>';
      $('#links').append('<li>'+wlinks+'</li>'); 
      
      $.ajax({type: 'GET',
                url: url,
                success: function(json) { 
                      cid = json.PropertyTable.Properties[0].CID;
                      //mlf = json.PropertyTable.Properties[0].MolecularFormula;
                      // "<p><img height=200px src='http://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/"+d.title+"/PNG' alt='[structure not found/available]'>"+
                      pubchem = "http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid="+cid;
                      pubchem_assay = "http://pubchem.ncbi.nlm.nih.gov/assay/assay.cgi?cid="+cid;
                      content = "<li><a href="+pubchem+" target='_blank'>Pubchem</a></li>"+
                                "<li><a href="+pubchem_assay+" target='_blank'>Pubchem_BioAssay</a></li>";
                      $('#links').append(content);
                      content = '' 
                      if (d.actions!=''){
                        content = "<p>Action : "+ d.actions 
                    }
                      $('#more').append(content); 
                      
                      
                },
                beforeSend : function() {
                    $("#a1 > .accordion-inner").append('<div id="loading"><img src="${request.application_url}/static/img/ajax-loader.gif"/> </div>');
                    $("#a2 > .accordion-inner").append('<div id="loading"><img src="${request.application_url}/static/img/ajax-loader.gif"/> </div>');
                },
                complete: function() {
                    $("div#loading").remove();
                },
                error: function() {console.log("Not found :"+d.title);},
                dataType: 'json',
                async: true
            });
           
   }
   else {
    $('#links').append('No available links');
   }
 
   $('.accordion-body:first').addClass('collapse in');
};



</%block>


<%block name="pagetail">
${parent.pagetail()} 


<%
  ds = data.datasets.get(dataset)
  a = ds.annotation
  molecules = []
  moleculeNames = []
  names = {}

  for n in nodes: 
   
    try:
      molecules.append(pybel.readstring( 'smi', str(a.data.ix[n].get('smi', {}))))
      moleculeNames.append(n)
    except:
      pass
          
  tanimoto =  [[mol1.calcfp() | mol2.calcfp() for mol1 in molecules] for mol2 in molecules]
  
  d = dict(zip(moleculeNames, tanimoto))
  d.update({'header': nodes})
  tanimoto_tab = d 
  
 
  A = [ dict(
    id    = n,
    name  = a.data.ix[n].get('name', n) or '',
    #formula = a.attrs.get(n, {}).get('formula') or '',
    #can = a.attrs.get(n, {}).get('can') or '',
    #smile = a.attrs.get(n, {}).get('smi') or '',
    index = moleculeNames.index(n),
    mean = numpy.mean(tanimoto[moleculeNames.index(n)]),
    sum = numpy.sum(tanimoto[moleculeNames.index(n)]),
    ) for n in nodes if n in tanimoto_tab.keys()]
  
%>


<script>

var matrix=${[[(tanimoto[i][j] if i!=j else 0) for j in range(len(tanimoto[i]))] for i in range(len(tanimoto))]};
var title= ${json.dumps(nodes)|n};
var ann= ${json.dumps(A)|n};
var range = ["#000000", "#e3dfd3", "#93b8a9", "#4c7869", "#FFDD89", "#ba873f", "#5aa3bd", "#e34245",
             "#383535", "#d6a446", "#8596ab", "#b54536", "#13213b", "#b53f86", "#4a4948", "#8f332c",
             "#ed7e3d", "#8a728f", "#413f57",  "#e68384", "#e6eda4","#8bb056", "#cc3535", "#4ea7ad",
             "#f2a69e", "#8cc9b3", "#806667", "#3260ba", "#8a7c6e", "#f26671", "#583059", "#59280e",
             "#a17b55", "#b06e3f", "#558dad", "#e8e099", "#d9b571", "#cc9c82", "#73877b", "#995057"
             ];

</script>



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
    .data([ 'ID', 'Value', 'Mean', 'Name' ])
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
      //[ 'formula', ann[d.index].formula ],
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
  console.debug(width);
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
      .style("stroke", "#000000");
 
    ticks.append("text")
      .attr("x", 8)
      .attr("dy", ".35em")
      .attr("transform", function(d) { return d.angle > Math.PI ? "rotate(180)translate(-16)" : null; })
      .style("text-anchor", function(d) { return d.angle > Math.PI ? "end" : null; })
      .text(function(d) { return d.label });
  }
}
else {
    $("#tanimoto_chord").html('Chord is to big and will not be displayed.  Click on the ID in the table or use the form above to get information');

    
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
$("#modal-tanimoto").modal({keyboard : true, backdrop: true , show:false});

$('#tanimoto-button').on('click', function(){
    $('#modal-tanimoto').modal('toggle')
});

</script>

</%block>


