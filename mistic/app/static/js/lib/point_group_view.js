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
            'keypress':                          'squashSubmit',
        },

        squashSubmit: function(e) {
            if (e.keyCode == 13) e.preventDefault();
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
                if (this.$('.group-stroke .stroke-width').val() !== 'inherit') {
                    attrs['stroke-width'] = this.$('.group-stroke .stroke-width').val();
                }
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

            this.group.set('name', $('.group-name').val() || undefined);
            this.group.set('style', attrs);
        },

        // XXX: re-enabling the colour picker control doesn't work.
        toggle_fill: function() {
            var state = this.$('.group-fill .state').val();
            this.$('.group-fill .colour').toggleClass('disabled', state != 'enabled');
            this.$('.selectpicker').selectpicker('refresh');
        },

        toggle_stroke: function() {
            var state = this.$('.group-stroke .state').val();
            this.$('.group-stroke .colour').toggleClass('disabled', state != 'enabled');
            this.$('.group-stroke .stroke-width').prop('disabled', state != 'enabled');
            this.$('.selectpicker').selectpicker('refresh');
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

            this.$el.html(this.template({
                capitalize: function(x) { return x.charAt(0).toUpperCase() + x.slice(1); },
                get_state:  function(x) { return x === null ? 'disable' : x === undefined ? 'inherit' : 'enable'; },
                selected:   function(x) { return x ? ' selected' : ''; },
                active:     function(x) { return x ? ' active' : ''; },
                colour:     function(x) { return x ? x : 'transparent'; },
                group:      this.group,
                style:      this.group.get('style'),
            }));

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

            this.$('.group-shape .state').button();
            this.$('.selectpicker').selectpicker();
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
            'click  .sg-add':           'add_points',
            'click  .sg-remove':        'remove_points',
            'click  .sg-clear':         'clear_points',
            'click  .sg-set-selection': 'set_selection',
            'click  .sg-style':         'settings',
            'click  .close':            'remove',
        },

        remove: function() {
            this.group.collection.remove(this.group);
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
                this.group.setPoints(sel);
            }
        },

        value: function() {
            return this.group.get('point_ids');
        },

        add_points: function() {
            var sel = this.graph.getSelection();
            this.graph.setSelection([]);
            this.group.addPoints(sel);
        },

        remove_points: function() {
            var sel = this.graph.getSelection();
            this.graph.setSelection([]);
            this.group.removePoints(sel);
        },

        clear_points: function() {
            this.group.clearPoints();
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

        name: function() {
            if (this.group.get('name') !== undefined) {
                return this.group.get('name')
            } else {
                return $('<i>').text('Group ' + (this.group.collection.indexOf(this.group)+1));
            }
        },

        updateName: function() {
            this.$('.header span').html(this.name());
        },

        updateStyle: function() {
            this.createLegend();
        },

        updatePoints: function() {
            this.$('input').val(this.value().join(' '));
        },

        render: function() {
            this.$el.html(this.template({
                view:  this,
                group: this.group,
                style: this.group.get('style'),
            }));
            this.createLegend();
            return this;
        },

        initialize: function(options) {
            this.group = options.group;
            this.graph = options.graph;

            this.group.on('change:point_ids', _.bind(this.updatePoints, this));
            this.group.on('change:name',      _.bind(this.updateName, this));
            this.group.on('change:style',     _.bind(this.updateStyle, this));
        },
    });
})();

