
<%!
import json
import mistic.app.data as data

terms = []
transforms = []

for ds in data.datasets.all():
  for k,v in ds.tags.iteritems():
    if k not in terms:
      terms.append(k)

  for t in ds.transforms:
   if t not in transforms:
     transforms.append(t)
%>

<%inherit file="mistic:app/templates/base.mako"/>


<%block name="pagetitle">RNA-seq dataset explorer</%block>

<%block name="style">
${parent.style()}

#datasets-table tbody tr:hover {
background-color:#DAD9DB;
cursor:pointer;
}

td.group {
  background-color: #EAE9E9; 
  text-align:left;
}
td.subgroup {
  background-color: #EAE9E9; 
  text-align:left;
  padding : 10px;
}

th { padding:0px;}

i {
float: left;
}

a#oo{
    text-decoration : none;
}

</%block>
<%block name="actions">
  <!--<button class="btn" id="csv-button">CSV</button>-->
</%block>


<%block name="pagecontent">

  <div class="container-fluid">
    <div class="row-fluid">
      <div class="span12">
      
<div style="text-align: center">
<div class="well" style="display: inline-block;">
<h2>Datasets</h2>
<h6>Click on a row to select the default log-transformed dataset or click on the desired data transformation</h6>
<hr>


<table id="datasets-table" style="width:850px;">
<thead>
<tr>
  <th>Dataset</th>
%for term in terms :
  <th><a><i class="icon-th-list"></a></i>${term}</th>
%endfor
<th>n</th>
<th>Icicle</th>
</tr>
</thead>

<tbody>
  %for ds in data.datasets.all() :
  <tr>
    <td>${ds.name}</td>
%for term in terms:
    <td>${ds.tags.get(term, '')}</td>
%endfor
    <td>${ds.numberSamples}</td>
    <td>
%for i, tf in enumerate(transforms):
  <span style="display: inline-block; width: 4em;">
  %if tf in ds.transforms:
      <a href="${request.route_url('mistic.template.clustering', dataset=ds.id, xform=tf)}">${tf}</a>
  %endif
  </span>
%endfor
    </td>
  </tr>
  %endfor
</tbody>
</table>
</div>


  
</%block>
<%block name="pagetail">
${parent.pagetail()}

<form id="csvform" target="_blank" method="post" action="${request.route_url('mistic.csv.root')}">
<input id="csvdata" type="hidden" name="csvdata" value=""></input></form>
 
<script type="text/javascript" charset="utf-8">


 $(document).ready(function() {
      var oTable = initTable();
});
    
function initTable() {
  var aoc = [null];
  var bsc = [true];
  for (var i=0; i<${len(terms)}; i++) {
    aoc.push(null);
    bsc.push(true);
  }
  aoc = aoc.concat([null, { "bSortable": false } ]);
  bsc = bsc.concat([true, false ]);
  
  return $('#datasets-table').dataTable({
    "aoColumns": aoc,
    "bSearch": bsc,
    "bPaginate": false, 
    "bSort":true,
    "bProcessing": false,
    "sDom": 'Rlfrtip',
    "bRetrieve":true,
  });
}

$('#datasets-table th a i').on('click', function(event) { 
    
    event.stopPropagation();
    var cell = this.parentElement.parentElement; 
    var cellContent = cell.innerHTML;
    var oTable = initTable();
      
    var alreadyActive = $(this).hasClass('icon-active');
    
    $('.icon-th-list').removeClass('icon-active');
    
    oTable = removeGrouping(oTable);  // utils.js
    oTable = setColReorder(oTable);  // utils.js
   
    if (alreadyActive) {
      oTable.fnDraw();
    }
    
    else {
    
      var j =-1;
      for (var i=0;i<oTable.fnSettings().aoColumns.length; i++) {
       if (oTable.fnSettings().aoColumns[i]['sTitle']==cellContent){
         j=i;
       }
     }
     j = j;
    
     $(this).addClass('icon-active');
    
     oTable = removeColReorder(oTable);  // utils.js
     
     oTable.rowGrouping({ iGroupingColumnIndex: j,
                          bExpandableGrouping: true, 
                          bHideGroupingColumn: false});
   
      } 
      
    });

$('#csv-button').on('click', function(event){
   
    $('#csvdata').val(tableToJSON($('#datasets-table')[0]));
    $('#csvform').submit();
     
});
      
$('#datasets-table tbody tr ').on('click', function(event){
    var values = _.map(this.cells, function(d){return(d.innerText);});
    
    var i = _.indexOf(values, 'log');
    if (i==-1) { i = _.indexOf(values, 'rank');} 
    else { if (i==-1) { i = _.indexOf(values, 'none');}} 
    
    var link = this.cells[i].innerHTML;
    window.open ($(link).attr("href"));
    
});
      
</script>

</%block>
