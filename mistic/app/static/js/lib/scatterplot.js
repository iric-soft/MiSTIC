(function() {
    var defaults = {
        padding: [ 20,20,60,60 ], // amount that the plot region is inset by. [ top, right, bottom, left ]
        inner: 10,   // amount that the plot background is expanded by.
        outer: 15,   // amount that the plot axes are moved by.
        outside_domain_pad: [10, 10],
        xlab_offset: 36,
        ylab_offset: -38,
        width: 1000,
        height: 1000,
        axis_labels: false,
        background: true,
        axes: false,
        pt_size: 4,
        makeGridLine: false,
        gridValue: 10,
        minimal: true,

        base_attrs: {
            _shape:  'circle',
            d:       d3.svg.symbol().type("circle")(),
            fill:    "rgba(0,0,0,.65)",
            stroke:  null,
        },
    };

    scatterplot = function(options, xdata, ydata) {
        this.options = {}

        _.extend(this.options, defaults);

        if (options !== undefined) {
            _.extend(this.options, options);
        }

        this.options.base_attrs = _.clone(this.options.base_attrs)

        this.svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');

        this.width = this.options.width;
        this.height = this.options.height;

        d3.select(this.svg)
            .attr("width", this.width)
            .attr("height", this.height)
            .attr('version', '1.1')
            .attr('baseProfile', 'full')
            .attr("xmlns", "http://www.w3.org/2000/svg")
            .attr("xmlns:xmlns:xlink", "http://www.w3.org/1999/xlink")
            .classed('scatterplot', true);

        this.xScale = undefined;
        this.yScale = undefined;

        this.xAxis = undefined;
        this.yAxis = undefined;

        this.current_selection = [];

        this.point_groups = null;

        this.setXData(xdata, false);
        this.setYData(ydata, false);
    };

    scatterplot.prototype.setBaseAttrs = function(cls) {
        this.options.base_attrs = {};
        _.extend(this.options.base_attrs, cls);

        this.updatePoints();
    };

    scatterplot.prototype.setPointGroups = function(pgs) {
        if (this.point_groups !== null) {
            this.point_groups.off(null, null, this);
        }
        this.point_groups = pgs;
        if (this.point_groups !== null) {
            this.point_groups.on('change:point_ids change:style add remove reset sort', function() { this.updatePoints(); }, this);
        }

        this.updatePoints();
    };

    scatterplot.prototype.resize = function(width, height) {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            d3.select(this.svg)
                .attr("width", width)
                .attr("height", height);

            this.draw();
        }
    };

    scatterplot.prototype.datadict = function(data) {
        var vals = {};
        for (var i in data) {
            var pt = data[i];
            vals[pt.sample] = pt.expr;
        }
        return vals;
    };

    scatterplot.prototype.setLog = function(l) {
        this.options.lg=l;
    };

    scatterplot.prototype.setXData = function(xdata, redraw) {
        if (xdata !== undefined) {
            this.x_id = xdata.gene;
            this.xlab = xdata.symbol;
            this.xdata = this.datadict(xdata.data);
        } else {
            this.xdata = undefined;
        }
        if (redraw !== false) {
            this.update();
        }
    };

    scatterplot.prototype.setYData = function(ydata, redraw) {
        if (ydata !== undefined) {
            this.y_id = ydata.gene;
            this.ylab = ydata.symbol;
            this.ydata = this.datadict(ydata.data);
        } else {
            this.ydata = undefined;
        }
        if (redraw !== false) {
            this.update();
        }
    };

    scatterplot.prototype.pointIDs = function() {
        return _.intersection(_.keys(this.xdata), _.keys(this.ydata));
    };

    scatterplot.prototype.notifySelectionChange = function(quiet) {
        var selection = this.getSelection();
        
        if (!_.isEqual(this.current_selection, selection)) {
            this.current_selection = selection;
            if (!quiet) $(this.svg).trigger('updateselection', [this.current_selection]);
        }
     
    };

    scatterplot.prototype.toggleSelected = function(d, i) {
        var current_selection = this.nodes[0][i];
        d3.select(current_selection).classed('selected', !d3.select(current_selection).classed('selected'));
        this.notifySelectionChange();
    };

    scatterplot.prototype.setSelection = function(selection, quiet) {
        d3.select(this.svg)
            .selectAll('g.node')
            .classed('selected', function(d) { return _.contains(selection, d.k); });
        this.notifySelectionChange(quiet);
    };

    scatterplot.prototype.clearBrush = function() {
        this.brush.clear();
        d3.select(this.svg).select('.brush').select('text').remove();
        d3.select(this.svg).select('g.brush').call(this.brush);
    };

    scatterplot.prototype.getSelection = function() {
        var nodes = d3
            .select(this.svg)
            .selectAll("g.node.selected");
        var selected = _.map(nodes.data(), function(d) { return d.k; });
        return selected;
    };

    scatterplot.prototype.brushstart = function() {
        var b = d3.select(this.svg).select('.brush').select('text').remove();
        $(this.svg).trigger('brushstart', [this]);
        var b = d3.select(this.svg).select('.brush');
        b.append('text');
        
    };

    scatterplot.prototype.brushed = function() {
        var self = this;
        var e = d3.event.target.extent();
        var circles  = d3
            .select(this.svg)
            .selectAll("g.node");
        var ntotal  = circles[0].length;
        circles = circles.filter(function(d) {
                var t = self.transform(d);
                return e[0][0] <= t.x && t.x <= e[1][0] && e[0][1] <= t.y && t.y <= e[1][1]
            });
        var selected = _.map(circles.data(), function(d) { return d.k; });
        this.setSelection(selected);
        nselected = selected.length;
        
        var p = nselected/ntotal*100;
        var r = d3.select(this.svg).select('rect.extent')
        var b = d3.select(this.svg).select('.brush').select('text');
        if (nselected > 0) {
          
            b.attr('x', r.attr('x'))
             .attr('y', r.attr('y'))
             .attr('text-anchor', 'right')
             .attr('fill','grey')
             .attr('style', 'font-family: helvetica; font-size: 11px;')
             .text(p.toFixed(2)+'%');
       }
    };

    scatterplot.prototype.brushend = function() {
        $(this.svg).trigger('brushstart', [this]);
    };

    scatterplot.prototype._transform = function(v, scale) {
        var d = scale.domain();
        var r = scale.range();
        var o0 = this.options.outside_domain_pad[0] - this.options.pt_size;
        var o1 = this.options.outside_domain_pad[1] - this.options.pt_size;
        if (d[0] > v) return r[0] + o0 * (r[0]<r[1] ? -1 : +1);
        if (d[1] < v) return r[1] + o1 * (r[0]<r[1] ? -1 : +1);
        return scale(v);
    };

    scatterplot.prototype.transform = function(d) {
        return {
            x: this._transform(d.x, this.xScale),
            y: this._transform(d.y, this.yScale)
        };
    };

    scatterplot.prototype.makeMinimalAxes = function() {
        xmean = stats.average(_.values(this.xdata));
        ymean = stats.average(_.values(this.ydata));

        var dx = this.xScale.domain();
        var dy = this.yScale.domain();

        var dmx = d3.extent(_.values(this.xdata), function(d) { return (d < dx[0] || d > dx[1]) ? null : d; });
        var dmy = d3.extent(_.values(this.ydata), function(d) { return (d < dy[0] || d > dy[1]) ? null : d; });

        var fmt = function(x) { return d3.format(",.2g")(x).replace(/([.][0-9]*[1-9])0*$/, '$1'); }

        if (this.xAxis !== null) {
            this.xAxis
                .scale(this.xScale)
                .orient("bottom")
                .tickValues([dmx[0], xmean, dmx[1]])
                .tickFormat(fmt);
        }

        if (this.yAxis !== null) {
            this.yAxis
                .scale(this.yScale)
                .orient("left")
                .tickValues([dmy[0], ymean, dmy[1]])
                .tickFormat(fmt);
        }
    };

    scatterplot.prototype.makeFullAxes = function() {
      
        if (this.xAxis !== null && !(_.isUndefined(this.xAxis))) {
            this.xAxis
                .tickValues(null)
                .scale(this.xScale)
                .orient("bottom")
                .tickFormat(this.xScale.tickFormat(5))
                .ticks(5);
        }

        if (this.yAxis !== null && !(_.isUndefined(this.yAxis))) {
            this.yAxis
                .tickValues(null)
                .scale(this.yScale)
                .orient("left")
                .tickFormat(this.xScale.tickFormat(5))
                .ticks(5);
        }
    };

    scatterplot.prototype.updateAxes = function() {
        if (this.options.minimal) {
            this.makeMinimalAxes();
        } else {
            this.makeFullAxes();
        }

        var svg = d3.select(this.svg);

        if (this.xAxis !== null && !(_.isUndefined(this.xAxis))) {
            svg.select('g.axis-x')
                //.transition()
                .call(this.xAxis);
        }

        if (this.yAxis !== null && !(_.isUndefined(this.yAxis))) {
            svg.select('g.axis-y')
                //.transition()
                .call(this.yAxis);
        }

        svg .selectAll('.axis path, .axis line')
            .attr('fill', 'none')
            .attr('stroke', '#aaa')
            .attr('opacity', 1.0)
            .attr('shape-rendering', 'crispEdges');

        svg .selectAll('.axis text')
            .attr('style', 'font-family: helvetica; font-size: 11px; font-weight: 100');
    };

    scatterplot.prototype.makeAxes = function() {
        var self = this;

        this.xAxis = d3.svg.axis()
        this.yAxis = d3.svg.axis()

        var svg = d3.select(this.svg);

        svg .append("g")
            .attr("class", "axis axis-x")
            .attr("transform", "translate(0," + (this.height - this.options.padding[2] + this.options.outer) + ")")

        svg .append("g")
            .attr("class", "axis axis-y")
            .attr("transform", "translate(" + (this.options.padding[3] - this.options.outer) + ",0)")

        this.updateAxes();

        if (this.options.makeGridLine) {
            svg.selectAll('.axis-x line')
                .filter(function(d, i) { return d <= self.options.gridValue })
                .attr('y1',-(this.height -this.options.padding[2] + this.options.outer)-this.yScale(d3.min([this.yScale.domain()[1],this.options.gridValue])));

            svg.selectAll('.axis-y line')
                .filter(function(d, i) { return d <= self.options.gridValue })
                .attr('x2', this.xScale(this.xScale.domain()[1])-(this.options.padding[3] - this.options.outer));
        }

        if (this.options.axis_labels) {
            svg .select('g.axis-x')
                .append('g')
                .attr('class', 'axis-label-x')
                .attr('transform', 'translate(' + String((this.xScale.range()[0] + this.xScale.range()[1])/2.0) + ',' + String(this.options.xlab_offset) + ')')
                .append('text')
                .attr('x', 0.0)
                .attr('y', 0.0)
                .attr('dy', '6px')
                .attr('text-anchor', 'middle')
                .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 600')
                .text(this.xlab);

            svg .select('g.axis-y')
                .append('g')
                .attr('class', 'axis-label-y')
                .attr('transform', 'translate(' + String(this.options.ylab_offset) + ',' + String((this.yScale.range()[0] + this.yScale.range()[1])/2.0) + ') rotate(-90 0 0)')
                .append('text')
                .attr('x', 0.0)
                .attr('y', 0.0)
                .attr('dy', '6px')
                .attr('text-anchor', 'middle')
                .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 600')
                .text(this.ylab);
        }
    };

    scatterplot.prototype.pointAttrs = function(d, i) {
        var self = this;
        var result = {};

        _.extend(result, this.options.base_attrs);
        if (this.point_groups !== null) {
            this.point_groups.each(function(pg) {
                if (pg.hasPoint(d.k)) {
                    _.extend(result, pg.get('style'));
                }
            });
        }
        _.extend(result, d.attrs);
        if (!result.fill) result.fill = 'none';
        return result;
    };

    scatterplot.prototype.updateScales = function(xy) {
        if (xy === undefined) xy = this.getXYData();

        var dmx, dmy;

        if (this.options.x_log) {
            dmx = d3.extent(xy, function(d) { return d.x == 0.0 ? null : d.x; });
            this.xScale = d3.scale.log();
        } else {
            dmx = d3.extent(xy, function(d) { return d.x; });
            this.xScale = d3.scale.linear();
        }

        this.xScale.domain(dmx)
            .range([ this.options.padding[3] + this.options.outside_domain_pad[0],
                     this.width - this.options.padding[1] - this.options.outside_domain_pad[1] ])
            .nice();

        if (this.options.y_log) {
            dmy = d3.extent(xy, function(d) { return d.y == 0.0 ? null : d.y; });
            this.yScale = d3.scale.log();
        } else {
            dmy = d3.extent(xy, function(d) { return d.y; });
            this.yScale = d3.scale.linear();
        }

        this.yScale.domain(dmy)
            .range([ this.height - this.options.padding[2] - this.options.outside_domain_pad[1],
                     this.options.padding[0] + this.options.outside_domain_pad[0] ])
            .nice();
    };


    scatterplot.prototype.updatePoints = function(xy) {
        
        var self = this;
        if (xy === undefined) xy = this.getXYData();

        var pt_size = this.options.pt_size;
        var font_size = pt_size + 8;

        this.nodes =
          d3.select(this.svg)
            .select('.nodes')
            .selectAll('.node')
            .data(xy, function (d) { return d.k; });

        var g = this.nodes
          .enter()
            .append('g')
            .classed('node', true)
            .attr("transform", function(d) {
                var t = self.transform(d);
                return "translate(" + [t.x, t.y] + ")";
            });

        g.append('path')
            .on('click', _.bind(this.toggleSelected, this));

        g.append("text")
            .attr('style', 'font-size:'+ font_size+"px;")
            .classed('circlelabel invisible', true);
        g.append('title');

        var transition = this.nodes.transition();

        transition
            .duration(500)
            .ease("linear")
            .attr("transform", function(d) {
                var t = self.transform(d);
                return "translate(" + [t.x, t.y] + ")";
            });

        transition
          .select('path')
            .each(function(d, i) {
                var a = self.pointAttrs(d, i);
                // this can be done better in d3 v3
                for (var i in a) {
                    d3.select(this).attr(i, a[i]);
                }
            });

        transition
          .select('text')
            .attr('x', pt_size + 2)
            .attr('y', pt_size)
            .text(function(d) {return d.k;} );

        transition
          .select('title')
            .text(function(d) {
                return 'ID=' + d.k + ' (' + d.x.toFixed(2) + ', ' + d.y.toFixed(2) + ')';
            });

        this.nodes
          .exit()
            .transition()
            .remove();
            
       
    }

    scatterplot.prototype.getXYData = function() {
        var keys = _.intersection(_.keys(this.xdata), _.keys(this.ydata));

        var xy = [];

        for (var i in keys) {
            var k = keys[i];
            xy.push({
                k:   k,
                x:   this.xdata[k],
                y:   this.ydata[k] 
            });
        }

        return xy;
    };

    scatterplot.prototype.setScaleType = function(x_log, y_log) {
        this.options.x_log = x_log;
        this.options.y_log = y_log;
    };

    scatterplot.prototype.update = function() {
        var xy = this.getXYData();
        this.updateScales(xy);
        this.updatePoints(xy);
        this.updateAxes();
    };

    scatterplot.prototype.draw = function() {
        var self = this;

        if (this.xdata === undefined || this.ydata === undefined) {
            return;
        }

        var svg = d3.select(this.svg)

        // clear the current plot
        svg.selectAll('*').remove();

        var width = this.width - this.options.padding[1] - this.options.padding[3] + this.options.inner * 2;
        var height = this.height - this.options.padding[0] - this.options.padding[2] + this.options.inner * 2;

        // background rectangle
        var bkgx = this.options.padding[3] - this.options.inner;
        var bkgy = this.options.padding[0] - this.options.inner;

        var color = 'transparent';
        if (this.options.background) {
            color = 'white';
        }

        svg .append('rect')
            .classed('background', true)
            .attr('width', width)
            .attr('height',height)
            .attr('x', bkgx)
            .attr('y', bkgy)
            .attr('fill', color)
            .attr('stroke', 'rgba(0,0,0,.2)')
            .attr('stroke-width', '1')
            .attr('shape-rendering', 'crispEdges');

        // selection brush
        this.xScaleBrush = d3.scale.linear().domain([ bkgx, bkgx+width ]).range([ bkgx, bkgx+width ]);
        this.yScaleBrush = d3.scale.linear().domain([ bkgy+height, bkgy ]).range([ bkgy+height, bkgy ]);

        this.brush = d3.svg.brush()
            .x(this.xScaleBrush)
            .y(this.yScaleBrush)
            .on("brushstart", _.bind(this.brushstart, this))
            .on("brush",      _.bind(this.brushed,    this))
            .on("brushend",   _.bind(this.brushend,   this));

        svg.append("g")
            .classed("brush", true)
            .call(this.brush);

        // draw points
        svg.append('g')
            .classed('nodes', true);

        // collect data
        var xy = this.getXYData();
        this.updateScales(xy);

        if (this.options.axes) this.makeAxes();

        this.updatePoints(xy);
    };
})();
