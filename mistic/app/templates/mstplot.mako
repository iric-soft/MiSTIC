<%!
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">MST</%block>
<%block name="actions">
  ${parent.actions()}
</%block>
<%block name="controls">
  <form class="form-inline">
    <div class="accordion-group">
       <div class="accordion-heading"><h4 class="accordion-title">
         <a class="accordion-toggle" data-toggle="collapse"  href="#extract_peak">WARNNING</a></h4>
       </div>

       <div id="extract_peak" class="accordion-body collapse in">
          <div class="accordion-inner">
              <form class="form-horizontal">
                Sorry, this graph have too many genes (>200), we can't display it.
                We suggest to you use extract peaks, with max number of genes = 200, to see all peaks we can display.
              </form>
          </div>
      </div>
    </div>
  </form>
</%block>
<%block name="pagetail">
${parent.pagetail()}

</%block>
