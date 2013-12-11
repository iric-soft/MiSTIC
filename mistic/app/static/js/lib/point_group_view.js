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
                get_state:  function(x) {
                    switch (x) {
                    case null:      return 'disabled';
                    case undefined: return 'inherit';
                    default:        return 'enabled';
                    }
                },
                selected:   function(x) { return x ? ' selected' : ''; },
                active:     function(x) { return x ? ' active' : ''; },
                colour:     function(x) { return x ? x : 'transparent'; },
                group:      this.group,
                style:      this.group.get('style'),
            }));

            this.$('.colour').spectrum({
                showInput: false,
                showButtons: false,
                showAlpha: true,
                change: function(colour) {
                    $('span', this).css('background-color', $(this).spectrum('get').toRgbString());
                },
                beforeShow: function(colour) {
                    if ($(this).hasClass('disabled')) return false;
                    $(this).spectrum('set', $('span', this).css('background-color'));
                    console.log(this);
                },
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
            'click  .shift-up':         'shift_up',
            'click  .shift-dn':         'shift_dn',
        },

        remove: function() {
            this.group.collection.remove(this.group);
        },

        shift_up: function() {
            var col = this.group.collection;
            var index = col.indexOf(this.group);
            if (index > 0) {
                col.remove(this.group, { silent: true });
                col.add(this.group, { at: index - 1, silent: true });
                col.trigger('sort', col, {});
            }
        },

        shift_dn: function() {
            var col = this.group.collection;
            var index = col.indexOf(this.group);
            if (index < col.length - 1) {
                col.remove(this.group, { silent: true });
                col.add(this.group, { at: index + 1, silent: true });
                col.trigger('sort', col, {});
            }
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
            this.graph.clearBrush();
            this.group.addPoints(sel);
        },

        remove_points: function() {
            var sel = this.graph.getSelection();
            this.graph.setSelection([]);
            this.graph.clearBrush();
            this.group.removePoints(sel);
        },

        clear_points: function() {
            this.group.clearPoints();
        },

        set_selection: function() {
            this.graph.setSelection(this.value());
            this.graph.clearBrush();
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
            this.updateStyle();
            this.updatePoints();
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



    PointGroupListView = Backbone.View.extend({
        tagName: 'div',
        className: 'point-group-list',
        events: {
        },

        groupAdded: function(group) {
            var view = new PointGroupView({ group: group, graph: this.graph });
            var index = this.groups.indexOf(group);
            if (index == this.model_views.length) {
                this.model_views.push(view);
                this.$el.append(view.render().el);
            } else {
                var insert_before = this.model_views[index];
                this.model_views.splice(index, 0, view);
                insert_before.$el.before(view.render().el);
            }
            _.each(this.model_views, function (v) { v.updateName(); });
        },

        groupRemoved: function(group, collection, options) {
            var index = options.index;
            var view = this.model_views.splice(index, 1)[0];
            view.$el.remove();
            _.each(this.model_views, function (v) { v.updateName(); });
        },

        groupsReordered: function() {
            var self = this;
            var new_order = [];
            _.each(this.model_views, function (v) { new_order[self.groups.indexOf(v.group)] = v; });
            this.model_views = new_order;
            _.each(this.model_views, function (v) { v.updateName(); self.$el.append(v.el); });
        },

        groupsReset: function() {
            this.model_views = [];
            this.$el.empty();

            for (var i = 0; i < this.groups.length; ++i) {
                var view = new PointGroupView({ group: this.groups.at(i), graph: this.graph });
                this.model_views.push(view);
                this.$el.append(view.render().el);
            }
            _.each(this.model_views, function (v) { v.updateName(); });
        },

        initialize: function(options) {
            this.groups = options.groups;
            this.graph = options.graph;

            this.model_views = [];

            this.groupsReset();

            this.groups.on('add',    _.bind(this.groupAdded, this));
            this.groups.on('remove', _.bind(this.groupRemoved, this));
            this.groups.on('reset',  _.bind(this.groupsReset, this));
            this.groups.on('sort',   _.bind(this.groupsReordered, this));
        },
    });
})();

