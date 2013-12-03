(function() {
    PointGroupSettingsView = Backbone.View.extend({
        tagName: 'div',
        className: 'modal hide',
        id: 'point-group-settings',
        template: _.template($('#tmpl-point-group-settings').html()),

        events: {
            'hidden':                            'remove',
            'change  .group-fill .is-enabled':   'toggle_fill',
            'change  .group-stroke .is-enabled': 'toggle_stroke',
            'click   .action-save':              'save',
        },

        save: function() {
            var attrs = { stroke: null, 'stroke-width': null, fill: null };
            if (this.$('.group-fill .is-enabled')[0].checked) {
                attrs.fill = this.$('.group-fill .colour').spectrum('get').toHexString();
            }
            if (this.$('.group-stroke .is-enabled')[0].checked) {
                attrs['stroke-width'] = '4px';
                attrs.stroke = this.$('.group-stroke .colour').spectrum('get').toHexString();
            }
            this.group.setStyle(attrs);
        },

        // XXX: re-enabling the colour picker control doesn't work.
        toggle_fill: function() {
            // this.$('.group-fill .colour').spectrum({ disabled: !this.$('.group-fill .is-enabled')[0].checked });
        },

        toggle_stroke: function() {
            // this.$('.group-stroke .colour').spectrum({ disabled: !this.$('.group-stroke .is-enabled')[0].checked });
        },

        remove: function() {
            this.$el.remove();
        },

        dismiss: function() {
            this.$el.modal('hide');
        },

        show: function(pos_elem) {
            var self = this;
            this.$el.appendTo($('body')).modal({ backdrop: false });

            if (pos_elem !== undefined) {
                var pos = _.extend(
                    {},
                    $(pos_elem).offset(),
                    { height: $(pos_elem)[0].offsetHeight }
                );

                this.$el.css({
                    width: 'auto',
                    top: pos.top + pos.height + 5,
                    left: pos.left,
                    margin: 0
                })
            } else {
                this.$el.css({
                    width: 'auto',
                    'margin-left': function () { return -self.$el.width() / 2; }
                });
            }
        },

        render: function() {
            this.$el.html(this.template());

            this.$('.group-fill .is-enabled')[0].checked = this.group.style.fill !== null;
            // this.$('.group-fill .colour').spectrum({ disabled: this.group.style.fill === null });

            this.$('.group-stroke .is-enabled')[0].checked = this.group.style.stroke !== null;
            // this.$('.group-stroke .colour').spectrum({ disabled: this.group.style.stroke === null });

            this.$('.colour').spectrum({ showInput: false, showButtons: false });

            this.$('.group-fill .colour').spectrum('set', this.group.style.fill);
            this.$('.group-stroke .colour').spectrum('set', this.group.style.stroke);
            return this;
        },

        initialize: function(options) {
            this.group = options.group;
        }
    });

    PointGroupView = Backbone.View.extend({
        tagName: 'div',
        className: 'point-group',
        template: _.template($('#tmpl-point-group').html()),
        events: {
            'change input':             'change',
            'click  .sg-add':           'add',
            'click  .sg-remove':        'remove',
            'click  .sg-clear':         'clear',
            'click  .sg-set-selection': 'set_selection',
            'click  svg':               'settings',
        },

        settings: function() {
            var settings = new PointGroupSettingsView({ group: this.group }).render();
            settings.show(this.$el);
        },

        change: function() {
           var curr_val = _.reject(this.$('input').val().split(/\s+/), function (x) { return x === ''; });

            if (!_.isEqual(curr_val, this.value())) {
                var all = this.graph.pointIDs();
                var sel = _.filter(all, function(id) {
                    return _.find(curr_val, function(val) { return id.match(val); }) !== undefined;
                });
                this.group.set(sel);
            }
        },

        value: function() {
            return this.group.all();
        },

        add: function() {
            var sel = this.graph.getSelection();
            this.graph.setSelection([]);
            this.group.add(sel);
        },

        remove: function() {
            var sel = this.graph.getSelection();
            this.graph.setSelection([]);
            this.group.rem(sel);
        },

        clear: function() {
            this.group.clear();
        },

        set_selection: function() {
            this.graph.setSelection(this.value());
        },

        serialize: function() {
        },

        createLegend: function() {
            var self = this;
            var svg = d3.select(this.$('svg')[0]);
            svg.selectAll('*').remove();
            this.graph.legendSymbol(svg, this.group);
            svg.select('g').attr('transform', 'translate(8,11)');
        },

        update: function() {
            this.$('input').val(this.value().join(' '));
        },

        groupNameChanged: function() {
        },

        groupStyleChanged: function() {
            console.log(this.group.style);
            this.createLegend();
        },

        groupChanged: function() {
            this.update();
        },

        render: function() {
            this.$el.html(this.template());
            this.createLegend();
            return this;
        },

        initialize: function(options) {
            this.group = options.group;
            this.graph = options.graph;
            this.group.on('change',       _.bind(this.groupChanged,      this));
            this.group.on('change:name',  _.bind(this.groupNameChanged,  this));
            this.group.on('change:style', _.bind(this.groupStyleChanged, this));
        },
    });
})();

