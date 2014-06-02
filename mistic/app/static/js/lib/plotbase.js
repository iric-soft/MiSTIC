define(["underscore", "backbone", "jquery", "d3", "math", "utils"], function(_, Backbone, $, d3, math, utils) {
    "use strict"; // jshint ;_;

    var next_id = 0;



    var selection =  function() {
        this.sel = {};
    };

    _.extend(selection.prototype, Backbone.Events, {
        add: function(key) { this.sel[key] = true; },
        rem: function(key) { delete this.sel[key]; },
        xor: function(key) { if (this.sel[key]) { delete this.sel[key]; } else { this.sel[key] = true; } },

        click: function(key, modifiers) {
            if (!modifiers.shift) {
                this.sel = {};
            }
            this.add(key);
            this.notify();
        },

        notify: function() {
            this.trigger("selection-changed", this.sel);
        },

        addSelection: function(keys, quiet) {
            if (!_.isArray(keys)) keys = _.keys(keys);
            _.each(keys, _.bind(this.add, this));
            if (!quiet) this.notify();
        },

        remSelection: function(keys, quiet) {
            if (!_.isArray(keys)) keys = _.keys(keys);
            _.each(keys, _.bind(this.rem, this));
            if (!quiet) this.notify();
        },

        setSelection: function(keys, quiet) {
            if (!_.isArray(keys)) keys = _.keys(keys);
            this.sel = {};
            _.each(keys, _.bind(this.add, this));
            if (!quiet) this.notify();
        },

        clearSelection: function(quiet) {
            this.sel = {};
            if (!quiet) this.notify();
        },

        getSelection: function() {
            return this.sel;
        },

        brushStart: function(modifiers) {
            this.prior_sel = _.extend({}, this.sel);
            this.brush_modifiers = modifiers;
        },

        brushUpdate: function(key_list) {
            if (this.brush_modifiers.shift) {
                this.sel = _.extend({}, this.prior_sel);
                _.each(key_list, _.bind(this.add, this));
            } else {
                this.sel = {};
                _.each(key_list, _.bind(this.add, this));
            }
            this.notify();
        },

        brushEnd: function() {
            delete this.prior_sel;
            delete this.brush_modifiers;
        }
    });

    selection.extend = Backbone.Model.extend;



    var e_base = function() {
        this.id = ++next_id;
    };

    _.extend(e_base.prototype, Backbone.Events, {
        extent: function() {
            return { x: [0.0, 0.0], y: [0.0, 0.0] };
        },

        pointClick: function(k) {},
        pointIn:    function(k) {},
        pointOut:   function(k) {},

        create: function(plot, g) {
            var self = this;
            this.plot = plot;
            this.g = d3.select(g);

            this.g.on("click", function() {
                self.pointClick(d3.event.srcElement.__data__);
            });
            this.g.on("mouseover", function() {
                self.pointIn(d3.event.srcElement.__data__);
            });
            this.g.on("mouseout", function(k) {
                self.pointOut(d3.event.srcElement.__data__);
            });
        },

        destroy: function() {},

        brushStart:  function(extent) {},
        brushUpdate: function(extent) {},
        brushEnd:    function(extent) {},
    });

    e_base.extend = Backbone.Model.extend;



    var e_xy = e_base.extend({
        constructor: function(x, y) {
            e_base.call(this);

            this.x = x;
            this.y = y;
        },

        extent: function() {
            return { x: d3.extent(this.x), y: d3.extent(this.y) };
        },
    });



    var e_points = e_xy.extend({
        constructor: function(x, y, attr) {
            e_xy.call(this, x, y);

            this.attr = attr;
        },

        draw: function() {
            var self = this;
            var pt = this.g
                .selectAll("path")
                .data({ length: Math.min(this.x.length, this.y.length) })

            pt.enter().append("path");

            var sym = d3.svg.symbol().type(this.shape).size(this.size);
            pt
                .attr(_.extend({}, e_points.defaults, this.attr))
                .attr("transform", function(d,i) {
                    return "translate(" + String([ self.plot._x(self.x[i]), self.plot._y(self.y[i]) ]) + ")";
                });
            pt.exit().remove();
        }
    }, {
        defaults: {
            "stroke-width": "1px",
            "fill":         "black",
            "stroke":       "none",
            "opacity":      1.0,
            "d":            d3.svg.symbol().type("circle").size(16)()
        }
    });



    var e_grouped_points = e_xy.extend({
        constructor: function(x, y, keys, labels, point_groups) {
            e_xy.call(this, x, y);

            this.keys = keys;
            this.labels = labels;
            this.point_groups = point_groups;

            this.selection_delegate = null;
        },

        setSelectionDelegate: function(delegate) {
            if (this.selection_delegate) {
                this.selection_delegate.off(null, null, this);
            }
            this.selection_delegate = delegate;
            if (this.selection_delegate) {
                this.selection_delegate.on("selection-changed", _.bind(this.reflectSelection, this), this);
            }
        },

        reflectSelection: function(sel) {
            if (_.isArray(sel)) {
                sel = _.reduce(sel, function(a, b) { a[b] = true; return a; }, {});
            }

            this.g
                .selectAll("g.node")
                .classed("selected", function(d) { return sel[d]; });
        },

        pointClick: function(k) {
            this.selection_delegate && this.selection_delegate.click(k, {
                "shift": d3.event.shiftKey,
            });
        },

        brushStart: function(extent) {
            this.selection_delegate && this.selection_delegate.brushStart({
                "shift": d3.event.sourceEvent.shiftKey,
            });
        },

        brushUpdate: function(extent) {
            var self = this;
            var in_rect = [];
            var x, y, i;

            for (i = 0; i < this.keys.length; ++i) {
                x = this.plot._x(this.x[i]);
                y = this.plot._y(this.y[i]);
                if (extent[0][0] <= x && x <= extent[1][0] &&
                    extent[0][1] <= y && y <= extent[1][1]) {
                    in_rect.push(this.keys[i]);
                }
            }
            this.selection_delegate && this.selection_delegate.brushUpdate(in_rect);
        },

        brushEnd: function(extent) {
            this.selection_delegate && this.selection_delegate.brushEnd();
        },

        title: function(k, i) {
            return "ID=" + k + " (" + d3.format(".2f")(this.x[i]) + "," + d3.format(".2f")(this.y[i]) + ")";
        },

        label: function(k, i) {
            return this.labels[i];
        },

        attrs: function(k) {
            var self = this;

            var result = _.extend({}, e_grouped_points.defaults);

            if (this.point_groups) {
                this.point_groups.each(function(pg) {
                    if (pg.hasPoint(k)) {
                        _.extend(result, pg.get("style"));
                    }
                });
            }

            if (!result.fill)   result.fill = "none";
            if (!result.stroke) result.stroke = "none";

            return _.omit(result, ["_shape"]);
        },

        draw: function() {
            var self = this;

            var pt = this.g
                .selectAll(".node")
                .data(this.keys, function(d) { return d; })

            var n = pt.enter().append("g").classed("node", true);

            n.append( "path");
            n.append( "text").attr(e_grouped_points.default_label_style);
            n.append("title");

            pt.attr("transform", function(k, i) {
                return "translate(" + String([ self.plot._x(self.x[i]), self.plot._y(self.y[i]) ]) + ")";
            });

            pt.select( "path").each(function(k, i) { d3.select(this).attr(self.attrs(k, i)); })
            pt.select( "text").text(function(k, i) { return self.label(k, i); });
            pt.select("title").text(function(k, i) { return self.title(k, i); });

            pt.exit().remove();
        }
    }, {
        default_label_style: {
            "dy":          "3px",
            "x":           "6px",
            "y":           "0px",
            "style":       "font-family: helvetica; font-size: 8px; font-weight: 400",
            "pointer-events": "auto",
        },

        defaults: {
            "_shape":       "circle",
            "d":            d3.svg.symbol().type("circle")(),
            "fill":         "rgba(0,0,0,.65)",
            "stroke":       null,
            "stroke-width": "1px"
        }
    });



    var e_line = e_xy.extend({
        constructor: function(x, y, attr) {
            e_xy.call(this, x, y);

            this.attr = attr;
        },

        makeLine: function() {
            return d3.svg.line();
        },

        makePath: function() {
            var self = this;

            var path = this.makeLine()
                .x(function(d, i) { return self.plot._x(self.x[i]); })
                .y(function(d, i) { return self.plot._y(self.y[i]); })(
                    { length: Math.min(this.x.length, this.y.length) }
                );

            return path;
        },

        draw: function() {
            this.g.selectAll("path").remove();
            this.g
                .append("path")
                .attr(_.extend({}, e_line.defaults, this.attr))
                .attr("d", this.makePath());
        }
    }, {
        defaults: {
            "stroke-width": "1px",
            "fill":         "none",
            "stroke":       "black",
        }
    });



    var e_smoothline = e_line.extend({
        makeLine: function() {
            return d3.svg.line().interpolate("basis");
        }
    });



    var label_defaults = {
        "dy": "6px",
        "text-anchor": "middle",
        "style": "font-family: helvetica; font-size: 12px; font-weight: 600"
    };

    var title_defaults = {
        "dy": "7px",
        "text-anchor": "middle",
        "style": "font-family: helvetica; font-size: 14px; font-weight: 600"
    };

    var axis_defaults = {
        "fill":            "none",
        "stroke":          "#aaa",
        "opacity":         1.0,
        "shape-rendering": "crispEdges"
    }

    var tick_defaults = {
        "style": "font-family: helvetica; font-size: 11px; font-weight: 100"
    }

    var background_defaults = {
        "fill":            "white",
        "stroke":          "#aaa",
        "stroke-width":    "1",
        "shape-rendering": "crispEdges"
    };

    var defaults = {
        title: "Plot",
        title_attrs: title_defaults,
        title_offset: [ 0, -20 ],

        svgclass: "plot",

        padding: [ 30,20,60,60 ], // amount that the plot region is inset by. [ top, right, bottom, left ]

        inner: 10,                // amount that the plot background is expanded by.
        outer: 15,                // amount that the plot axes are moved by.

        width: 1000,              // initial svg width
        height: 1000,             // initial svg height
        background: true,         // whether to add a background
        background_attrs: background_defaults,

        axes: {
            x: {
                label: "X",
                visible: true, nice: true, log: false,
                lo: 0.0, hi: 1.0,
                offset: [   0, +36 ],
                odp: [ 0,0 ],
                axis_attrs: axis_defaults,
                label_attrs: label_defaults,
                tick_attrs: _.extend({}, tick_defaults, { "text-anchor": "middle" })
            },
            y: {
                label: "Y",
                visible: true, nice: true, log: false,
                lo: 0.0, hi: 1.0,
                offset: [ -38,   0 ],
                odp: [ 0,0 ],
                axis_attrs: axis_defaults,
                label_attrs: label_defaults,
                tick_attrs: _.extend({}, tick_defaults, { "text-anchor": "end" })
            },
        }
    };



    var plotbase = function() {
        var this_config = {};
        this.config = this_config;

        this.elems = [];

        utils.merge(this_config, defaults);
        _.each(arguments, function(config) {
            utils.merge(this_config, config);
        });

        this.initialize();
    };

    plotbase.prototype.initialize = function() {
        this.svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
        var svg = d3.select(this.svg);

        this.width  = this.config.width;
        this.height = this.config.height;

        d3.select(this.svg)
            .attr("width",             this.width)
            .attr("height",            this.height)
            .attr("version",           "1.1")
            .attr("baseProfile",       "full")
            .attr("xmlns",             "http://www.w3.org/2000/svg")
            .attr("xmlns:xmlns:xlink", "http://www.w3.org/1999/xlink")
            .classed("plot",           this.config.svgclass);

        svg
            .append("g")
            .classed("background", true);

        this.xScaleBrush = d3.scale.linear();
        this.yScaleBrush = d3.scale.linear();

        this.brush = d3.svg.brush()
            .x(this.xScaleBrush)
            .y(this.yScaleBrush)
            .on("brushstart", _.bind(this.brushStart,  this))
            .on("brush",      _.bind(this.brushUpdate, this))
            .on("brushend",   _.bind(this.brushEnd,    this));

        svg.append("g").classed("brush", true).call(this.brush);

        d3.select(this.svg).append("g").classed("axes", true);

        svg.select("g.axes").append("g").classed("axis-x", true);
        svg.select("g.axes").append("g").classed("axis-y", true);

        svg.select("g.axis-x").append("g").classed("axis-label", true);
        svg.select("g.axis-y").append("g").classed("axis-label", true);

        svg.append("g").classed("title", true);

        svg.append("g").classed("plotarea", true);

        this.xAxis = d3.svg.axis();
        this.yAxis = d3.svg.axis();

        this.update();
    };

    plotbase.prototype.update = function() {
        this.updateBackground();
        this.updateScales();
        this.updateAxes();
        this.updateAxisLabels();
        this.updateTitle();
        this.updatePlotArea();
    };

    plotbase.prototype.brushStart = function() {
        var self = this;
        var e = d3.event.target.extent();
        d3.select(this.svg)
            .select("g.plotarea")
            .selectAll("g.elem").each(function(d, i) {
                d.brushStart(e);
            });
    };

    plotbase.prototype.brushUpdate = function() {
        var self = this;
        var e = d3.event.target.extent();
        d3.select(this.svg)
            .select("g.plotarea")
            .selectAll("g.elem").each(function(d, i) {
                d.brushUpdate(e);
            });
    };

    plotbase.prototype.brushEnd = function() {
        var self = this;
        var e = d3.event.target.extent();
        d3.select(this.svg)
            .select("g.plotarea")
            .selectAll("g.elem").each(function(d, i) {
                d.brushEnd(e);
            });
    };

    plotbase.prototype.updateBackground = function() {
        var svg = d3.select(this.svg);

        var rect = {
            w: this.width  - this.config.padding[1] - this.config.padding[3] + this.config.inner * 2,
            h: this.height - this.config.padding[0] - this.config.padding[2] + this.config.inner * 2,
            x: this.config.padding[3] - this.config.inner,
            y: this.config.padding[0] - this.config.inner
        }

        this.xScaleBrush.domain([ rect.x, rect.x + rect.w ]).range([ rect.x, rect.x + rect.w ]);
        this.yScaleBrush.domain([ rect.y + rect.h, rect.y ]).range([ rect.y + rect.h, rect.y ]);

        this.brush
            .x(this.xScaleBrush)
            .y(this.yScaleBrush)

        svg.select("g.brush").call(this.brush);

        var bkg = svg
            .select("g.background")
            .selectAll("rect")
            .data(this.config.background ? [rect] : [])

        bkg.enter().append("rect")

        bkg .attr(this.config.background_attrs)
            .attr("x",               function(d) { return d.x })
            .attr("y",               function(d) { return d.y })
            .attr("width",           function(d) { return d.w })
            .attr("height",          function(d) { return d.h });

        bkg.exit().remove();
    };

    plotbase.prototype.makeScale = function(cfg, range) {
        var scale = cfg.log ? d3.scale.log() : d3.scale.linear();
        scale.domain([ cfg.lo, cfg.hi ]);
        var D = range[0] < range[1] ? +1 : -1;
        scale.range([
            range[0] + D*cfg.odp[0],
            range[1] - D*cfg.odp[0]
        ]);
        if (cfg.nice) scale.nice();
        return scale;
    };

    plotbase.prototype.updateScales = function() {
        this.xScale = this.makeScale(
            this.config.axes.x,
            [ this.config.padding[3], this.width - this.config.padding[1] ]
        );

        this.yScale = this.makeScale(
            this.config.axes.y,
            [ this.height - this.config.padding[2], this.config.padding[0] ]
        );
    };

    plotbase.prototype.updateAxes = function() {
        this.xAxis
            .tickValues(null)
            .scale(this.xScale)
            .orient("bottom")
            .tickFormat(this.xScale.tickFormat(5))
            .ticks(5);

        this.yAxis
            .tickValues(null)
            .scale(this.yScale)
            .orient("left")
            .tickFormat(this.xScale.tickFormat(5))
            .ticks(5);

        var svg = d3.select(this.svg);

        if (this.config.axes.x.visible) {
            svg.select("g.axis-x")
                .attr("transform", "translate(0," + (this.height - this.config.padding[2] + this.config.outer) + ")")
                .call(this.xAxis);
        }

        if (this.config.axes.y.visible) {
            svg.select("g.axis-y")
                .attr("transform", "translate(" + (this.config.padding[3] - this.config.outer) + ",0)")
                .call(this.yAxis);
        }

        svg .selectAll(".axis-x path, .axis-y line").attr(this.config.axes.x.axis_attrs);
        svg .selectAll(".axis-x .tick text").attr(this.config.axes.x.tick_attrs);

        svg .selectAll(".axis-y path, .axis-y line").attr(this.config.axes.y.axis_attrs);
        svg .selectAll(".axis-y .tick text").attr(this.config.axes.y.tick_attrs);
    };

    plotbase.prototype.updateAxisLabels = function() {
        var svg = d3.select(this.svg);
        var pos, lab;


        pos = [
            (this.xScale.range()[0] + this.xScale.range()[1])/2.0 + this.config.axes.x.offset[0],
            this.config.axes.x.offset[1]
        ];

        lab = svg.select("g.axis-x g.axis-label");

        lab.attr("transform", "translate(" + String(pos) + ")")

        lab = lab.selectAll("text").data(this.config.axes.x.label ? [this.config.axes.x.label] : [])
        lab.enter().append("text").attr(this.config.axes.x.label_attrs);
        lab.text(function (d) { return d; });
        lab.exit().remove();


        pos = [
            this.config.axes.y.offset[0],
            (this.yScale.range()[0] + this.yScale.range()[1])/2.0 + this.config.axes.y.offset[1],
        ];

        lab = svg.select("g.axis-y g.axis-label");

        lab.attr("transform", "translate(" + String(pos) + ") rotate(-90)")

        lab = lab.selectAll("text").data(this.config.axes.y.label ? [this.config.axes.y.label] : [])
        lab.enter().append("text").attr(this.config.axes.y.label_attrs);
        lab.text(function (d) { return d; });
        lab.exit().remove();
    };

    plotbase.prototype.updateTitle = function() {
        var svg = d3.select(this.svg);
        var pos, lab;

        pos = [
            (this.xScale.range()[0] + this.xScale.range()[1])/2.0 + this.config.title_offset[0],
            this.yScale.range()[1] + this.config.title_offset[1]
        ];

        lab = svg.select("g.title");

        lab.attr("transform", "translate(" + String(pos) + ")")

        lab = lab.selectAll("text").data(this.config.title ? [this.config.title] : [])
        lab.enter().append("text").attr(this.config.title_attrs);
        lab.text(function (d) { return d; });
        lab.exit().remove();
    };

    plotbase.prototype.addElem = function(elem) {
        this.elems.push(elem);
    };

    plotbase.prototype.removeElem = function(elem_id) {
        this.elems = _.reject(this.elems, function(elem) { return elem.id == elem_id; });
    };

    plotbase.prototype.fitElems = function() {
        if (!this.elems.length) return;

        var e = this.elems[0].extent();
        for (var i = 1; i < this.elems.length; ++i) {
            var e2 = this.elems[i].extent();
            e.x = [ Math.min(e.x[0], e2.x[0]), Math.max(e.x[1], e2.x[1]) ];
            e.y = [ Math.min(e.y[0], e2.y[0]), Math.max(e.y[1], e2.y[1]) ];
        }

        this.config.axes.x.lo = e.x[0];
        this.config.axes.x.hi = e.x[1];
        this.config.axes.y.lo = e.y[0];
        this.config.axes.y.hi = e.y[1];
    };

    plotbase.prototype.updatePlotArea = function() {
        var self = this;
        var plot = d3.select(this.svg).select("g.plotarea")
        var elems = plot.selectAll("g.elem").data(this.elems, function(d) { return d.id; });

        elems.enter().append("g").classed("elem", true).each(function(d) { d.create(self, this); });
        elems.each(function(d) { d.draw(); });
        elems.exit().each(function(d) { d.destroy(); }).remove();
    };

    plotbase.prototype.resize = function(width, height) {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            d3.select(this.svg)
                .attr("width", width)
                .attr("height", height);

            this.update();
        }
    };

    plotbase.prototype._transform = function(v, scale, o) {
        var d = scale.domain();
        var r = scale.range();
        var D = r[0] < r[1] ? +1 : -1;

        if (d[0] > v) return r[0] - D*o[0];
        if (d[1] < v) return r[1] + D*o[1];

        return scale(v);
    };

    plotbase.prototype._x = function(x) {
        return this._transform(x, this.xScale, this.config.axes.x.odp);
    };

    plotbase.prototype._y = function(y) {
        return this._transform(y, this.yScale, this.config.axes.y.odp);
    };

    plotbase.prototype.transform = function(d) {
        return { x: this._x(d.x), y: this._y(d.y) };
    };

    plotbase.extend = Backbone.Model.extend;

    return {
        selection:        selection,
        e_base:           e_base,
        e_xy:             e_xy,
        e_points:         e_points,
        e_grouped_points: e_grouped_points,
        e_line:           e_line,
        e_smoothline:     e_smoothline,
        plotbase:         plotbase
    };
});
