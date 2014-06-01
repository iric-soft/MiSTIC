define(["underscore", "backbone", "jquery", "modal_base", "dt_plugins"], function(_, Backbone, $, mb) {
    "use strict"; // jshint ;_;

    var DatasetSelector = mb.ModalBase.extend({
        title: 'Dataset selector',

        events : function() {
            return _.extend({}, _.result(mb.ModalBase.prototype, 'events'), {
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

        render: function() {
            mb.ModalBase.prototype.render.call(this);

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

        select: function(event) {
            var dataset_id = $(event.currentTarget).data('dataset');
            this.$el.trigger('select-dataset', [dataset_id]);
            this.dismiss();
        },

        disable_rows: function(row_ids) {
            console.log(row_ids)
            this.$('tbody tr').each(function () {
                if (_.contains(row_ids, $(this).data('dataset'))) {
                    $(this).removeClass('selectable');
                }
            });
        },
    });

    return {
       DatasetSelector: DatasetSelector
    };
});
