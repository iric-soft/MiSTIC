(function() {
    scatterplot = function(options, xdata, ydata) {
        this.options = {
            padding: [ 20,20,60,60 ], // amount that the plot region is inset by. [ top, right, bottom, left ]
            inner: 10,   // amount that the plot background is expanded by.
            outer: 15,   // amount that the plot axes are moved by.
            xlab_offset: 36,
            ylab_offset: -38,
            width: 1000,
            height: 1000,
            axis_labels: false,
            background: true,
            axes: false,
            pt_size: 4,
            makeGridLine:false,
            gridValue: 10,
            minimal : true,
            clearBrush: false,

        };

        if (options !== undefined) {
            _.extend(this.options, options);
        }

        this.svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');

        this.width = this.options.width;
        this.height = this.options.height;

        d3.select(this.svg)
            .attr("width", this.width)
            .attr("height", this.height)
            .attr('version', '1.1')
            .attr('baseProfile', 'full')
            .attr('xmlns', 'http://www.w3.org/2000/svg')
            .classed('scatterplot', true);

        this.setXData(xdata, false);
        this.setYData(ydata, false);

        this.xScale = undefined;
        this.yScale = undefined;

        this.xAxis = undefined;
        this.yAxis = undefined;

        this.current_selection = [];

        this.draw();
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
        if (redraw !== false) this.draw();
    };

    scatterplot.prototype.setYData = function(ydata, redraw) {
        if (ydata !== undefined) {
            this.y_id = ydata.gene;
            this.ylab = ydata.symbol;
            this.ydata = this.datadict(ydata.data);
        } else {
            this.ydata = undefined;
        }
        if (redraw !== false) this.draw();
    };

    scatterplot.prototype.notifySelectionChange = function(quiet) {
        var selection = this.getSelection();
        if (!_.isEqual(this.current_selection, selection)) {
            this.current_selection = selection;
            if (!quiet) $(this.svg).trigger('updateselection', [this.current_selection]);
        }
    };

    scatterplot.prototype.highlightCircle = function(d, i) {
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

    scatterplot.prototype.getSelection = function() {
        var circles = d3
            .select(this.svg)
            .selectAll("g.node.selected");
        var selected = _.map(circles.data(), function(c) { return c.k; });
        return selected;
    };

    scatterplot.prototype.brushstart = function() {
    };

    scatterplot.prototype.brushed = function() {
        var self = this;
        var e = d3.event.target.extent();
        var circles  = d3
            .select(this.svg)
            .selectAll("g.node")
            .filter(function(d) {
                var t = self.transform(d);
                return e[0][0] <= t.x && t.x <= e[1][0] && e[0][1] <= t.y && t.y <= e[1][1]
            });
        var selected = _.map(circles.data(), function(c) {return c.k;});
        this.setSelection(selected);
    };

    scatterplot.prototype.brushend = function() {
    };

    scatterplot.prototype._transform = function(v, scale) {
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
        xrg = stats.range(_.values(this.xdata));
        yrg = stats.range(_.values(this.ydata));

        this.xAxis = d3.svg
            .axis()
            .scale(this.xScale)
            .orient("bottom")
            .tickValues([xrg[0]+0.001, xmean, xrg[1]])
            .tickFormat(d3.format(",.1f"));

        this.yAxis = d3.svg
            .axis()
            .scale(this.yScale)
            .orient("left")
            .tickValues([yrg[0]+0.01, ymean, yrg[1]])
            .tickFormat(d3.format(",.1f"));
    };

    scatterplot.prototype.makeFullAxes = function() {
        this.xAxis = d3.svg.axis()
            .scale(this.xScale)
            .orient("bottom")
            .tickFormat(this.xScale.tickFormat(5, d3.format(".2f")))
            .ticks(5);


        this.yAxis = d3.svg.axis()
            .scale(this.yScale)
            .orient("left")
            .tickFormat(this.xScale.tickFormat(5, d3.format(".2f")))
            .ticks(5);
    };

    scatterplot.prototype.updateAxes = function() {
        if (this.options.minimal) {
            this.makeMinimalAxes();
        } else {
            this.makeFullAxes();
        }

        var svg = d3.select(this.svg);

        if (this.xAxis !== null) {
            svg.select('g.axis-x')
                .transition()
                .call(this.xAxis);
        }

        if (this.yAxis !== null) {
            svg.select('g.axis-y')
                .transition()
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

    scatterplot.prototype.updatePoints = function(xy) {
        var self = this;

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

        g.append('circle')
            .on('click', _.bind(this.highlightCircle, this));
        g.append("text")
            .attr('style', 'font-size:'+ font_size+"px;")
            .classed('circlelabel invisible', true);
        g.append('title');

        var transition = this.nodes.transition();

        transition
            .attr("transform", function(d) {
                var t = self.transform(d);
                return "translate(" + [t.x, t.y] + ")";
            });

        transition
          .select('circle')
            .attr('r',  this.options.pt_size)
            .attr('opacity', 0.65);

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
            var x = this.xdata[k];
            var y = this.ydata[k];
            xy.push({ k:k, x:x, y:y });
        }

        return xy;
    };

    scatterplot.prototype.update = function() {
        var xy = this.getXYData();
        this.updatePoints(xy);
        this.updateAxes();
    };

    scatterplot.prototype.draw = function() {
        var self = this;

        if (this.xdata === undefined || this.ydata === undefined) {
            return;
        }

        var svg = d3.select(this.svg)

        svg.selectAll('*').remove();

        var keys = _.intersection(_.keys(this.xdata), _.keys(this.ydata));

        var v1_log = [];
        var v2_log = [];
        var v1 = [];
        var v2 = [];
        var v1_anscombe = [];
        var v2_anscombe = [];

        var xy = [];

        var lg = true;

        for (var i in keys) {
            var k = keys[i];
            var x = this.xdata[k];
            var y = this.ydata[k];
            if  (x < 0.0 ||  y < 0.0) {
                lg = false;
                xy.push({x:x,y:y,k:k});
            } else {
                xy.push({ x: x < 0.0105 ? 0.01 : x, y: y < 0.0105 ? 0.01 : y , k: k});
            }

            v1.push(x);
            v2.push(y);
            v1_log.push(Math.log(x + 1/1024));
            v2_log.push(Math.log(y + 1/1024));
        }

        var rr = Math.max(
            stats.range(v1)[1]-stats.range(v1)[0],
            stats.range(v2)[1]-stats.range(v2)[0]);
        if (rr<1) {
            lg = false;
        }

        var r = stats.pearson(v1, v2);
        var r_log = stats.pearson(v1_log, v2_log);

        var width = this.width - this.options.padding[1] - this.options.padding[3] + this.options.inner * 2;
        var height = this.height - this.options.padding[0] - this.options.padding[2] + this.options.inner * 2;

        var dmx = d3.extent(xy, function(d) { return d.x; });
        var dmy = d3.extent(xy, function(d) { return d.y; });

        if (lg) {
            this.xScale = d3.scale.log();
            this.yScale = d3.scale.log();
        } else {
            this.xScale = d3.scale.linear();
            this.yScale = d3.scale.linear();
            //if (rr<1) {
            //  dmx = [0,1];
            //  dmy = [0,1];
            //}
        }

        this.xScale.domain(dmx)
            .range([ this.options.padding[3], this.width - this.options.padding[1] ])
            .nice();

        this.yScale.domain(dmy)
            .range([ this.height - this.options.padding[2], this.options.padding[0] ])
            .nice();

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

        if (this.options.axes) this.makeAxes();

        this.updatePoints(xy);
    };
})();
