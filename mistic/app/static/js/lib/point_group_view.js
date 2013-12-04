(function() {
    PointGroupSettingsView = Backbone.View.extend({
        tagName: 'div',
        className: 'modal hide',
        id: 'point-group-settings',
        template: _.template($('#tmpl-point-group-settings').html()),

        events: {
            'hidden':                            'remove',
            'change  .group-fill .state':        'toggle_fill',
            'change  .group-stroke .state':      'toggle_stroke',
            'click   .action-save':              'save',
        },

        save: function() {
            var attrs = {};

            switch (this.$('.group-fill .state').val()) {
            case 'enabled':
                attrs.fill = this.$('.group-fill .colour span').css('background-color');
                break;
            case 'disabled':
                attrs.fill = null;
                break;
            }

            switch (this.$('.group-stroke .state').val()) {
            case 'enabled':
                attrs.stroke = this.$('.group-stroke .colour span').css('background-color');
                attrs['stroke-width'] = this.$('.group-stroke .stroke-width').val();
                break;
            case 'disabled':
                attrs.stroke = null;
                attrs['stroke-width'] = null;
                break;
            }

            var shape = this.$('.group-shape .state .active').data('value');
            if (shape !== 'inherit') {
                attrs._shape = shape;
                attrs.d = d3.svg.symbol().type(shape)();
            }

            this.group.setStyle(attrs);
        },

        // XXX: re-enabling the colour picker control doesn't work.
        toggle_fill: function() {
            var state = this.$('.group-fill .state').val();
            this.$('.group-fill .colour').toggleClass('disabled', state != 'enabled');
        },

        toggle_stroke: function() {
            var state = this.$('.group-stroke .state').val();
            this.$('.group-stroke .colour').toggleClass('disabled', state != 'enabled');
            this.$('.group-stroke .stroke-width').prop('disabled', state != 'enabled');
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
            var self = this;

            this.$el.html(this.template());

            var _state = function(x) {
                return x === null ? 'disable' : x === undefined ? 'inherit' : 'enable';
            }

            this.$('.group-fill .state').val(_state(this.group.style.fill));
            this.$('.group-stroke .state').val(_state(this.group.style.stroke));

            this.$('.group-fill .colour span').css('background-color', this.group.style.fill);
            this.$('.group-stroke .colour span').css('background-color', this.group.style.stroke);

            this.$('.colour').spectrum({
                change: function(colour) {
                    $('span', this).css('background-color', $(this).spectrum('get').toHexString());
                },
                beforeShow: function(colour) {
                    if ($(this).hasClass('disabled')) return false;
                    $(this).spectrum('set', $('span', this).css('background-color'));
                    console.log(this);
                },
                showInput: false,
                showButtons: false
            });

            this.toggle_fill();
            this.toggle_stroke();

            var options = d3.select(this.$('.group-shape .state')[0])
                .selectAll('span')
                .data(d3.svg.symbolTypes);

            options
                .enter()
                .append('span')
                .classed('btn', true)
                .classed('active', function(d) { self.group.style._shape === d; })
                .attr('data-value', function(d) { return d; })
                .style('padding', '2px 3px')
                .append('svg')
                .attr('width', 16)
                .attr('height', 17)
                .append('g')
                .attr('transform', 'translate(8,10)')
                .append('path')
                .attr('fill', '#000')
                .attr('d', function(d) { return d3.svg.symbol().type(d)() });

            if (this.group.style._shape === undefined) {
                this.$('.group-shape .state a').addClass('active')
            }

            this.$('.group-shape .state').button();

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
            'click  .sg-style':         'settings',
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
            svg.select('g').attr('transform', 'translate(8,10)');
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

