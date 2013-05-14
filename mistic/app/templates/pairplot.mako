<%! import mistic.app.data as data %>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Multi-way scatterplot</%block>



<%block name="actions">
  ${parent.actions()}<button class="btn" id="static_url" href="">Static URL</button>
</%block>
<%block name="controls">

<div class="row-fluid">
<div class="span10" style="display:inline;">

  <form class="form-inline">
    <label for="datasets">Dataset:</label>
    <select id="datasets">
      <option value="">Select a dataset</option>
%for d in data.datasets.all():
      <option value="${d.id}">${d.name}</option>
%endfor
    </select>
    <span id="genelist"></span>
    <label for="gene">Gene:</label>
    <input type="text" id="gene"/> 	
   
   </form>
</div>	

    <div class="span2" id="advanced" >
   		<a id="advanced-options-link" class="dropdown-toggle" data-toggle="dropdown" href="#"> More options
    	<strong id="link-caret" class="caret"></strong> </a>
    </div>
</div>    	
 
 <div id="advanced-options">
    
    	<button class="btn btn-primary" id="show_labels">Show labels</button> 
    	<button class="btn btn-primary" data-toggle="button" id="select_clear">Select all</button>
    	<!--<button class="btn btn-primary" data-toggle="button" id="toggle_ids">Toggle IDs</button>-->
    </div>
  
 <div>  
    <label style="display:inline;" for="tag" size="10px">Locate:</label>
      <input type="text" id="tag" autocomplete="off"  />
   </div>

</%block>

<%block name="style">
${parent.style()}



a#advanced-options-link {
	float: right;	
	text-decoration : none;
	display: none;	
}

div#advanced-options {
  margin-top: 15px;
  display : none;
  float:right;
  
}
div#advanced_options .btn{
  font-size:11px;
}

div#graph text {
  pointer-events : none;
}



.circlelabel .invisible {
  pointer-events : none;
}

circle  {
  pointer-events : auto;
}


#link-caret {
	vertical-align: middle;
}



</%block>

<%block name="pagetail">
${parent.pagetail()}


<script src="${request.static_url('mistic:app/static/js/lib/scatterplot.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/pairplot.js')}" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function() {
  (function() {
    var opts = {};
    updateURLTarget = function(params) {
      _.extend(opts, params);
      if (opts.dataset !== null) {
        var url = "${request.route_url('mistic.template.pairplot_static', dataset='_dataset_', genes=[])}"
          .replace('_dataset_', opts.dataset);
        _.each(current_graph.data, function(x) { url += '/' + x.gene; });
        $('#static_url')
          .attr('disabled', false)
          .on('click.static_url', function() {
          window.location.href = url;
        });
      } else {
        $('#static_url')
          .attr('disabled', true)
          .off('click.static_url');
      }
    };
  })();
 
  current_graph = new pairplot(undefined, undefined, $('#graph'));

  current_dataset = undefined;

  var gene_entry = new GeneDropdown({ el: $("#gene") });
  
  $('body').on('click.remove', 'i.icon-remove-sign', function(event) {
    console.debug('badge');
    var badge = $(event.target).closest('span.badge');
    var badge_idx = parseInt(badge.attr('data-idx'));
    current_graph.removeData(function(d, i) { return i === badge_idx; });
    badge.remove();
    clearInformation();
  });

  gene_entry.on('change', function(item) {
    if (item === null) return;
    
    $.ajax({
      url: "${request.route_url('mistic.json.gene.expr', dataset='_dataset_', gene_id='_gene_id_')}".replace('_dataset_', current_dataset).replace('_gene_id_', item.id),
      dataype: 'json',
      success: function(data) {
        var gene_list = $('#genelist');
       
        
        current_graph.addData(data);
        gene_entry.$el.val('');
        var label = $('<span>')
          .addClass('badge')
          .css({ 'margin': '0px 5px' })	
          .attr({ 'data-idx': current_graph.data.length - 1 })
          .html(item.get('symbol') !== '' ? item.get('symbol') : item.id);
        label.append($('<i>')
          .addClass('icon-white icon-remove-sign')
          .css({ 'cursor': 'pointer', 'margin-right': -8, 'margin-left': 4 }));
        $('#genelist').append(label);
        updateURLTarget();
        if(current_graph.data.length>=2) {
          $("a#advanced-options-link").css('display', 'inline');
        }
      },
      error: function() {
        // inform the user something went wrong.
      }
    });
   
  });

  $('#datasets').on('change', function(event) {
    current_dataset = event.target.value;
    if (current_dataset === '') {
      current_dataset = null;
      gene_entry.url = null;
      $("#gene").attr('disabled', true);
      $("#tag").attr('disabled', true);
      
    } else {
     $("#gene").attr('disabled', false);
     $("#tag").attr('disabled', false);
      gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
    }
    gene_entry.$el.val('');

    $('#genelist').empty();
    current_graph.removeData(function() { return true; });
    updateURLTarget({ dataset: current_dataset });
  });

  $('#datasets').change();

  resizeGraph = function() {
    $('div#graph').height($(window).height() - 124);

    current_graph.resize(
      $('div#graph').width(),
      $('div#graph').height());
  };

  $('div#graph').append(current_graph.svg);

  resizeGraph();
  $(window).resize(resizeGraph);
  
  $('#show_labels').on("click", function(event){
  	d3.selectAll("text.circlelabel").classed('invisible', !d3.selectAll("text.circlelabel").classed('invisible'));
  	
  	if ($(this).text()=="Show labels"){
  		$(this).text("Clear labels");
  	}
  	else {
  		$(this).text("Show labels");
  	}
  	event.preventDefault();
  	
  });
  
  $('#select_clear').on('click', function(event) {
  
  	if (!d3.select(this).classed("active")){
  		d3.selectAll('circle').classed('highlighted', true);
  		var dat = [];
  		d3.selectAll('circle.highlighted').each(function(d) {
    		dat.push(d.k);
  		});
  		dat = _.uniq(dat);
  		_.each(dat, addInformation);
  		d3.select(this).text("Clear all");
  	}
  	else {
  		d3.selectAll('circle').classed('highlighted', false);
  		clearInformation();
  		d3.select(this).text("Select all");
  		
	  	}
	event.preventDefault();
	});
	
  $("#toggle_ids").on("click", function(event) {
     d3.selectAll('#text-symbol').classed('invisible', ! d3.selectAll('#text-symbol').classed('invisible'));
     d3.selectAll('#text-desc').classed('invisible', ! d3.selectAll('#text-desc').classed('invisible'));
  });
 
  $('#advanced-options-link').on('click', function(event) { 
 	$('#advanced-options').toggle();
 	event.preventDefault();
 	});
 		
  $('#tag').on('change', function(event){
  	var tag_entry = event.target.value.split(" ");
  	var circles = d3.selectAll('circle'); 
  	
  	var dat = [];
  	circles.each(function(d) { dat.push(d.k);});
  	dat = _.uniq(dat);
  	
  	search = function (list, regex) {
      return _.filter(list, function(obj){ return obj.match(regex);});
    };
  	tag_valid = _.flatten(_.map(tag_entry, function(item) {return search(dat, item);}  ));
  	
  	d3.selectAll('circle').classed('highlighted', false);
  	
	 circles.filter(function(d, i) {return (_.contains(tag_valid, d.k));})
			.classed('highlighted', !d3.select(this).classed('highlighted'));
	
	 clearInformation();
	 _.each(tag_valid, addInformation);
  	
  	
  	event.preventDefault();
  	
 	});
  
  
  	
  	


});
</script>
</%block>
