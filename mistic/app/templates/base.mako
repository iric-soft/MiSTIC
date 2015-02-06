<!DOCTYPE html>
<html>
<%
from pyramid.security import authenticated_userid 
environ =  request.__dict__.get('environ', {})
root_url = request.registry.settings.get('mistic_forward_host', request.url)

if 'mistic_forward_host' in request.registry.settings.keys() and environ.get('HTTP_X_FORWARDED_HOST', None): 
    request.host = root_url
    request.port = ''
#print authenticated_userid(request), 'request host:', request.host, request.remote_addr

%>



  <head>
    <title><%block name="pagetitle"></%block></title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">
    <meta name="keywords" content="">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/bootstrap.min.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/bootstrap-responsive.min.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/bootstrap-modal.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/bootstrap-select.min.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/jquery.dataTables.css')}" type="text/css" media="screen" charset="utf-8"> 
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/TableTools.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/spectrum.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/mistic.css')}" type="text/css" media="screen" charset="utf-8">
    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/mistic_svg.css')}" type="text/css" media="screen" charset="utf-8">



<script type="text/javascript">


mistic = {  url: "${request.host}"};

</script>

<!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
<![endif]-->
<!--[if lt IE 8]>
    <script src="${request.static_url('mistic:app/static/js/lib/json2.js')}" type="text/javascript" />
<![endif]-->

  </head>
  <body>

    <div class="navbar navbar-fixed-top navbar-inverse">
      <div class="navbar-inner">
        <div class="container-fluid">
        <a href="#" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
        <span class="icon-th-list icon-white"></span></a>
          <a class="brand" href="${request.route_url('mistic.template.root')}">[Datasets and Icicle]</a>
          <div class="nav-collapse">
            <ul class="nav">
        
              %if request.matched_route.name == 'mistic.template.corrgraph':
                  <li class="active"><a href="#">Single gene correlation</a></li>
              %else:
                  <li><a href="${request.route_url('mistic.template.corrgraph')}">Single gene correlation</a></li>
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
              <a href="${request.route_url('mistic.template.pairplot', dataset=None, genes=[])}">Pairwise correlation scatterplots</a></li>

        
              %if request.matched_route.name == 'mistic.template.mds':
                  <li class="active"><a href="#">Multidimensional scaling plots</a></li>
              %else:
                  <li><a href="${request.route_url('mistic.template.mds', dataset=None, genes=[])}">Multidimensional scaling plots</a></li>
              %endif



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
              <a href='/' id='logout' class='pull-right' style='padding-left:10px; vertical-align:middle;' title="${user}"><i class="icon-user icon-white"></i></a>
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
    <script src="${request.static_url('mistic:app/static/js/lib/bootstrap-select.min.js')}" type="text/javascript"></script>

    <script src="${request.static_url('mistic:app/static/js/lib/bootstrap-modal.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/bootstrap-modalmanager.js')}" type="text/javascript"></script> 

    <script src="${request.static_url('mistic:app/static/js/lib/d3.v2.min.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.min.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.colReorderWithResize.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.rowGrouping.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.scientific-sorting.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.columnFilter.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/jquery.dataTables.TableTools.min.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/spectrum.js')}" type="text/javascript"></script>

    <script src="${request.static_url('mistic:app/static/js/lib/colour.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/math.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/fisher.js')}" type="text/javascript"></script>
    <script src="${request.static_url('mistic:app/static/js/lib/base64.js')}" type="text/javascript"></script>
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
          max_items: 50,
          menu: '<ul class="typeahead dropdown-menu" style="max-width: 600px; max-height: 400px; overflow-x: hidden; overflow-y: auto"></ul>',

          autofillText: function(model) {
            if (model !== undefined && model !== null) {
              if (model.get('name')!='') {
                  return model.id + ': ' + model.get('name');
                  }
              else {
                      return model.id ;
                    }
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
        

        
      $('#logout').click(function ()  {  clearAuthentication("${request.url}"); });

      
        
      })(jQuery);
    </script>
  </%block>
</html>
