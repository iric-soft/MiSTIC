(function() {
    PointGroupView = Backbone.View.extend({
        tagName: 'div',
        className: 'point-group',
        template: _.template($('#tmpl-point-group').html()),
        events: {
            'change input':             'change',
            'click  .sg-add':           'add',
            'click  .sg-remove':        'remove',
            'click  .sg-clear':         'clear',
            'click  .sg-set-selection': 'set_selection'
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

        render: function() {
            this.$el.html(this.template());
            return this;
        },

        update: function() {
            this.$('input').val(this.value().join(' '));
        },

        groupChanged: function() {
            this.update();
        },

        initialize: function(options) {
            this.group = options.group;
            this.graph = options.graph;
            this.group.on('change', _.bind(this.groupChanged, this));
        },
    });
})();

