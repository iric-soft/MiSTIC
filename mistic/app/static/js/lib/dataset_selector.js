(function() {
    DatasetSelector = Backbone.View.extend({
        tagName: 'div',
        className: 'modal hide',
        template: _.template('\
<div class="modal-dialog">\
  <div class="modal-content">\
    <div class="modal-header">\
      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>\
      <h4 class="modal-title">Dataset selector</h4>\
    </div>\
    <div class="modal-body">\
    </div>\
    <div class="modal-footer">\
      <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>\
    </div>\
  </div>\
</div>'),
        err: _.template(''),

        events: {
            'hidden':                    'remove',
            'click tbody tr.selectable': 'select',
        },

        remove: function() {
            this.$el.remove();
        },

        dismiss: function() {
            this.$el.modal('hide');
        },

        render: function() {
            var self = this;
            this.$el.html(this.template());

            $.ajax({
                url: 'http://'+mistic.url+'/modal/datasets',
                data: {},
                async: false,
                dataType: 'html',
                success: function(data) {
                    self.$('.modal-body').html(data);
                }
            });

            this.$('tbody tr').addClass('selectable');

            this.$('table').dataTable({
                "bPaginate": true,
                "bSort":true,
                "bProcessing": false,
                "sDom": 'Rlfrtip',
                "bRetrieve":true,
            });

            return this;
        },

        show: function(pos_elem) {
            var self = this;
            this.$el.appendTo($('body')).modal({ backdrop: false });

            if (pos_elem !== undefined) {
                var pos = _.extend(
                    {},
                    $(pos_elem).offset(),
                    { height: $(pos_elem)[0].offsetHeight }
                );

                this.$el.css({
                    width: 'auto',
                    top: pos.top + pos.height + 5,
                    left: pos.left,
                    margin: 0
                });
            } else {
                this.$el.css({
                    width: 'auto',
                    'margin-left': function () { return -self.$el.width() / 2; }
                });
            }
        },

        select: function(event) {
            var dataset_id = $(event.currentTarget).data('dataset');
            this.$el.trigger('select-dataset', [dataset_id]);
            this.dismiss();
        },

        disable_rows: function(row_ids) {
            this.$('tbody tr').each(function () {
                if (_.contains(row_ids, $(this).data('dataset'))) {
                    $(this).removeClass('selectable');
                }
            });
        },

        initialize: function() {
            this.render();
        }
    });
})();
