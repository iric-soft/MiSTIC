
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


<table id="datasets-table">
<thead>
<tr>
  <th>Dataset</th>
%for term in terms :
  <th><a class="unicode-icon group-data">&#x2630</a> ${term}</th>

%endfor
<th>n</th>
<th>Icicle</th>
<th></th>
</tr>
</thead>

<tbody>
  %for ds in data.datasets.all() :
  <tr>
    <td>${ds.name}<a style='float:right;' class="unicode-icon description" title='Click here to know more about the dataset' data-id=${ds.id}>&#8230</a></td>
%for term in terms:
    <td>${ds.tags.get(term, '')}</td>
%endfor
    <td>${ds.numberSamples}</td>
    <td>
      <div class="btn-group">
%for tf in transforms:
  %if tf in ds.transforms:
        <a class="btn btn-small icicle-link" target="_blank" href="${request.route_url('mistic.template.clustering', dataset=ds.id, xform=tf)}">${tf}</a>
  %endif
%endfor
      </div>
    </td>
    <td class='td_add_favorite'>
      <a class="unicode-icon add_favorite" title='Click here to select your favorite datasets'><span class="dummy" id="dummy" style="display:none">a</span>&#x2736</a>
    </td>
  </tr>
  %endfor
</tbody>
</table>
</div>


<div id='description-modal' class="modal hide" tabindex="-1" role="dialog">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
    <div id='description-modal-title'><h4></h4></div>
  </div>
  <div id='description-modal-body' class="modal-body">

  </div>

</div>



</%block>
<%block name="pagetail">
${parent.pagetail()}

<%

dat = [dict([(k, ds.__dict__[k]) for k in ds.__dict__.keys() if isinstance(ds.__dict__[k], str) and '/' not in ds.__dict__[k]]) for ds in data.datasets.all()]

%>


<form id="csvform" target="_blank" method="post" action="${request.route_url('mistic.csv.root')}">
<input id="csvdata" type="hidden" name="csvdata" value=""></input></form>

<script type="text/javascript" charset="utf-8">
require(["jquery", "utils"], function($, utils) {

    require(["dt_plugins"]);

    var dat = ${json.dumps(dat)|n};

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
        aoc = aoc.concat([null, { "bSortable": false }, { "bSortable": true , "sType": "html"}]);
        bsc = bsc.concat([true, false, false ]);
        var n = bsc.length-1;

        return $('#datasets-table').dataTable({
            "aoColumns": aoc,
            "bSearch": bsc,
            "bPaginate": false,
            "bSort":true,
            "bProcessing": false,
            "sDom": 'Rlfrtip',
            "bRetrieve":true,
            "aaSorting": [[n, 'asc'],[0,'asc']],
        });
    }

    $('#datasets-table th a ').on('click', function(event) {
        event.stopPropagation();
        var cell = this.parentElement;
        var cellContent = cell.innerHTML;
        var oTable = initTable();

        var alreadyActive = $(this).hasClass('active');

        $('.group-data').removeClass('active');

        oTable = utils.table.removeGrouping(oTable);
        oTable = utils.table.setColReorder(oTable);

        if (alreadyActive) {
            oTable.fnDraw();
        } else {
            var j =-1;
            for (var i=0;i<oTable.fnSettings().aoColumns.length; i++) {
                if (oTable.fnSettings().aoColumns[i]['sTitle']==cellContent) {
                    j=i;
                }
            }
            j = j;

            $(this).addClass('active');

            oTable = utils.table.removeColReorder(oTable);  // utils.js

            oTable.rowGrouping({
                iGroupingColumnIndex: j,
                bExpandableGrouping: true,
                bHideGroupingColumn: false
            });
        }
    });

    $('#csv-button').on('click', function(event) {
        $('#csvdata').val(utils.table.toJSON($('#datasets-table')[0]));
        $('#csvform').submit();
    });

    $('#datasets-table tbody td button').on('click', function(event) {
        return false;
    });

    $('#datasets-table tbody td').on('click', function(event) {
        if ($(this).find('.icicle-link').length > 1) return;
        if ($(this).hasClass('td_add_favorite')) return;

        var tr = $(this).parents('tr');
        var link = $(tr).find('span > a')[0];
        window.open($(link).attr("href"));
    });

    var favorites = utils.cookie.get('favorite_datasets');

    $('.td_add_favorite').on('click', function(event) {
        event.stopPropagation();
        event.preventDefault();
        var favorite_dataset = $(this).parents('tr').find('td')[0].innerText;
        var ix = favorites.indexOf(favorite_dataset);

        if (ix ==-1) {
            favorites.push (favorite_dataset);
        } else {
            favorites.splice(ix, 1);
        }
        manageFavorites();
        utils.cookie.set('favorite_datasets', favorites);
    });

    $('.description' ).on('click', function(event) {
        event.stopPropagation();
        event.preventDefault();
        d = _.where(dat, {'id': $(this).data('id')})[0];
        $('#description-modal-title > h4').html(d.name);
        $('#description-modal-body').html(d.description);
        $('#description-modal').modal('show')
    });


    var manageFavorites = function () {
        var oTable = initTable();

        _.each($('.add_favorite'), function(a) {
            var tr =  $(a).parents('tr');
            var td  = tr.find('td')[0]
            var txt = td.innerText;

            $(a).removeClass('active');
            $(a).find('span#dummy').text('');
            var a_td = $(a).parents('td')[0];
            var h_td = a_td.innerHTML;
            pos = oTable.fnGetPosition(a_td);

            if (favorites.indexOf(txt)!= -1) {
                $(a).addClass('active');
                $(a).find('span#dummy').text('a');
                a_td = $(a).parents('td')[0];
                h_td = a_td.innerHTML;
            }
            oTable.fnUpdate(h_td, pos[0], pos[1], true, false)
        });
    };

    manageFavorites();
});
</script>

</%block>
