(function($){
    "use strict"; // jshint ;_;

    var DropdownItemView = Backbone.View.extend({
        tagName: 'span',
        template: _.template("<%- get('label') %>"),

        render: function() {
            this.$el.html(this.template(this.model));
            this.$el.highlight_text(this.search);
            if ($.isFunction(this.itemClass)) {
                this.$el.addClass(this.itemClass.call(this));
            } else {
                this.$el.addClass(this.itemClass);
            }
            return this;
        },

        initialize: function(options) {
            this.search = options.search;
        }
    });

    var Highlighter = function(search) {
        this.terms = $.grep(search.split(/\s+/), function(s) { return s.length > 0; });
        this.re = new RegExp(
            $.map(this.terms,
                  function(x) {
                      return '(' + x.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&') + ')';
                  }).join('|'), 'gi');
    }

    Highlighter.unhighlight = function(node) {
        var hl = $('strong.highlight', node);
        var hlp = hl.parent();
        hl.each(function(idx, node) { $(node).replaceWith(document.createTextNode($(node).text())); });
        hlp.each(function(idx, node) { node.normalize(); });
    };

    Highlighter.prototype.highlight = function(node) {
        var self = this;
        if (this.terms.length === 0) return;

        $('*', node)
            .andSelf()
            .contents()
            .filter(function() { return this.nodeType == 3; })
            .each(function(idx, node) {
            var m, out = [], txt = node.textContent, pos = 0;
            while ((m = self.re.exec(txt)) !== null) {
                if (pos < m.index) {
                    out.push(document.createTextNode(txt.substring(pos, m.index)));
                }
                out.push($('<strong>').addClass('highlight').text(m[0])[0]);
                pos = m.index + m[0].length;
            }
            if (out.length) {
                if (pos < txt.length) {
                    out.push(document.createTextNode(txt.substring(pos)));
                }
                $(node).replaceWith(out);
            }
        });
    };

    window.DropdownItemView = DropdownItemView;
    window.Highlighter = Highlighter;

    $.fn.unhighlight_text = function() {
        Highlighter.unhighlight(this);
    }

    $.fn.highlight_text = function(hl) {
        hl = new Highlighter(hl);
        this.each(function() { hl.highlight(this); });
    }

    window.Dropdown = Backbone.View.extend({
        tagName: 'input',
        attributes: { type: 'text' },

        events: {
            'click':    'empty',
            'change':   'update',
            'keydown':  'keydown',
            'keyup':    'keyup',
            'keypress': 'keypress',
            'blur':     'blur',
        },

        menu: '<ul class="typeahead dropdown-menu"></ul>',
        item: '<li><a href="#"></a></li>',
        trailer: _.template('<li>(<%- remain %> more)</li>'),

        item_view: window.DropdownItemView,
        max_items: 10,
        url: undefined,

        hasScroll: function() {
	    return this.$menu.outerHeight() < this.$menu[0].scrollHeight;
        },

        scrollToItem: function(item) {
	    if (this.hasScroll()) {
		var borderTop = parseFloat($.css(this.$menu[0], "borderTopWidth")) || 0;
		var paddingTop = parseFloat($.css(this.$menu[0], "paddingTop")) || 0;
		var offset = item.offset().top - this.$menu.offset().top - borderTop - paddingTop;
		var scroll = this.$menu.scrollTop();
		var menuHeight = this.$menu.height();
		var itemHeight = item.height();

		if ( offset < 0 ) {
		    this.$menu.scrollTop(scroll + offset);
		} else if (offset + itemHeight > menuHeight) {
		    this.$menu.scrollTop(scroll + offset - menuHeight + itemHeight);
		}
	    }
        },

        activeItem: function() {
            
            var active = this.$menu.find('.active');
            if (active.length === 0) return null;
            return this.collection.get(active.attr('data-id'));
        },

        autofillText: function(model) {
            return model.get('label');
        },

       
        selectActive: function() {
            this.selectItem(this.activeItem());
        },

      
        selectItem: function(item) {
            if (item === this.selected_item) {
                return;
            }

            if (item !== null) {
                var txt = this.autofillText(item);
                this.$el.val(txt);
                this.selected_item = item;
                this.selected_text = txt;
               
            } else {
                this.selected_item = null;
                this.selected_text = null;
            }
           
            this.trigger('change', this.selected_item);
            this.hide();
        },

        toggle: function() {
            if (this.shown) {
                this.hide();
            } else {
                this.show();
            }
        },

        show: function() {
            if (!this.shown) {
                var pos = _.extend(
                    {},
                    this.$el.offset(),
                    { height: this.$el[0].offsetHeight }
                );

                this.$menu.css({
                    top: pos.top + pos.height,
                    left: pos.left
                })

                this.$menu.show()
                this.shown = true
            }
        },

        hide: function() {
            if (this.shown) {
                this.$menu.hide()
                this.shown = false;
            }
        },

        beginFetching: function(url, data) {
            if (url === null ||
                this.fetching_items ||
                _.isEqual(this.current_search, [url, data])) {
                return;
            }

            this.fetching_items = true;
            this.current_search = [url, data];
            this.collection.url = url;
            this.collection.fetch({ data: data }).done(_.bind(this.afterFetch, this));
        },

        afterFetch: function() {
            this.fetching_items = false;
            this.beginFetching(this.searchURL(), this.searchData());
        },

        setSearchURL: function(url) {
            this.url = url;
            this.$el.attr('disabled', this.url === undefined);
        },

        searchURL: function() {
            return this.url;
        },

        searchData: function() {
            return {};
        },

        update: function(event) {
            if (this.selected_text !== null && this.$el.val() === this.selected_text) {
                return;
            }
            this.beginFetching(this.searchURL(), this.searchData());
            if (this.$el.val() !== this.selected_text) {
                this.selectItem(null);
            }
            this.renderItems();
            this.show();
        },

        collectionChange: function() {
            var self = this;
            this.need_render = true;
            setTimeout(
                function() {
                    if (self.need_render) {
                        self.renderItems();
                        delete self.need_render;
                    }
                },
                0);
        },

        renderItems: function() {
            var self = this
            var search = this.$el.val();

            var items = this.collection.first(this.max_items).map(function(item) {
                var content = new self.item_view({ model: item, search: search }).render().$el;
                var el = $(self.item);
                el.attr({ 'data-id': item.id });
                el.find('a').append(content);
                if (item === self.selected_item) {
                    el.addClass('active');
                }
                return el[0];
            });

            this.$menu.html(items);

            if (this.collection.length > this.max_items) {
                this.$menu.add($(self.trailer({
                    total: this.collection.length,
                    remain: this.collection.length - this.max_items
                })));
            }

            if (this.collection.length === 0) {
                this.hide();
            } else {
                this.show();
            }
        },

        next: function (event) {
            var active = this.$menu.find('.active');
            var next = active.next();
            if (!next.length) {
                next = $(this.$menu.find('li')[0])
            }
            active.removeClass('active');
            next.addClass('active');
            this.scrollToItem(next);
        },

        prev: function (event) {
            var active = this.$menu.find('.active')
            var prev = active.prev();
            if (!prev.length) {
                prev = this.$menu.find('li').last()
            }
            active.removeClass('active');
            prev.addClass('active');
            this.scrollToItem(prev);
        },

        keydown: function(event) {
            switch(event.keyCode) {
            case 9:
            case 13:
            case 27: {
                if (this.shown) {
                    event.preventDefault();
                }
                break;
            }
            case 38: {
                // up arrow
                this.show();
                this.prev();
                event.preventDefault();
                break;
            }
            case 40: {
                // down arrow
                this.show();
                this.next();
                event.preventDefault();
                break;
            }
            }
        },

        keyup: function(event) {
            if (this.shown) {
                switch(event.keyCode) {
                case 9:
                case 13: {
                    this.selectActive();
                    event.preventDefault();
                    return;
                }
                case 27: {
                    this.hide();
                    event.preventDefault();
                    return;
                }
                case 38:
                case 40: {
                    event.preventDefault();
                    return;
                }
                }
            }
            this.update(event)
        },

        keypress: function(event) {
            switch(event.keyCode) {
            case 9:
            case 13:
            case 27: {
                if (this.shown) {
                    event.preventDefault();
                }
                break;
            }
            case 38:
            case 40: {
                event.preventDefault();
            }
            }
        },

        blur: function(event) {
            if (this.cancel_blur) {
                delete this.cancel_blur;
                return;
            }

            setTimeout(_.bind(this.hide, this), 0);
        },

        itemMousedown: function(event) {
            var self = this;

	    this.cancel_blur = true;
            setTimeout(function() { delete self.cancel_blur; }, 0);

            event.preventDefault();
        },

        itemClick: function(event) {
            
            var item = $(event.target).closest('li');
            this.$menu.find('.active').removeClass('active')
            item.addClass('active')
            this.selectActive();
            return false;
        },

        render: function() {
        },
        
        empty: function(event){
            $(event.target).val('');
        },
        
        initialize: function(options) {
            var self = this;

            if (options.collection !== undefined) {
                this.collection = options.collection;
            } else {
                this.collection = new Backbone.Collection();
            }

            this.setSearchURL(options.url);

            this.fetching_items = false;
            this.current_search = null;
            this.selected_item = null;
            this.selected_text = null;

            this.collection.on('all', _.bind(this.collectionChange, this));

            this.$menu = $(this.menu);
           
            this.shown = false;
            this.$menu
                .hide()
                .appendTo($('body'))
                .on('mousedown', _.bind(this.itemMousedown, this))
                .on('click',     _.bind(this.itemClick, this));
        }
    });
})(window.jQuery);
