<%! 
import mistic.app.data as data 
import json
%>

<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">Multi-way scatterplot</%block>

<%block name="actions">
  ${parent.actions()} 
   <a id="share_url" href="#link_to_share" role="button" class="btn" data-toggle="modal">Link to share</a>
</%block>

<%block name="controls">

<% 
   ds = data.datasets.get(dataset)
%>


<div class="row-fluid">
   <div id="menu" class="span12"  >

      <form class="form-inline">
     
        <div class="accordion" id="accordion">
            <div class="accordion-group">        
              <div class="accordion-heading">
                <h4 class="accordion-title">
                  <a class="accordion-toggle" data-toggle="collapse"  href="#dataset_menu">Datasets <div id="nb_datasets" class='text-info' style='display:inline;'>(0)</div></a>
                </h4>
              </div>
       
              <div id="dataset_menu" class="accordion-body collapse in">
                <div class="accordion-inner">
                  
                 
                  
                  <select id="datasets">
                    <option value="">Select a dataset</option>
                    %for d in data.datasets.all():
                      <option value="${d.id}">${d.name}</option>
                    %endfor
                 </select>
                 
              </div>
            </div>
          </div>
     
          <div class="accordion-group">        
            <div class="accordion-heading">
               <h4 class="accordion-title">
                  <a class="accordion-toggle" data-toggle="collapse"  href="#gene_menu">Genes <div id="nb_genes" class='text-info' style='display:inline;'>(0)</div></a>
               </h4>
            </div>
    
            <div id="gene_menu" class="accordion-body collapse ">
              <div class="accordion-inner">
      
                  <label for="gene">Select a gene :</label>
                  <input type="text" id="gene" autocomplete="off"/> <br>	
      
                  <span id="genelist"></span>
              </div>
            </div>
          </div>
    
        <div class="accordion-group">        
           <div class="accordion-heading">
             <h4 class="accordion-title">
                <a class="accordion-toggle" data-toggle="collapse"  href="#sample_menu">Samples 
                <div id="nb_samples" class='text-info' style='display:inline;'>(0)</div></a>
            </h4>
       </div>
    
      <div id="sample_menu" class="accordion-body collapse in ">  
        <div class="accordion-inner">
          
        
          <h5><a class="accordion-toggle" data-toggle="collapse"  href="#current_selection">Selected samples</a></h5>
          <div id="current_selection" class="accordion-body collapse in ">
          
          %for i in range(0,4) :
            <br>
            <label style="display:inline;" for="highlighted${i}" size="8px">
            
           
            <svg height='10' width="10">
            <rect id="spectrum${i}" width="10" height="10" class="highlighted${i} color${i}" />
                
            </label>
            <input type="text" class="locate" id="highlighted${i}" autocomplete="off" data-index='${i}' />
            <div style="display:inline;">
              <i id="add${i}" class="icon-plus "></i>
              <i id="minus${i}" class="icon-minus "></i>
              <i id="remove${i}" class="icon-remove"></i>
              <i id="tograph${i}" class="icon-share-alt"></i>
             
            </div>
            
          %endfor
          
          </div>
          
          <hr>
          
              <select id="sample_selection" >
                <option selected value="none">Select by characteristic</option>
              </select>

        </div> 
      </div>
   
    </div> 
       
     <div class="accordion-group">        
       <div class="accordion-heading">
         <h4 class="accordion-title">
         <a class="accordion-toggle" data-toggle="collapse"  href="#options_menu">More options </a>
         </h4>
       </div>
    
      <div id="options_menu" class="accordion-body collapse ">  
        <div class="accordion-inner">
           <ul id="options" class="nav nav-list">
            <li><a id='show_labels'  href="#">Show labels</a></li>
            <li><a id='select_clear' href="#">Select all</a></li>
            <li class="divider"></li>
            <li><a id="change_axes"  href="#">Change axes</a></li>
          </ul>
        </div> 
      </div>
    </div>
    </div>
       
  </div>	
</div>
  
</form>
  
</%block>

<%block name="graph">
 ${parent.graph()}
 
  <div class="modal hide" id="link_to_share">
  <div class='modal-body'>
  <span id="share"></span>
  </div> 
 </div>  

</%block>

<%block name="style">
${parent.style()}



</%block>

<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/scatterplot.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/pairplot.js')}" type="text/javascript"></script>

<script type="text/javascript">
$(document).ready(function() {
  
  var highlights= new Object();
   
   for (i = 0; i < 4; ++i)  {
    
    highlights['highlighted'+i] = {'fill':$("rect#spectrum"+i).css('fill'), 'stroke':$("rect#spectrum"+i+"-stroke").css('stroke')};

   _.each($("[id ^='spectrum_i']".replace('_i', i)), function(event){ 
   
        $(event).spectrum({
            showButtons: false,
            showRadio: true,
          
            change : function(event){
              var newColor = event.toHexString(); 
              var classes = $(this).attr('class').split(' '); 
              var id = this.id;
              var to = $(this).data().applyTo;
              
              var highlight = classes[0];
              if (classes.length>1) {              
                 var cssColor = classes[1];
                 d3.select(this).classed(cssColor,false);
              }
              
              if (to=='stroke'){
                d3.select(this).attr('stroke', newColor);
                d3.select(this).attr('stroke-width', '4px' );
                d3.select(this).attr('fill', 'white');
                
                highlights[highlight]['stroke']=newColor;
                highlights[highlight]['fill']=undefined;
                
              
              }
              else {
                d3.select(this).attr('stroke', null);
                d3.select(this).attr('stroke-width',null );
                d3.select(this).attr('fill', newColor);
                
                highlights[highlight]['fill']=newColor;
                highlights[highlight]['stroke']=undefined;
              }
              
              $('.locate').change();
          }
    });
   });
   
   
  }

  
  var gene_entry = new GeneDropdown({ el: $("#gene") });
  current_graph = new pairplot(undefined, undefined, $('#graph'));
  $("#options").css('display', 'none');
  
   <%  
   ds = data.datasets.get(dataset)
   gene_data = [ds.expndata(gene) for gene in genes ]
   
  %>
  
  %if not ds==None:
    current_dataset = "${dataset}"; 
    $('#datasets').val(current_dataset);
   
    gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
    $("#nb_datasets").text('(1)');
    
   
  %else:
    current_dataset = undefined;
    gene_entry.url = null;
  
    $("#gene").attr('disabled', true);
    $("#tag").attr('disabled', true);
  %endif
  

  //  Gene symbols were passed in the URL
  %if len(genes)>0:
    $("#nb_genes").text('(${len(genes)})');
    %for g in genes:      
      // Selecting the first item corresponding to the gene symbol (no validation)
      gene = ${json.dumps(g)|n};
      gene_entry.$el.val(gene).select();
    
    %endfor
  %endif 
  
  
  

  $("#share_url").on('click', function(event){
   
    var url = "${request.route_url('mistic.template.pairplot', dataset='_dataset_', genes=[])}"
              .replace('_dataset_', current_dataset);
         
    if (current_graph.data.length>0){
        _.each(current_graph.data, function(x) { url += '/' + x.gene;console.debug(x.gene); });
    }
    $("span#share").html(url);
  });
  
  
  var minimal_axes = false;
  $('#change_axes').on('click', function(event){  
      minimal_axes = !minimal_axes;
      current_graph.setMinimalAxes(minimal_axes);
      current_graph.draw()
     
   });  
  
  $('body').on('click.remove', 'i.icon-remove-sign', function(event) {
    
    var badge = $(event.target).closest('span.badge');
    var badge_idx = parseInt(badge.attr('data-idx'));
    
    current_graph.removeData(function(d, i) { return i === badge_idx; });
    badge.remove();
    
    var badges = d3.selectAll('.badge');
    badges.each (function(d,i) {d3.select(this).attr('data-idx',i);});
    if (current_graph.data.length<2) { 
        $("#options").css('display', 'none');
    }
    clearInformation();
    $("#nb_genes").text('('+current_graph.data.length+')');
    $('.locate').change();
  });


  gene_entry.on('change', function(item) {
        
    if (item === null) return;
    
    $.ajax({
      url: "${request.route_url('mistic.json.gene.expr', dataset='_dataset_', gene_id='_gene_id_')}".replace('_dataset_', current_dataset).replace('_gene_id_', item.id),
      dataype: 'json',
      success: function(data) {
       
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
       
        $("#nb_genes").text('('+current_graph.data.length+')');
        if(current_graph.data.length>=2) {
          $("#options").css('display', 'inline');
         
        }
        $('.locate').change();
      },
      error: function() {
        // inform the user something went wrong.
      }
    });
   
  });

  

  $('#datasets').on('change custom', function(event) {
   
    current_dataset = event.target.value;
    
    if (current_dataset === '') {
      current_dataset = null;
      gene_entry.url = null;
      
      $("#gene").attr('disabled', true);
      $(".locate").attr('disabled', true);
      $("#nb_datasets").text('(0)');
      $("#nb_genes").text('(0)');
      $("#nb_samples").text('(0)');
      $('#sample_selection').html('<option selected value="none">Select a characteristic</option>');
    
     
    } else {
     $("#gene").attr('disabled', false);
     $(".locate").attr('disabled', false);
     $("#nb_datasets").text('(1)');
     
     gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
     
     $.ajax({
      url:  "${request.route_url('mistic.json.cannotation.items', dataset='_dataset_')}".replace('_dataset_', current_dataset),
      dataype: 'json',
      success: function(data) {
           
            var options = $('#sample_selection');
            _.each(data, function(d) {
                _.each(d, function(e,v) {
                options.append('<optgroup label="'+v+'">');
                _.each(e, function(l) {
                    options.append('<option value="'+v+'.'+l+'">'+l+'</options>');
                });
                options.append('</optgroup>');
                });            
            });
       }
        
        });
    }
    gene_entry.$el.val('');

    $('#genelist').empty();
    current_graph.removeData(function() { return true; });
   
  });

  $('#datasets').change();

  resizeGraph = function() {
    $('div#graph').height($(window).height() - 124);

    current_graph.resize(
      $('div#graph').width(),
      $('div#graph').height());
    $('.locate').change();
  };

  $('div#graph').append(current_graph.svg);

  resizeGraph();
  $(window).resize(resizeGraph);
  
  $('#show_labels').on("click", function(event){
    
    var selected = d3.selectAll("text.circlelabel").filter(function(){var c = $(this).siblings('circle'); return $(c)[0].className.baseVal=='selected';});
    
    if (selected[0].length>0 ) { 
           selected.classed('invisible', !selected.classed('invisible'));
    }
    else {
  	     d3.selectAll("text.circlelabel").classed('invisible', !d3.selectAll("text.circlelabel").classed('invisible'));
  	}
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
  		d3.selectAll('circle').classed('selected', true);
  		var dat = [];
  		d3.selectAll('circle.selected').each(function(d) {
    		dat.push(d.k);
  		});
  		dat = _.uniq(dat);
  		_.each(dat, addInformation);
  		d3.select(this).text("Clear all");
  		d3.select(this).classed("active", true);
  	}
  	else {
  	  
  		d3.selectAll('circle').classed('selected', false);
  		clearInformation();
  		d3.select(this).text("Select all");
  		d3.select(this).classed("active", false);
  		
	  	}
	event.preventDefault();
	});
	

  $("[id^='add']").on('click', function(event) {
    var cclass = this.id.replace('add', 'highlighted'); 
      
    var dat = [];
    d3.selectAll('circle.selected').each(function(d) { dat.push(d.k); });
    d3.selectAll('circle.'+cclass).each(function(d) { dat.push(d.k); });
    
    if (dat.length > 0 ) {
      dat = _.uniq(dat);
      $('#'+cclass).val(dat.join(' '));
      current_graph.draw()
      $('.locate').change();
    } 
    $("#sample_selection > option").attr('selected', false);
  });
  
   $("[id^='minus']").on('click', function(event){
    var cclass = this.id.replace('minus', 'highlighted'); 
    var highlighted = [];
    d3.selectAll('circle.'+cclass).each(function(d) { highlighted.push(d.k); });
    
    var selected = [];
    d3.selectAll('circle.selected').each(function(d) { selected.push(d.k); });
    
    var dat= _.difference(highlighted,selected);
    d3.selectAll('circle.selected').attr('fill', undefined);
    d3.selectAll('circle.selected').classed(cclass, false);    
    d3.selectAll('circle.selected').classed('selected', false);
    dat = _.uniq(dat);
    $('#'+cclass).val(dat.join(' '));
    $('.locate').change();
  });
  
  
  $("[id^='tograph']").on('click', function(event){
    var cclass = this.id.replace('tograph', 'highlighted'); 
    var dat =  $('#'+cclass).val().split(' ');
    var circles = d3.selectAll('circle'); 
    circles.filter(function(d, i) {return (_.contains(dat, d.k));})
      .classed('selected', true );
     _.each(dat, addInformation);
  });
  
  $("[id^='remove']").on('click', function(event){
    var cclass = this.id.replace('remove', 'highlighted'); 
    d3.selectAll('circle.'+cclass).attr('fill', undefined);
    d3.selectAll('circle.'+cclass).attr('stroke', undefined);
    d3.selectAll('circle.'+cclass).classed(cclass, false);   
    $('#'+cclass).val('');
    $('.locate').change();
  });
	
  $("[id^='spectrum']").on('click', function(event){
    var to = $(this).data().applyTo;
    $(this).spectrum('set',(to=='stroke' ? $(this).css('stroke'): $(this).css('fill') ));
    $(this).show();
  });
  

  $('.locate').on('change', function(event){
    
    var tag_entry = event.target.value.split(" ");
    if (tag_entry.length==1 & tag_entry[0]=="") {
        event.preventDefault();
        return
    }
    
    var cclass = this.id;
  	var circles = d3.selectAll('circle'); 
  	
  	var dat = [];
  	circles.each(function(d) { dat.push(d.k);});
  	dat = _.uniq(dat);
  	
  	search = function (list, regex) {
  	  if (regex=='') { return (new Array());}
      return _.filter(list, function(obj){ return obj.match(regex);});
    };
    
  	var tag_valid = _.flatten(_.map(tag_entry, function(item) {return search(dat, item);}  ));
  	
	circles = circles.filter(function(d, i) {return (_.contains(tag_valid, d.k));});
    circles.classed(cclass, !d3.select(this).classed(cclass));
	
	circles.attr('fill', undefined );
    circles.attr('stroke', undefined);
   
	_.each(circles[0], function(c) {
	       cls = $(c).attr('class').split(' ');
	       cls.sort();
	       cls = _.reject(cls, function(el) {return el=='selected'});
	      
	       _.each(cls, function(ll) {
	         
	           hls = highlights[ll];
	         
	           if (!_.isUndefined(hls.fill)) {
	               $(c).attr('fill', hls.fill );
	           }
	           if (!_.isUndefined(hls.stroke)){
                   $(c).attr('stroke', hls.stroke );
                   $(c).attr('stroke-width', '2px');
	           }
	         });  
	});
	
	
	clearInformation();
	  _.each(tag_valid, addInformation);
  	
  	// Update counts label (dataset, genes, samples)
  	var nplots = stats.sum(_.range(1,current_graph.data.length));
  	var nsamples = $("circle[class^='highlighted']").length/nplots;
  	if (_.isNaN(nsamples)) { nsamples=0;}
    $("#nb_samples").text('('+nsamples+')');
    
  	event.preventDefault();
  	
 	});
  

  
  $("#sample_selection").on("change", function(){
   
    var val = $(event.target).val().split('.');
    var l1 = val[0];
    var l2 = val[1];
    
    var tags = [];
    _.each(current_graph.data, function (d) {_.each(d.data, function(e) {if (e[l1]==l2){tags.push(e.sample);}});});
    tags = _.uniq(tags);
    
    var cclass = 'selected';
    d3.selectAll('circle').classed(cclass, false);
    d3.selectAll('circle').filter(function(d, i) {return (_.contains(tags, d.k));})
      .classed(cclass, !d3.select(this).classed(cclass));
  
  });
        

});
</script>
</%block>
