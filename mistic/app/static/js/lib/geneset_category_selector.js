(function() {
    GenesetCategorySelector = ModalBase.extend({
        footer: _.template('<button class="btn btn-primary modal-save">Save</button><button class="btn btn-primary modal-clear">Clear</button>'),

        events: function() {
            return _.extend({}, _.result(ModalBase.prototype, 'events'), {
                'click .modal-save':                                                 'saveClicked',
                'click .modal-clear':                                                'clearClicked',
                'change ul.geneset-cat-list > li > label > input[type="checkbox"]':  'changeCat',
                'change ul.geneset-type-list > li > label > input[type="checkbox"]': 'changeType',
            });
        },

        title: 'Geneset category filter',

        changeType: function(event) {
            var tgt = $(event.currentTarget);
            var checked = tgt.prop("checked");
            var type_id = tgt.data("geneset-type");
            var categories = this.$("input[data-geneset-cat^='" + type_id + ".']");

            categories.each(function() { $(this).prop("checked", checked) });

            return false;
        },

        changeCat: function(event) {
            var tgt = $(event.currentTarget);
            var cat_id = tgt.data('geneset-cat');
            var type_id = cat_id.split('.')[0];

            var checked = tgt.prop("checked");
            var siblings = this.$("input[data-geneset-cat^='" + type_id + ".']");
            var states = _.map(siblings, function(x) { return $(x).prop('checked'); });
            var parent = this.$("input[data-geneset-type='" + type_id + "']");

            if (_.contains(states, true)) {
                if (_.contains(states, false)) {
                    parent.prop('indeterminate', true);
                } else {
                    parent.prop('indeterminate', false);
                    parent.prop('checked', true);
                }
            } else {
                parent.prop('indeterminate', false);
                parent.prop('checked', false);
            }

            return false;
        },

        getBody: function() {
            var body_text = '';
            $.ajax({
                url: '/modal/geneset_categories/' + this.options.dataset,
                data: {},
                async: false,
                dataType: 'html',
                success: function(data) {
                    body_text = data;
                }
            });
            return body_text;
        },

        show: function(pos_elem) {
            var result = ModalBase.prototype.show.call(this, [pos_elem]);

            this.$('.modal-body').css('max-height', 200);
            this.$('.modal-body').css('overflow', 'scroll');

            return result;
        },

        clearClicked: function(event) {
            this.dismiss();
            this.trigger('GenesetCategorySelector:update', []);
            return false;
        },

        saveClicked: function(event) {
            this.dismiss();
            var categories = this.$("input[data-geneset-cat]:checked");
            var selected_categories = _.map(categories, function(x) { return $(x).data('geneset-cat'); });
            this.trigger('GenesetCategorySelector:update', selected_categories);
            return false;
        },

        select: function(event) {
        }
    });
})();
