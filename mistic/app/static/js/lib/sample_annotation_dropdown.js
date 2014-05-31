define(["underscore", "jquery", "dropdown"], function(_, $, dropdown) {
    "use strict"; // jshint ;_;

    var SampleAnnotationItemView = dropdown.DropdownItemView.extend({
        template: _.template("<span class='label label-inverse'><%- get('key') %></span> <%- get('values') %>"),
        itemClass: function() {
            return this.model.get('key');
        }
    });

    var SampleAnnotationDropdown = dropdown.Dropdown.extend({
        item_view: SampleAnnotationItemView,
        max_items: 1500,
        menu: '<ul class="typeahead dropdown-menu" style="width:auto;max-width: 400px; max-height: 400px; overflow-x: hidden; overflow-y: auto"></ul>',

        autofillText: function(model) {
            if (model !== undefined && model !== null) {
                return model.get('key') + ' : ' + model.get('values');
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
        SampleAnnotationDropdown: SampleAnnotationDropdown
    };
});
