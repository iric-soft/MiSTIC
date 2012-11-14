<%!
import json
import mistic.app.data as data

transforms = ('log', 'rank', 'anscombe')
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
        <table>
<tr>
  <th></th>
  <th colspan="${len(transforms) * 4 - 2}">Transform</th>
</tr>
<tr>
  <th></th>
%for i, tf in enumerate(transforms):
%if i:
  <th>&nbsp;&nbsp;</th>
%endif
  <th colspan="2">${tf.capitalize()}</th>
%endfor
</tr>
%for ds in data.datasets.all():
<tr>
  <th>${ds.name}</th>
%for i, tf in enumerate(transforms):
%if i:
  <td>&nbsp;&nbsp;</td>
%endif
%if tf in ds.transforms:
  <td><a href="${request.route_url('mistic.template.clustering', dataset=ds.id, xform=tf)}">Icicle</a></td>
  <td><a href="${request.route_url('mistic.template.mstplot', dataset=ds.id, xform=tf)}">MST</a></td>
%else:
  <td></td>
  <td></td>
%endif
%endfor
</tr>
%endfor
</table>
</div>
</div>
      </div>
    </div>
  </div>
</%block>
<%block name="pagetail">
</script>
</%block>
