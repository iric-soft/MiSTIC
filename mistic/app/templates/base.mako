<!DOCTYPE html>
<html>



  <head>
    <title><%block name="pagetitle">Correlation waterfall plot</%block></title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">
    <meta name="keywords" content="">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/bootstrap.min.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/bootstrap-responsive.min.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/jquery.dataTables.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/spectrum.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/mistic.css')}" type="text/css" media="screen" charset="utf-8">


<!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
<![endif]-->
<!--[if lt IE 8]>
    <script src="${request.static_url('mistic:app/static/js/lib/json2.js')}" type="text/javascript" />
<![endif]-->

<script type="text/javascript">
mistic = {
  url: "${request.application_url}"
};
</script>
 
<style type="text/css">
<%block name="style">



</%block>
</style>



</head>
<body>

  <div class="navbar navbar-fixed-top navbar-inverse">
    <div class="navbar-inner">
      <div class="container-fluid">
        <a class="brand" href="${request.route_url('mistic.template.root')}">[MiSTIC]</a>
        <div class="nav-collapse">
          <ul class="nav">
      
        %if request.matched_route.name == 'mistic.template.corrgraph':
            <li class="active"><a href="#">Waterfall</a></li>
        %else:
            <li><a href="${request.route_url('mistic.template.corrgraph')}">Waterfall</a></li>
        %endif


        %if request.matched_route.name == 'mistic.template.corrgraph_static':
            <li class="active"><a href="#">&#x25b6; [static plot]</a></li>
        %endif

<!--
  %if request.matched_route.name == 'mistic.template.scatterplot':
            <li class="active"><a href="#">Scatterplot</a></li>
%else:
            <li><a href="${request.route_url('mistic.template.scatterplot')}">Scatterplot</a></li>
%endif
-->
      %if request.matched_route.name == 'mistic.template.scatterplot_static':
            <li class="active"><a href="#">&#x25b6; [static plot]</a></li>
      %endif

      %if request.matched_route.name == 'mistic.template.pairplot':
            <li class="active">
      %else: 
            <li>
      %endif
      <a href="${request.route_url('mistic.template.pairplot', dataset=None, genes=[])}">Multi-way Scatterplot</a></li>


          </ul>
        </div>
        <div class="pull-right">
          <div class="btn-group">
            <%block name="actions"><button type="submit" class="btn" id="pdf" href="">PDF</button></%block>
          </div>
        </div>
      </div>
    </div>
  </div>
  
  
<%block name="pagecontent">
  <div class="container-fluid">
  
  
  
  <div class="row-fluid">
    <div class="span3">
        <%block name="controls"></%block>
     </div>
    
    <%block name="graph">
     <div class="span9">
        <div id="graph">
        </div>
      </div>
   
   
   <div class="row-fluid">
     <div class="span12" id ="more-information"></div>
  </div>
   </%block>
 </div>  
  </div>
  
</%block>





</body>
<%block name="pagetail">
<form id="pdfform" target="_blank" method="post" action="${request.route_url('mistic.pdf.fromsvg')}">
<input id="pdfdata" type="hidden" name="pdfdata" value=""></input></form>
 
<script src="${request.static_url('mistic:app/static/js/lib/jquery.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/underscore-min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/backbone-min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/bootstrap.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/d3.v2.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/ColReorderWithResize.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.rowGrouping.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/spectrum.js')}" type="text/javascript"></script>

<script src="${request.static_url('mistic:app/static/js/lib/colour.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/math.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/transform.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/ontology.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/datasets.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/dropdown.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/utils.js')}" type="text/javascript"></script>

<script type="text/javascript">
(function($) {
  "use strict";

  $('#pdf').click(function() {
    $('#pdfdata').val($('#graph').html());
    $('#pdfform').submit();
  });

  window.GeneItemView = DropdownItemView.extend({
    template: _.template(<%text>"<span class='label'><%- get('id') %></span><%- get('name') %>  "</%text>),
    itemClass: 'gene-item'
  });

  window.GeneDropdown = Dropdown.extend({
    item_view: GeneItemView,

    autofillText: function(model) {
      var symbol = model.get('symbol') ?  model.get('symbol') :  model.get('id')
      return symbol  +" "+ model.get('name');
    },

    searchData: function() {
      return { q: this.$el.val() };
    }
  });


  window.GOTerm = Backbone.Model.extend();

  window.GO = Backbone.Collection.extend({
    url: "${request.route_url('mistic.json.go')}",
    model: window.GOTerm
  });

  window.go_cache = new GO();

  window.GOItemView = DropdownItemView.extend({
    template: _.template(<%text>"<span class='label'><%- id %></span> <%- get('name') %>"</%text>),
    itemClass: function() { return 'go-'+this.model.get('namespace'); }
  });

  window.GODropdown = Dropdown.extend({
    item_view: GOItemView,
    url: "${request.route_url('mistic.json.go.search')}",
    max_items: 100,
    menu: '<ul class="typeahead dropdown-menu" style="max-width: 400px; max-height: 300px; overflow-x: hidden; overflow-y: auto"></ul>',

    autofillText: function(model) {
      return model.id+'|'+model.get('name');
    },

    searchData: function() {
      return { q: this.$el.val() };
    }
  });
  

  
  
})(jQuery);
</script>
</%block>
</html>
