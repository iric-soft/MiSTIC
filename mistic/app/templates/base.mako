<!DOCTYPE html>
<html>
  <head>
    <title><%block name="pagetitle"></%block></title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">
    <meta name="keywords" content="">
    <link rel="stylesheet" href="${request.static_url('mistic:app/cdnjs/twitter-bootstrap/2.3.2/css/bootstrap.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/cdnjs/twitter-bootstrap/2.3.2/css/bootstrap-responsive.min.css')}" type="text/css" media="screen" charset="utf-8">

    <link rel="stylesheet" href="${request.static_url('mistic:app/cdnjs/bootstrap-modal/2.1.0/bootstrap-modal.min.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/cdnjs/bootstrap-select/1.5.4/bootstrap-select.min.css')}" type="text/css" media="screen" charset="utf-8">

    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/jquery.dataTables.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/spectrum.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/mistic.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/mistic_svg.css')}" type="text/css" media="screen" charset="utf-8">

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
      <a href="#" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
       <span class="icon-th-list icon-white"></span></a>
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
            <%block name="actions">
            <%
            import mistic.app.views.pdffile as pdffile
            no_pdf = pdffile.PDFData.rsvg_convert== None and pdffile.PDFData.phantomjs== None
            %>
            %if not no_pdf:
                <button type="submit" class="btn" id="pdf" href="">PDF</button>
            %endif
            </%block>
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

<%include file="mistic:app/templates/fragments/tmpl_geneset_selector.mako"/>

<script src="${request.static_url('mistic:app/cdnjs/jquery/1.11.1/jquery.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/cdnjs/underscore.js/1.6.0/underscore-min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/cdnjs/backbone.js/1.1.2/backbone-min.js')}" type="text/javascript"></script>

<script src="${request.static_url('mistic:app/cdnjs/twitter-bootstrap/2.3.2/js/bootstrap.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/cdnjs/bootstrap-select/1.5.4/bootstrap-select.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/cdnjs/bootstrap-modal/2.1.0/bootstrap-modal.pack.min.js')}" type="text/javascript"></script>

<script src="${request.static_url('mistic:app/cdnjs/d3/3.4.8/d3.min.js')}" type="text/javascript"></script>

<script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.min.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.colReorderWithResize.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.rowGrouping.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.scientific-sorting.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.columnFilter.js')}" type="text/javascript"></script>

<script src="${request.static_url('mistic:app/static/js/lib/spectrum.js')}" type="text/javascript"></script>

<script src="${request.static_url('mistic:app/static/js/lib/colour.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/math.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/fisher.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/base64.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/transform.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/datasets.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/dropdown.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/go_dropdown.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/utils.js')}" type="text/javascript"></script>
<script src="${request.static_url('mistic:app/static/js/lib/modal_base.js')}" type="text/javascript"></script>

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
      if (model !== undefined && model !== null) {
        var symbol = model.get('symbol') ? model.get('symbol') : model.get('id')
        return symbol + ' ' + model.get('name');
      }
      return '';
    },

    searchData: function() {
      return { q: this.$el.val() };
    }
  });

 
 
  window.SampleFeature = Backbone.Model.extend();

  window.SampleAnnotation = Backbone.Collection.extend({
    model: window.SampleFeature
  });

  window.sample_annotation_cache = new SampleAnnotation();

  window.SampleAnnotationItemView = DropdownItemView.extend({
    
    template: _.template(<%text>"<span class='label label-inverse'><%- get('key') %></span> <%- get('values') %>"</%text>),
    itemClass: function() {return this.model.get('key'); }
  });

  window.SampleAnnotationDropdown = Dropdown.extend({
    item_view: SampleAnnotationItemView,
    max_items: 1500,
    menu: '<ul class="typeahead dropdown-menu" style="width:auto;max-width: 400px; max-height: 400px; overflow-x: hidden; overflow-y: auto"></ul>',

    autofillText: function(model) {
    
      if (model !== undefined && model !== null) {
        return model.get('key') + ' : ' + model.get('values');
      }
      return '';
    },

    searchData: function() {
      
      return { q: this.$el.val() };
    }
  });
  

  
  
})(jQuery);
</script>
</%block>
</html>
