(function($){
    "use strict"; // jshint ;_;

    var GODropdownItemView = DropdownItemView.extend({
        template: _.template("<span class='label'><%- id %></span> <%- get('name') %>"),
        itemClass: function() { return 'go-'+this.model.get('namespace'); }
    });

    var GODropdown = Dropdown.extend({
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

        searchData: function() {
            return { q: this.$el.val() };
        }
    });

    window.GODropdown = GODropdown;
})(window.jQuery);

