(function() {
    point_group = function(options) {
        this.group_id = options.group_id;
        this.style = options.style;
        this.name = options.name;
        this.point_ids = {};
        _.extend(this, Backbone.Events);
    }

    point_group.unserialize = function() {
    };

    point_group.prototype.serialize = function() {
    };

    point_group.prototype.setStyle = function(style) {
        this.style = style;
        this.trigger('change:style', this);
    };

    point_group.prototype.setName = function(name) {
        this.name = name;
        this.trigger('change:name', this);
    };

    point_group.prototype.all = function() {
        var ids = _.keys(this.point_ids);
        ids.sort();
        return ids;
    };

    point_group.prototype.clear = function(id) {
        if (!_.isEqual(this.point_ids, {})) {
            this.point_ids = {};
            this.trigger('change', this);
        }
    };

    point_group.prototype.has = function(id) {
        return !!this.point_ids[id];
    };

    point_group.prototype.add = function(ids) {
        var self = this;
        _.each(ids, function (id) {
            if (!self.point_ids[id]) {
                self.point_ids[id] = true;
                changed = true;
            }
        });
        this.trigger('change', this);
    };

    point_group.prototype.rem = function(ids) {
        var self = this;
        var changed = false;
        _.each(ids, function (id) {
            if (self.point_ids[id]) {
                delete self.point_ids[id];
                changed = true;
            }
        });
        if (changed) this.trigger('change', this);
    };

    point_group.prototype.set = function(ids) {
        var self = this;
        var changed = false;
        var new_val = {};
        _.each(ids, function (id) {
            new_val[id] = true;
        });
        changed = !_.isEqual(new_val, self.point_ids);
        self.point_ids = new_val;
        this.trigger('change');
    };
})();
