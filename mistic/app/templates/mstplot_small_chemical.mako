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
  border : 1px solid black;
    
}

tr.selected {
  background-color: #cc7400;
  color: #fff;
}

#document-tanimoto { 
  padding-top: 45px;
    
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
  background-color: #cc7400;
}



#part2 {
  overflow-y: hidden;
  overflow-x: hidden;
  font-family: helvetica; 
  font-size: 10.5px; 

}

.modal {
  position: fixed;
  top: 50%;
  left: 50%;
  z-index: 1050;
  width: 860px;
  margin: -250px 0 0 -280px;
  overflow: auto;
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
  max-height: 800px;
  padding: 15px;
  overflow-y: auto;
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
    formula = a.attrs.get(n, {}).get('formula') or '',
    can = a.attrs.get(n, {}).get('can') or '',
    smile = a.attrs.get(n, {}).get('smi') or '',
    index = nodes.index(n),
    mean = numpy.mean(tanimoto[nodes.index(n)]),
    sum = numpy.sum(tanimoto[nodes.index(n)]),
  ) for n in nodes ]
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
     

<!--<div class="row-fluid" id="document-tanimoto">

   <div  class='span6' id="tanimoto_table-tmp">
    <table><thead>
   
    <tr><th></th>
    %for r in tanimoto_tab['header'] : 
      <th>  </th>
    %endfor
    <th>Mean</th>
    <th>Name</th>
    <th>Formula</th>
    </tr>
     
    </thead><tbody>
    %for i in range(0,len(tanimoto_tab['header'])):
      <%  k = tanimoto_tab['header'][i]   %>
      <tr><td>${k}</td>
      
      %for j in range(0,len(tanimoto_tab[k])) :
          //<% v= "%0.2f"%tanimoto_tab[k][j] %>  
          <% v = "%0.2f"%tanimoto_tab[k][j] if j>=i else '' %>
          <td>${v}</td>
      %endfor 
       <td> ${"%0.2f"%(numpy.mean(tanimoto_tab[k])) } </td>
       <td> ${str(a.attrs.get(k, {}).get('name')).lower()} </td>
       <td> ${str(a.attrs.get(k, {}).get('formula'))} </td>
      </tr>  
     %endfor    
     </tbody> 
     </table>
   </div>

  <div class="row-fluid" id="document-tanimoto">
    <div class="span5" id="tanimoto_table" ></div>
    <div class="span7" id="tanimoto_chord" ></div>
  </div>
  
//-->

 <div class="modal hide fade" id="document-tanimoto">
  <div class='modal-body'>
     <div class="row-fluid" id="document-tanimoto">
    <div class="span6" id="tanimoto_table" ></div>
    <div class="span6" id="tanimoto_chord" ></div>
  </div>
   </div>
  </div>
 </div>




<script>

var matrix=${[[(tanimoto[i][j] if i!=j else 0) for j in range(len(tanimoto[i]))] for i in range(len(tanimoto))]};
var title= ${json.dumps(nodes)|n};
var ann= ${json.dumps(A)|n};
var range = ["#000000", "#33585e", "#957244", "#F26223", "#155420","#FFDD89", "#957244", "#F26223"];

</script>

</%block>


<%block name="popover_creation">

getContent = function(d) {
  
  var content = "";
  
  png_url = "${request.application_url}"+"/images/compounds/"+d.name+".png"
  
  if (d.title!='') {
      var dt = d.title.toLowerCase().replace(' ','&nbsp;');
      content = "<h4>"+d.title+"</h4>" +'<p><a href=http://en.wikipedia.org/wiki/'+ dt +' target="_blank">Wikipedia</a>';
      url = 'http://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/'+d.title+'/property/MolecularFormula/JSON'
     
      $('#part2').html(content);
      
      $.ajax({type: 'GET',
                url: url,
                success: function(json) { 
                      cid = json.PropertyTable.Properties[0].CID;
                      //mlf = json.PropertyTable.Properties[0].MolecularFormula;
                      // "<p><img height=200px src='http://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/"+d.title+"/PNG' alt='[structure not found/available]'>"+
                      pubchem = "http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid="+cid;
                      pubchem_assay = "http://pubchem.ncbi.nlm.nih.gov/assay/assay.cgi?cid="+cid;
                      
                    
                      content = "<p><a href="+pubchem+" target='_blank'>Pubchem</a>&nbsp;&nbsp;"+
                                "<a href="+pubchem_assay+" target='_blank'>Pubchem_BioAssay</a>"+
                                "<p>Formula : "+ d.formula +
                               
                                "<p><img height=200px src='"+png_url+"' alt='[structure not found/available]'>"
                                
                                            
                      ; 
                      if (d.actions!=''){
                        content = content +  "<p>Action : "+ d.actions 
                    }
              
                      pop = $('div#more-information a:contains('+d.name+')').data('popover')
                      pop.options.content =  pop.options.content + content;
                      
                      $('#part2').append(content);
                      
                      
                },
                error: function() {console.log("Not found :"+d.title);},
                dataType: 'json',
                async: true
            });
   }
  else  {
   
   content ="<p>Formula : "+ d.formula + "<p><img height=200px src='"+png_url+"' alt='[structure not found/available]'>"
             
   $('#part2').html(content);
  }
  return (content);
};

hideMore = function() {
 
  $('div#more-information a').popover('hide');
  d3.select('#part2').html('');
  return false;
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


var th = thead.selectAll("th")
    .data([ 'ID', 'Name', 'Formula', 'Sum', 'Mean', 'Value' ])
    .enter()
    .append("th")
    .text(function(d) { return d; });

var tr = tbody.selectAll('tr').data(chord.groups)

tr.enter()
    .append('tr')
    .style("color", function(d) {return range[d.index]; })
    .on("mouseover", function(d) {
                           fade(d,.03)
                           d3.select(this).classed('selected','true');
                                           
                           tr = d3.selectAll('#tanimoto_table tbody tr')[0]; 
                           var mx = matrix[d.index];
                           mx[d.index] = 1.00;
                                
                          d3.selectAll(tr).each(function(d,i) {  
                             d3.select(this.cells[5])
                                      .append("text")
                                      .text(mx[i].toFixed(2));   });})
                                      
    .on("mouseout", function(d) {fade(d,1);
                                  d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
                                     d3.selectAll('#tanimoto_table tbody tr').each(function(){
                                        d3.select(this.cells[5]).text('');} ) })
    ;

var td = tr.selectAll('td')
    .data(function(d) {return [
      [ 'compound_id', ann[d.index].id],
      [ 'name', ann[d.index].name.toLowerCase()],
      [ 'formula', ann[d.index].formula ],
      [ 'sum', ann[d.index].sum.toFixed(2) ],   
      [ 'mean', ann[d.index].mean.toFixed(2) ],  
      [ 'value',''],      
    ];})
    ;

td.enter()
    .append('td')
    .text(function(d) { return d[1]; })
  
    //.attr('title', function(d) {return d[1];})
    ;
 

var width = 300+20*title.length;
var height = 300 +20 * title.length;
var innerRadius = Math.min(width, height) * .31;
var outerRadius = innerRadius * 1.1;


var svg = d3.select("#tanimoto_chord")
     .append("svg")
     .attr("width", width)
     .attr("height", height)
     .append("g")
     .attr("transform","translate(" + width / 2 + "," + height/2.25  + ")");

svg.append("g")
        .selectAll("path")
        .data(chord.groups)
        .enter().append("path")
        .style("fill", function(d) { return fill(d.index); })
        .style("stroke", function(d) { return fill(d.index); })
        .attr("d", d3.svg.arc().innerRadius(innerRadius).outerRadius(outerRadius))
        .on("mouseover", function(d) {
                              fade(d,.03);
                              tr = d3.selectAll('#tanimoto_table tbody tr')[0][d.index];
                              d3.select(tr).classed('selected',true);
                                                            
                              tr = d3.selectAll('#tanimoto_table tbody tr')[0]; 
                              var mx = matrix[d.index];
                              mx[d.index] = 1.00;
                                
                              d3.selectAll(tr).each(function(d,i) {  
                                       d3.select(this.cells[5])
                                         .append("text")
                                         .text(mx[i].toFixed(2));   });
                              
                              })
        .on("mouseout", function(d) {fade( d,1);
                                     d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
                                     d3.selectAll('#tanimoto_table tbody tr').each(function(){
                                        d3.select(this.cells[5]).text('');}); 
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
                                       d3.select(this.cells[5])
                                         .append("text")
                                         .text(val);   });
   
                                  //highlight chord
                                  d3.selectAll('g.chord path').style('opacity',0.03); 
                                  d3.select(this).style('opacity', 1);})
                                      
        .on("mouseout", function() { d3.selectAll('g.chord path').style('opacity',1);
                                     d3.selectAll('#tanimoto_table tbody tr').classed('selected',false);
                                     d3.selectAll('#tanimoto_table tbody tr').each(function(){
                                                              d3.select(this.cells[5]).text('');});  })
        .append("title")
        .text(function(d) { return title[d.source.index]+"-"+title[d.target.index]+" :  "+ d.source.value.toFixed(2) ; })
        ;
       
      
//svg.selectAll("text")
//        .data(chord.groups)
//        .enter()
//        .append("text")
//        .text(function(d) { return title[d.index]+" "+ann[d.index].name+" " ;  })
//        .attr("x", function(d) { return -width/2+10; })
//        .attr("y", function(d) { return -height / 2 + 20*(d.index+1);  })
//       .attr("font-size", "11px")
//        .attr("fill", function(d) {return range[d.index]; })
//        .on("mouseover", fade(.03))
//        .on("mouseout", fade(1));
        


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

function fade(d, opacity) {
   var i = d.index;
   svg.selectAll("g.chord path")
       .filter(function(d) {
           return d.source.index != i && d.target.index != i;
        })
      .style("opacity", opacity);
   
}



</script>

</%block>


