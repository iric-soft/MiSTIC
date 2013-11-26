(function() {
    DatasetSelector = Backbone.View.extend({
        tagName: 'div',
        className: 'modal hide',
        template: _.template(''),
        err: _.template(''),

        events: {
            'hidden': 'remove',
        },

        remove: function() {
            this.$el.remove();
        },

        dismiss: function() {
            this.$el.modal('hide');
        },

        render: function() {
            this.$el.html(this.template());
            return this;
        },

        show: function() {
            this.$el.appendTo($('body')).modal();
        },

        disable_rows: function(row_ids) {
            this.$('tbody tr').each(function () {
                if (_.contains(row_ids, $(this).data('dataset'))) {
                    $(this).removeClass('selectable');
                }
            });
        },

        initialize: function() {
            var self = this;
            $.ajax({
                url: "/modal/datasets",
                data: { },
                async: false,
                dataType: 'html',
                success: function(data) {
                    self.template = _.template(data)
                },
                error: function() {
                    self.template = undefined;
                }
            });
            this.render();

            this.$('tbody tr').addClass('selectable');

            this.$('tbody tr').on('click', function(event) {
                if ($(this).hasClass('selectable')) {
                    var dataset_id = $(this).data('dataset');
                    self.$el.trigger('select-dataset', [dataset_id]);
                    self.dismiss();
                }
            });

            return this.$('table').dataTable({
                "bPaginate": true,
                "bSort":true,
                "bProcessing": false,
                "sDom": 'Rlfrtip',
                "bRetrieve":true,
            });
        }
    });
})();
