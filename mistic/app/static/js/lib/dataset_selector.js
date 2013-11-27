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
                url: '/modal/datasets',
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

        show: function() {
            this.$el.appendTo($('body')).modal({ backdrop: false, keyboard: false });
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
