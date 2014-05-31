define(["underscore", "backbone", "jquery", "go_dropdown", "geneset_category_selector"], function(_, Backbone, $, gd, gsc) {
    "use strict"; // jshint ;_;

    var GenesetSelector = Backbone.View.extend({
        tagName: 'div',
        template: _.template($('#tmpl-geneset-selector').html()),

        events: {
            'mousedown .dropdown-toggle': 'dropdown_mousedown',
            'click     .dropdown-toggle': 'dropdown_click',
            'click     .geneset-filter':  'filter_click',
        },

        dropdown_mousedown: function(event) {
            this.shown_at_mousedown = this.geneset_entry.shown;
        },

        dropdown_click: function(event) {
            if (this.shown_at_mousedown) {
                this.geneset_entry.hide();
            } else {
                this.geneset_entry.show();
                this.geneset_entry.update();
            }
            this.geneset_entry.$el.focus();
            event.preventDefault();
        },

        filter_click: function(event) {
            this.gscat_sel.show(this.$('.geneset-filter')[0]);
            event.preventDefault();
        },

        filter_update: function(categories) {
            this.$('.geneset-filter').toggleClass('btn-warning', categories.length != 0);
            this.geneset_entry.extra_args.c = categories;
        },

        render: function() {
            this.$el.html(this.template({ self: this }));
            return this;
        },

        propagate_change: function(item) {
            this.trigger('GenesetSelector:change', item);
        },

        setDataset: function(dataset, url) {
            this.gscat_sel.setDataset(dataset);
            this.geneset_entry.setSearchURL(url);
        },

        initialize: function(options) {
            this.render();

            this.gscat_sel = new gsc.GenesetCategorySelector({ dataset: options.dataset });
            this.gscat_sel.on('GenesetCategorySelector:update', _.bind(this.filter_update, this));
            this.geneset_entry = new gd.GODropdown({
                el: this.$("input"),
                url: options.url
            });
            this.geneset_entry.on('change', _.bind(this.propagate_change, this));
        },
    });

    return {
        GenesetSelector: GenesetSelector
    };
});
