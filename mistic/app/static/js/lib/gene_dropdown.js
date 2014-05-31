define(["underscore", "jquery", "dropdown"], function(_, $, dropdown) {
    "use strict"; // jshint ;_;

    var GeneItemView = dropdown.DropdownItemView.extend({
        template: _.template("<span class='label'><%- get('id') %></span><%- get('name') %>"),
        itemClass: 'gene-item'
    });

    var GeneDropdown = dropdown.Dropdown.extend({
        item_view: GeneItemView,

        autofillText: function(model) {
            if (model !== undefined && model !== null) {
                var symbol = model.get('symbol') ? model.get('symbol') : model.get('id')
                return symbol + ' ' + model.get('name');
            }
            return '';
        },

        initialize: function(options) {
            dropdown.Dropdown.prototype.initialize.call(this, options);
            this.extra_args = options.extra_args || {};
        },

        searchData: function() {
            return _.extend(
                { },
                this.extra_args,
                { q: this.$el.val(), });
        }
    });

    return {
        GeneItemView: GeneItemView,
        GeneDropdown: GeneDropdown
    };
});
