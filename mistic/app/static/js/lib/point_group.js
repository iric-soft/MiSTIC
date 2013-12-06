(function() {
    PointGroup = Backbone.Model.extend({
        defaults: {
            name: undefined,
            style: {},
            point_ids: []
        },
        initialize: function() {
            this.point_ids = {};
        },
        clearPoints: function() {
            this.point_ids = {};
            this.set('point_ids', []);
        },
        hasPoint: function(id) {
            return !!this.point_ids[id];
        },
        addPoints: function(ids) {
            var self = this;
            var changed = false;
            _.each(ids, function (id) {
                if (!self.point_ids[id]) {
                    self.point_ids[id] = true;
                    changed = true;
                }
            });
            if (changed) {
                var point_ids = _.keys(this.point_ids);
                point_ids.sort();
                this.set('point_ids', point_ids);
            }
        },
        removePoints: function(ids) {
            var self = this;
            var changed = false;
            _.each(ids, function (id) {
                if (self.point_ids[id]) {
                    delete self.point_ids[id];
                    changed = true;
                }
            });
            if (changed) {
                var point_ids = _.keys(this.point_ids);
                point_ids.sort();
                this.set('point_ids', point_ids);
            }
        },
        setPoints: function(ids) {
            var self = this;
            this.point_ids = {};
            _.each(ids, function (id) {
                self.point_ids[id] = true;
            });
            var point_ids = _.keys(this.point_ids);
            point_ids.sort();
            this.set('point_ids', point_ids);
        },
    });

    PointGroupCollection = Backbone.Collection.extend({
        model: PointGroup,
    });
})();
