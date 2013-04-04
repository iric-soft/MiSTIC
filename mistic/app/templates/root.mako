
<%!
import json
import mistic.app.data as data

transforms = ('log', 'rank',  'none')
%>

<%inherit file="mistic:app/templates/base.mako"/>


<%block name="pagetitle">RNA-seq dataset explorer</%block>

<%block name="style">
${parent.style()}
</%block>


<%block name="pagecontent">
  <div class="container-fluid">
    <div class="row-fluid">
      <div class="span12">
<div style="text-align: center">
<div class="well" style="display: inline-block;">
<h2>Datasets</h2>
<hr>



<table id="datasets-table"  style="width:850px;">
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
        $('#datasets-table').dataTable( {  
                        "aoColumns": [null, null,  null, null, null, null]  ,   
                        "bSearch": [true, null, null, null, null, true]  ,
                        "bPaginate": false, 
                        "bSort":false,
                        "bProcessing": false
                      
                          });
      } );
      
  
      
      
</script>

</%block>
