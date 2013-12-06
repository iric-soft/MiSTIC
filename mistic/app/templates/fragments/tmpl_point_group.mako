<%text>
<script type="text/template" id="tmpl-point-group">
  <div class="content">
    <div class="widgets">
      <a class="shift-up">&#x25B2;</a><a class="shift-dn">&#x25BC;</a><a class="close">&times;</a>
    </div>
    <div class="header"><span><% view.name() %></span></div>
    <span class="control-group sg-style" style="position: absolute; left: 2px; width: 16px;">
      <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" class="legend" width="16" height="20"></svg>
    </span>
    <span class="control-group sg-ops" style="position: absolute; right: 2px; width: 68px; padding-top: 5px; padding-bottom: 1px">
      <i class="sg-add           icon-plus"     ></i>
      <i class="sg-remove        icon-minus"    ></i>
      <i class="sg-clear         icon-trash"    ></i>
      <i class="sg-set-selection icon-share-alt"></i>
    </span>
    <input style="display: inline-block; width: auto; position: absolute; left: 28px; right: 80px;" type="text" autocomplete="off">
  </div>
</script>



<script type="text/template" id="tmpl-point-group-settings">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">Group settings</h4>
      </div>
      <div class="modal-body">
        <div class="form-horizontal">
          <div class="control-group">
            <label class="control-label" for="input-group-name"><b>Label:</b></label>
            <div class="controls"><input type="text" class="group-name" placeholder="Label" value="<%- group.get('name') %>"></input></div>
          </div>
          <div class="control-group group-shape">
            <label class="control-label"><b>Shape:</b></label>
            <div class="controls">
              <div class="btn-group state" data-toggle="buttons-radio">
                <button type="button" class="btn<%= active(style._shape===undefined)%>" data-value="inherit">Inherit</button>
<% _.each(d3.svg.symbolTypes, function(symbol) { %>
                <button type="button" class="btn<%= active(style._shape===symbol)%>" data-value="<%= symbol %>" style="padding: 2px 3px;">
                  <svg width="16" height="17">
                    <g transform="translate(8,10)">
                      <path fill="#000" d="<%- d3.svg.symbol().type(symbol)() %>"></path>
                    </g>
                  </svg>
                </button>
<% }); %>
              </div>
            </div>
          </div>
          <div class="control-group group-fill">
            <label class="control-label"><b>Fill:</b></label>
            <div class="controls">
              <span  style="float: right;">
                <span class="btn colour" style="position: relative;">&nbsp;
                  <span style="position: absolute; left: 3px; right: 3px; top: 3px; bottom: 3px; border: 1px solid black; display: inline-block; background: <%- colour(style.fill) %>;"></span>
                </span>
              </span>
              <select class="state selectpicker" style="width: 14ex" data-width="14ex" data-container="body">
<% _.each(['enabled', 'disabled', 'inherit'], function(state) { var curr = get_state(style.fill); %>
                <option value="<%- state %>"<%= selected(state===curr) %>><%- capitalize(state) %></option>
<% }); %>
              </select>
            </div>
          </div>
          <div class="control-group group-stroke">
            <label class="control-label"><b>Stroke:</b></label>
            <div class="controls">
              <span style="float: right; white-space: nowrap;">
                <select class="stroke-width selectpicker" style="width: 11ex" data-width="11ex" data-container="body">
                  <option value="inherit">Inherit</option>
                  <option value="1px">1px</option>
                  <option value="2px">2px</option>
                  <option value="3px">3px</option>
                  <option value="4px">4px</option>
                </select>
                <div class="btn-group" style="display: inline-block">
                  <span class="btn colour" style="position: relative;">&nbsp;
                    <span style="position: absolute; left: 3px; right: 3px; top: 3px; bottom: 3px; border: 1px solid black; display: inline-block; background: <%- colour(style.stroke) %>;"></span>
                  </span>
                </div>
              </span>
              <select class="state selectpicker" style="width: 14ex" data-width="14ex" data-container="body">
<% _.each(['enabled', 'disabled', 'inherit'], function(state) { var curr = get_state(style.stroke); %>
                <option value="<%- state %>"<%= selected(state===curr) %>><%- capitalize(state) %></option>
<% }); %>
              </select>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
        <button type="button" class="btn btn-primary action-save" data-dismiss="modal">Save</button>
      </div>
    </div>
  </div>
</script>
</%text>
