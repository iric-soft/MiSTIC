<%inherit file="mistic:app/templates/base.mako"/>

<%block name="pagetitle">RNA-seq dataset explorer</%block>



<%block name="pagecontent">
  <div class="container-fluid">
    <div class="row-fluid">
      <div class="span12">

      <div style="text-align: center;" > 
      <div class="well" style="display: inline-block;">
      <h3>This short video will give you an idea of how you can use MiSTIC </h3>


      <video width="960" height="720" controls>
           <source src="${request.static_url('mistic:resources/video/MiSTIC.20170207.mp4')}" type="video/mp4">
            Your browser does not support the video tag.
      </video>


      <iframe width="480" height="320" src='https://www.youtube.com/embed/FjtzdKNpJ7I'></iframe>


          </div>
      </div>

  
</%block>
