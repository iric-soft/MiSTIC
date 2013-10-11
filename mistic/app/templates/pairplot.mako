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
   op1 = []
   op2 = []
   if ds: 
    ca = ds.cannotation.attrs
    so =list(set(sum([e.items() for e in ca.values()], [])))
    op1 = list(set([x[0] for x in so]))
    op1.remove('sample')
    op1.remove('expr')
    op2 = [list(set([x[1] for x in so if  x[0]==a])) for a in op1]
   
   
%>


<div class="row-fluid">
   <div id="menu" class="span12" style="display:inline;" >

      <form class="form-inline">
     
        <div class="accordion" id="accordion">
            <div class="accordion-group">        
              <div class="accordion-heading">
                <h4 class="accordion-title">
                  <a class="accordion-toggle" data-toggle="collapse"  href="#dataset_menu">Datasets <div id="nb_datasets" class='text-info'></div></a>
                </h4>
              </div>
       
              <div id="dataset_menu" class="accordion-body collapse in">
                <div class="accordion-inner">
                  
                  <label for="datasets">Choose a dataset:</label>
                  <select id="datasets">
                    <option value=""></option>
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
                  <a class="accordion-toggle" data-toggle="collapse"  href="#gene_menu">Genes <div id="nb_genes" class='text-info'></div></a>
               </h4>
            </div>
    
            <div id="gene_menu" class="accordion-body collapse ">
              <div class="accordion-inner">
      
                  <label for="gene">Select a gene :</label>
                  <input type="text" id="gene" autocomplete="off"/> 	
      
                  <span id="genelist"></span>
              </div>
            </div>
          </div>
    
        <div class="accordion-group">        
           <div class="accordion-heading">
             <h4 class="accordion-title">
                <a class="accordion-toggle" data-toggle="collapse"  href="#sample_menu">Samples <div id="nb_samples" class='text-info'></div></a>
            </h4>
       </div>
    
      <div id="sample_menu" class="accordion-body collapse in ">  
        <div class="accordion-inner">
          
        
          <h5><a class="accordion-toggle" data-toggle="collapse"  href="#current_selection">Selected samples</a></h5>
          <div id="current_selection" class="accordion-body collapse in ">
          
          <div>
          <label style="display:inline;" for="highlighted1" size="10px">[1]</label>
          <input type="text" class="locate" id="highlighted1" autocomplete="off"  />
          <i id="add1" class="icon-plus"></i>
          <i id="minus1" class="icon-minus"></i>
          </div>
          
          <div>
          <label style="display:inline;" for="highlighted2" size="10px">[2]</label>
          <input type="text" class="locate" id="highlighted2" autocomplete="off"   />
          <i id="add2" class="icon-plus"></i>
          <i id="minus2" class="icon-minus"></i>
          </div>
          
          <div>
          <label style="display:inline;" for="highlighted3" size="10px">[3]</label>
          <input type="text" class="locate" id="highlighted3" autocomplete="off"  />
          <i id="add3" class="icon-plus"></i>
          <i id="minus3" class="icon-minus"></i>
          
          
          </div>
          <div>
            <label style="display:inline;" for="highlighted4" size="10px">[4]</label>
            <input type="text" class="locate" id="highlighted4" autocomplete="off"  />
            <i id="add4" class="icon-plus"></i>
            <i id="minus4" class="icon-minus"></i>
         
          </div>
          </div>
          
          <hr>
          <h5><a class="accordion-toggle" data-toggle="collapse"  href="#characteristic_selection">Select by characteristic</a></h5>
          <div id="characteristic_selection" class="accordion-body collapse in ">
           
             
          <!--<div class="dropdown">
              <a data-toggle="dropdown" class="dropdown-toggle" href="#">Click me!!  <b class="caret"></b></a>
              <ul class="dropdown-menu" id="menu1">
                %for i in range(len(op1)) :
                    <li><a href="#">${op1[i]}</a>
                      <ul class="dropdown-menu dropdown-submenu">
                      % for e2 in op2[i] : 
                        <li><a href="#">${e2}</a></li>
                      %endfor
                      </ul>
             
                   </li>
               %endfor
       
            </ul>
          </div>-->
             
             
             
             
            </div>     
          
          
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
  
          <div class="dropdown">
              <a data-toggle="dropdown" class="dropdown-toggle" href="#">Click me!!  <b class="caret"></b></a>
              <ul class="dropdown-menu" id="menu1">
                %for i in range(len(op1)) :
                    <li><a class='l1' href="#">${op1[i]}</a>
                      <ul class="dropdown-menu dropdown-submenu">
                      % for e2 in op2[i] : 
                        <li><a class='l2' href="#">${e2}</a></li>
                      %endfor
                      </ul>
             
                   </li>
               %endfor
       
            </ul>
          </div>

 <!--<div class="span12" id="advanced"  >
 
 <div class="btn-group">
  <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown">More options
    <span class="caret"></span>
  </button>
  <ul class="dropdown-menu" role="menu">
    <li><a id='show_labels'  href="#">Show labels</a></li>
    <li><a id='select_clear' href="#">Select all</a></li>
    <li class="divider"></li>
    <li><a id="change_axes"  href="#">Change axes</a></li>

  </ul>
</div>
      
 </div>-->
      
 


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

div#graph text {
  pointer-events : none;
}

.circlelabel .invisible {
  pointer-events : none;
}

circle  {
  pointer-events : auto;
}




</%block>

<%block name="pagetail">
${parent.pagetail()}

<script src="${request.static_url('mistic:app/static/js/lib/scatterplot.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/pairplot.js')}" type="text/javascript"></script>


<script type="text/javascript">
$(document).ready(function() {
 
  
  var gene_entry = new GeneDropdown({ el: $("#gene") });
  current_graph = new pairplot(undefined, undefined, $('#graph'));
  $("#options").css('display', 'none');
  
   <%  
   ds = data.datasets.get(dataset)
   gene_data = [ds.expndata(gene) for gene in genes ]
   
  %>
  
  %if not ds==None:
    current_dataset = "${dataset}";
    $('#datasets').val(current_dataset).change();
    gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
   
  %else:
    current_dataset = undefined;
    gene_entry.url = null;
    $("#gene").attr('disabled', true);
    $("#tag").attr('disabled', true);
  %endif
  

  //  Gene symbols were passed in the URL
  %if len(genes)>0:
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
        _.each(current_graph.data, function(x) { url += '/' + x.gene; });
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

  

  $('#datasets').on('change', function(event) {
   
    current_dataset = event.target.value;
    
    if (current_dataset === '') {
      current_dataset = null;
      gene_entry.url = null;
      $("#gene").attr('disabled', true);
      $(".locate").attr('disabled', true);
    
      
    } else {
     $("#gene").attr('disabled', false);
     $(".locate").attr('disabled', false);
     
     gene_entry.url = "${request.route_url('mistic.json.dataset.search', dataset='_dataset_')}".replace('_dataset_', current_dataset);
     
    }
    gene_entry.$el.val('');

    $('#genelist').empty();
    current_graph.removeData(function() { return true; });
    
    
  });

  

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
    if (dat.length > 0 ) {
      $('#'+cclass).val(dat.join(' '));
      current_graph.draw()
      $('.locate').change();
 
    }
   
  });
  $("[id^='minus']").on('click', function(event){
    var cclass = this.id.replace('minus', 'highlighted'); 
    $('#'+cclass).val('');
    $('.locate').change();
  
  });
 		
 	// Point labels 

 	
  $('.locate').on('change', function(event){
    var cclass = this.id;
  	var tag_entry = event.target.value.split(" ");
  	var circles = d3.selectAll('circle'); 
  	
  	var dat = [];
  	circles.each(function(d) { dat.push(d.k);});
  	dat = _.uniq(dat);
  	
  	search = function (list, regex) {
  	  if (regex=='') { return (new Array());}
      return _.filter(list, function(obj){ return obj.match(regex);});
    };
    
  	var tag_valid = _.flatten(_.map(tag_entry, function(item) {return search(dat, item);}  ));
  	
  	d3.selectAll('circle').classed(cclass, false);
  	
	  circles.filter(function(d, i) {return (_.contains(tag_valid, d.k));})
			.classed(cclass, !d3.select(this).classed(cclass));
	
	  clearInformation();
	  _.each(tag_valid, addInformation);
  	
  	event.preventDefault();
  	
 	});
  
  $('#menu1 li ul li').on('click', function() {
    var l2 = event.target.text;
    var l1 = $(event.target).parents('li')[1].firstChild.text;
    console.debug(l1);
    console.debug(l2);
    
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
