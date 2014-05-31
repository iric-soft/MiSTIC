define(["underscore", "jquery", "dropdown"], function(_, $, dropdown) {
    "use strict"; // jshint ;_;

    var GODropdownItemView = dropdown.DropdownItemView.extend({
        template: _.template("<span class='label'><%- id %></span> <%- get('name') %>"),
        itemClass: function() { return 'go-'+this.model.get('namespace'); }
    });

    var GODropdown = dropdown.Dropdown.extend({
        item_view: GODropdownItemView,
        max_items: 50,
        menu: '<ul class="typeahead dropdown-menu" style="max-width: 600px; max-height: 400px; overflow-x: hidden; overflow-y: auto"></ul>',

        autofillText: function(model) {
            if (model !== undefined && model !== null) {
                if (model.get('name')!='') {
                    return model.id + ': ' + model.get('name');
                } else {
                    return model.id ;
                }
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
        GODropdownItemView: GODropdownItemView,
        GODropdown:         GODropdown
    };
});
