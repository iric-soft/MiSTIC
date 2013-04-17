
<%!
import json
import mistic.app.data as data
terms = []
dds = {}
for ds in data.datasets.all() : 
  terms += [term.split("=")[0].strip() for term in ds.tags.split(";")]
  dds[ds.name] = dict([(term.split('=')[0].strip(), term.split('=')[1].strip()) for term in ds.tags.split(';')]) 
  
terms = reduce(lambda x, y: x if y in x else x + [y], terms, [])

#transforms = ('log', 'rank',  'none')
transforms = ['log']
%>

<%inherit file="mistic:app/templates/base.mako"/>


<%block name="pagetitle">RNA-seq dataset explorer</%block>

<%block name="style">
${parent.style()}

td.group {
  background-color: grey; 
  text-align:left;
}
td.subgroup {
  background-color: grey; 
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

<%block name="pagecontent">

  <div class="container-fluid">
    <div class="row-fluid">
      <div class="span12">
      
<div style="text-align: center">
<div class="well" style="display: inline-block;">
<h2>Datasets</h2>
<hr>


<table id="datasets-table" style="width:850px;">
<thead>
<tr>
%for term in terms :
  <th><a><i class="icon-th-list"></a></i>${term}</th>
%endfor
<th>n<th>
<th><th>
</tr>
</thead>

<tbody>
  %for ds in data.datasets.all() :
  <tr>
   %for term in terms :
    <td>${dds[ds.name].get(term, '')}</th>
   %endfor
   <td>${ds.numberSamples}</td>
    <td><a href="${request.route_url('mistic.template.clustering', dataset=ds.id, xform='log')}">Icicle</a></td>
   
  </tr>
  %endfor
</table>



<table id="datasets-table-2"  style="width:850px; display:none;">
<thead>
<tr>
  
  <th></th>
  <th></th>
  <th colspan="${len(transforms) * 1 }">Transformed data type</th>
  <th></th>
</tr>
<tr>
 <th></th>
 <th>n</th>

%for i, tf in enumerate(transforms):
  <th colspan="1">${tf.capitalize()}</th>
%endfor
 <th></th>
</tr>
</thead>


<tbody>
  %for ds in data.datasets.all() :
  
  <tr>
    
    <th>${ds.name}</th>
    <th>${ds.numberSamples}</th>
  %for i, tf in enumerate(transforms):
  
  
  %if tf in ds.transforms:
    
    <td><a href="${request.route_url('mistic.template.clustering', dataset=ds.id, xform=tf)}">Icicle</a></td>
    <!--<td><a href="${request.route_url('mistic.template.mstplot', dataset=ds.id, xform=tf)}">MST</a></td> -->
  %else:
     <!--<td></td> -->
    <td></td>
  %endif
  %endfor
  <td>${ds.tags}</td>
  </tr>
  %endfor
 
</tbody>
</table>

</div>
</div>
      </div>
    </div>
  
  </div>
  
  
</%block>
<%block name="pagetail">
${parent.pagetail()}

<script type="text/javascript" charset="utf-8">
    $(document).ready(function() {
    
      var oTable = initTable();
  
    });
    
  function initTable() {
        var aoc = new Array();
        var bsc = new Array();
        for (var i=0; i<${len(terms)}; i++) {
            aoc.push(null);
            bsc.push(true);
        }
        aoc = aoc.concat([null, null]);
        bsc = bsc.concat([true, null]);
  
       
        return $('#datasets-table').dataTable( {  
                        "aoColumns": aoc  ,   
                        "bSearch": bsc  ,
                        "bPaginate": false, 
                        "bSort":true,
                        "bProcessing": false ,
                        "sDom": "Rlfrtip",
                        "bRetrieve":true
                      });    
  }    
  
$('#datasets-table th a i').on('click', function(event) { 
    
    event.stopPropagation();
    var cell = this.parentElement.parentElement; 
    var cellContent = cell.innerHTML;
    var oTable = initTable();
      
    var j =-1;
    for (var i=0;i<oTable.fnSettings().aoColumns.length; i++) {
      if (oTable.fnSettings().aoColumns[i]['sTitle']==cellContent){
        j=i;
      }
    }
    j = j;
   
    $('.icon-th-list').removeClass('icon-active');
    $(this).addClass('icon-active');
  
    oTable.fnSettings().sDom = "";
    oTable.fnSettings().oInstance._oPluginColReorder.s['allowReorder']= false;
     
    oTable.rowGrouping({ iGroupingColumnIndex: j,
                         bExpandableGrouping: true, 
                         bHideGroupingColumn: false});
   
    
    });

      
</script>

</%block>
