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
    <link rel="stylesheet" href="${request.static_url('mistic:app/cdnjs/datatables/1.9.4/css/jquery.dataTables.min.css')}" type="text/css" media="screen" charset="utf-8">

    <link rel="stylesheet" href="${request.static_url('mistic:app/static/css/ext/spectrum.css')}" type="text/css" media="screen" charset="utf-8">

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
<%block name="controls">
    <div id="controls" class="span3">
    </div>
</%block>

<%block name="graph">
    <div class="span9">
      <div id="graph">
      </div>
    </div>
  </div>
  <div class="row-fluid">
    <div class="span12" id ="more-information"></div>
  </div>
</%block>
</div>
</%block>





</body>
<%block name="pagetail">
<%include file="mistic:app/templates/fragments/tmpl_geneset_selector.mako"/>

<script src="${request.static_url('mistic:app/cdnjs/require.js/2.1.11/require.min.js')}"></script>
<script type="text/javascript">
    require.config({
        baseUrl: "${request.static_url('mistic:app/static/js/lib')}",

        paths: {
            "jquery":           "${request.static_url('mistic:app/cdnjs/jquery/1.11.1/jquery.min')}",
            "underscore":       "${request.static_url('mistic:app/cdnjs/underscore.js/1.6.0/underscore-min')}",
            "backbone":         "${request.static_url('mistic:app/cdnjs/backbone.js/1.1.2/backbone-min')}",
            "bootstrap":        "${request.static_url('mistic:app/cdnjs/twitter-bootstrap/2.3.2/js/bootstrap.min')}",
            "bootstrap-select": "${request.static_url('mistic:app/cdnjs/bootstrap-select/1.5.4/bootstrap-select.min')}",
            "bootstrap-modal":  "${request.static_url('mistic:app/cdnjs/bootstrap-modal/2.1.0/bootstrap-modal.pack.min')}",
            "d3":               "${request.static_url('mistic:app/cdnjs/d3/3.4.8/d3.min')}",
            "zeroclipboard":    "${request.static_url('mistic:app/cdnjs/zeroclipboard/2.0.0-beta.8/ZeroClipboard.min')}",

            "domReady":         "${request.static_url('mistic:app/cdnjs/require-domReady/2.0.1/domReady.min')}",

            "spectrum":         "${request.static_url('mistic:app/static/js/lib/ext/spectrum')}",
            "base64":           "${request.static_url('mistic:app/static/js/lib/ext/base64')}",

            "datatables":                      "${request.static_url('mistic:app/cdnjs/datatables/1.9.4/jquery.dataTables.min')}",
            "datatables.colreorderwithresize": "${request.static_url('mistic:app/static/js/lib/ext/jquery.dataTables.colReorderWithResize')}",
            "datatables.rowgrouping":          "${request.static_url('mistic:app/static/js/lib/ext/jquery.dataTables.rowGrouping')}",
            "datatables.scientificsorting":    "${request.static_url('mistic:app/static/js/lib/ext/jquery.dataTables.scientific-sorting')}",
            "datatables.columnfilter":         "${request.static_url('mistic:app/static/js/lib/ext/jquery.dataTables.columnFilter')}",
        },

        shim: {
            "bootstrap":                       { deps: ["jquery"] },
            "bootstrap-select":                { deps: ["bootstrap"] },
            "bootstrap-modal":                 { deps: ["bootstrap"] },
            "spectrum":                        { deps: ["jquery"] },
            "datatables.colreorderwithresize": { deps: ["datatables"] },
            "datatables.rowgrouping":          { deps: ["datatables"] },
            "datatables.scientificsorting":    { deps: ["datatables"] },
            "datatables.columnfilter":         { deps: ["datatables"] },
        },

        waitSeconds: 15
    });
</script>

<form id="pdfform" target="_blank" method="post" action="${request.route_url('mistic.pdf.fromsvg')}">
  <input id="pdfdata" type="hidden" name="pdfdata" value=""></input>
</form>

<script type="text/javascript">
// force bootstrap to always be loaded.
require(["bootstrap", "bootstrap-select"]);

require(["jquery"], function($) {
  "use strict";

  $('#pdf').click(function() {
    $('#pdfdata').val($('#graph').html());
    $('#pdfform').submit();
  });
});
</script>
</%block>
</html>
