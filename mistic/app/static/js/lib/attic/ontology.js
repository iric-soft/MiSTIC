(function() {
    GOTerm = Backbone.Model.extend();

    GO = Backbone.Collection.extend({
        model: GOTerm
    });

    GOItem = Backbone.View.extend({
        tagName: 'li',
        className: 'menu-item',
        template: _.template('<strong class="go-<%= m.get("namespace") %>"><%- m.id %></strong> <%- m.get("desc") %>'),

        render: function() {
            this.$el.data({ model: this.model });

            this.$el.html(this.template({ m: this.model }));

            return this;
        }
    });

    GOEntry = Backbone.View.extend({
        events: {
            'blur':      'blur',
            'focus':     'focus',
            'keydown':   'keydown',
            'keypress':  'keypress',
            'keyup':     'keyup',
        },

        select: function(model) {
            if (model !== undefined) {
                this.$el.val(model.id);
                this.$el.addClass('valid');
            } else {
                this.$el.removeClass('valid');
            }
            if (model !== this.last_selection) {
                this.trigger('select:go', model);
                this.last_selection = model;
            }
        },

        blur: function(event) {
            this.menu.hide();
        },

        focus: function(event) {
        },

        input: function(event) {
        },

        keydown: function(event) {
        },

        keypress: function(event) {
        },

        keyup: function(event) {
            this.update();
            this.valueChanged();
        },

        valueChanged: function() {
            if (this.goterms !== undefined) {
                this.select(this.goterms.get(this.$el.val()));
            }
        },

        reposition: function() {
            var margin_left   = parseInt(this.$el.css("marginLeft")) || 0;
	    var margin_top    = parseInt(this.$el.css("marginTop"))  || 0;
            var width         = this.$el.outerWidth();
	    var height        = this.$el.outerHeight();
            var pos           = this.$el.offset();
            var menu_width    = this.menu.outerWidth();
            var menu_height   = this.menu.outerHeight();
            if (menu_width < width) {
                var pl = parseFloat(this.menu.css('paddingLeft')) || 0;
                var pr = parseFloat(this.menu.css('paddingRight')) || 0;
                var bl = parseFloat(this.menu.css('borderLeftWidth')) || 0;
                var br = parseFloat(this.menu.css('borderRightWidth')) || 0;

                this.menu.width(width - pl -pr -bl - br);
            }
            this.menu.css({ left: pos.left, top: pos.top + height });
        },

        renderMatches: function(matches) {
            var self = this;
            var ul = this.menu;
            ul.empty();

            if (matches.length == 0) {
                ul.hide();
            } else {
                _.each(matches, function(match) {
                    var item = new GOItem({ model: match });
                    item.on('select', function(goterm) { self.selectItem(goterm); });
                    ul.append(item.render().el);
                });

                var width = Math.max(ul.width("").outerWidth(), this.$el.outerWidth());
                var pos = this.$el.offset();

                this.reposition();
                ul.show();
            }
        },

        update: function() {
            var v = this.$el.val();
            if (this.goterms !== undefined && v.length != 0) {
                var v_regex = new RegExp(v, 'i');
                var matches = this.goterms.filter(function(goterm) {
                    return v_regex.test(goterm.id) || v_regex.test(goterm.get('desc'));
                });
                if (matches.length < 100) {
                    this.renderMatches(matches);
                } else {
                    this.menu.empty().hide();
                }
            } else {
                this.menu.empty().hide();
            }
        },

        changeList: function(goterms) {
            if (this.goterms !== undefined) {
                this.goterms.off(null, null, this);
            }
            this.goterms = goterms;
            if (this.goterms !== undefined) {
                this.goterms.on("add remove reset", this.update, this);
            }
            this.$el.val('');
        },

        click: function(event) {
            event.preventDefault();
            var item = $(event.target).closest('.menu-item');
            if (item.length) {
                var model = $(item[0]).data('model');
                this.select(model);
                this.menu.hide();
            }
        },

        initialize: function() {
            var self = this;

            this.goterms = undefined;
            this.last_selection = undefined;

            this.menu = $('<ul></ul>')
                .addClass('menu')
                .hide()
                .appendTo($('body')[0])
                .mousedown(function(event) { self.click(event); });
        }
    });
})();
