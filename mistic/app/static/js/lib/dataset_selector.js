(function() {
    DatasetSelector = ModalBase.extend({
        title: 'Dataset selector',

        events : function() {
            return _.extend({}, _.result(ModalBase.prototype, 'events'), {
                'click tbody tr.selectable': 'select',
            });
        },

        getBody: function() {
            var body_text = '';
            $.ajax({
                url: '/modal/datasets',
                data: {},
                async: false,
                dataType: 'html',
                success: function(data) {
                    body_text = data;
                }
            });
            return body_text;
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
    });
})();
