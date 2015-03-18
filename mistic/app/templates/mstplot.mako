<%!
import json
%>
<%inherit file="mistic:app/templates/base.mako"/>
<%block name="pagetitle">MST</%block>
<%block name="actions"> ${parent.actions()}</%block>

<%block name="controls"></%block>
<%block name="pagecontent">
 <div class='container'> <h2>WARNNING</h2> 
<div id="extract_peak" >
    <h4>Sorry, this graph have too many genes (> ${max_genes}). We can't display it!
    <br/>

    We suggest that you use the extract peaks function on the icicle page to see the peaks that can be displayed.
    
    
    <p>
    <br>
    <ol>
    <li> Go back to the Icicle plot </li>
    <li> Open the "Extract peaks" Menu </li>
    <li> Set the maximum number of genes in a peak to ${max_genes} </li>
    <li> Click view </li>   
    <li> Click on the colored peaks to further investigate them </li>   
    </ol>
    
    
    <br> 
    For bigger peaks, consider using the Extract peaks tool to save them in a file 
    
    </h4>
     <div>       
   
    </div>          
</%block>
<%block name="pagetail">
${parent.pagetail()}

</%block>
