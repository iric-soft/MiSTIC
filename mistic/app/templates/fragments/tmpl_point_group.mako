<script type="text/template" id="tmpl-point-group">
  <span style="display: inline-block">
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" class="legend" height="18" width="18"></svg>
  </span>
  <input type="text" autocomplete="off"></input>
  <span style="display: inline-block; white-space: nowrap">
    <i class="sg-add           icon-plus"     ></i>
    <i class="sg-remove        icon-minus"    ></i>
    <i class="sg-clear         icon-remove"   ></i>
    <i class="sg-set-selection icon-share-alt"></i>
  </span>
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
            <span  style="float: right;"><input type="text" class="colour"></span>
            <div class="controls">
              <label class="checkbox"><input class="is-enabled" type="checkbox"> Enabled</label>
            </div>
          </div>
          <div class="control-group group-stroke">
            <label class="control-label"><b>Stroke:</b></label>
            <span  style="float: right;"><input type="text" class="colour"></span>
            <div class="controls">
              <label class="checkbox"><input class="is-enabled" type="checkbox"> Enabled</label>
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
