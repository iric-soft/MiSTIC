<script type="text/template" id="tmpl-point-group">
  <span class="well sg-style" style="position: absolute; left: 0px; padding: 3px; width: 16px; height: 16px; display: inline-block; margin: 0px;">
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" class="legend" width="16" height="20"></svg>
  </span>

  <span class="well sg-ops" style="position: absolute; right: 0px; padding: 3px; width: 68px; height: 16px; display: inline-block; margin: 0px;">
    <i class="sg-add           icon-plus"     ></i>
    <i class="sg-remove        icon-minus"    ></i>
    <i class="sg-clear         icon-trash"    ></i>
    <i class="sg-set-selection icon-share-alt"></i>
  </span>

  <input style="display: inline-block; width: auto; position: absolute; left: 26px; right: 78px;" type="text" autocomplete="off"></input>
</script>
<script type="text/template" id="tmpl-point-group-settings">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>\
        <h4 class="modal-title">Group settings</h4>
      </div>
      <div class="modal-body">
        <form class="form-horizontal">
          <div class="control-group">
            <label class="control-label" for="input-group-name"><b>Label:</b></label>
            <div class="controls"><input type="text" class="group-name"></div>
          </div>
          <div class="control-group group-fill">
            <label class="control-label"><b>Fill:</b></label>
            <span  style="float: right;">
              <span class="btn colour" style="position: relative;">&nbsp;
                <span style="position: absolute; left: 3px; right: 3px; top: 3px; bottom: 3px; border: 1px solid black; display: inline-block; background-color: #fff;"></span>
              </span>
            </span>
            <div class="controls">
              <select class="state">
                <option value="enabled">Enabled</option>
                <option value="disabled">Disabled</option>
                <option value="inherit">Inherit</option>
              </select>
            </div>
          </div>
          <div class="control-group group-stroke">
            <label class="control-label"><b>Stroke:</b></label>
            <span  style="float: right; white-space: nowrap;">
              <select class="stroke-width">
                <option value="1">1px</option>
                <option value="2">2px</option>
                <option value="3">3px</option>
                <option value="5">4px</option>
              </select>
              <span class="btn colour" style="position: relative;">&nbsp;
                <span style="position: absolute; left: 3px; right: 3px; top: 3px; bottom: 3px; border: 1px solid black; display: inline-block; background-color: #fff;"></span>
              </span>
            </span>
            <div class="controls">
              <select class="state">
                <option value="enabled">Enabled</option>
                <option value="disabled">Disabled</option>
                <option value="inherit">Inherit</option>
              </select>
            </div>
          </div>
        </form>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
        <button type="button" class="btn btn-primary action-save" data-dismiss="modal">Save</button>
      </div>
    </div>
  </div>
</script>
