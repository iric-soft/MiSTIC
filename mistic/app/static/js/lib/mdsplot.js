(function() {
    var defaults = {
        padding: [ 80, 80, 80, 80 ],
        outside_domain_pad: [10, 10],
        inner: 10,
        outer: 15,
        separation: 10,
        width: 1000,
        height: 1000,
        axes: true,
        pt_size: 4,
        xlab_offset: -50,
        ylab_offset: 40,
        xform: '',

        base_attrs: {
            _shape:  'circle',
            d:       d3.svg.symbol().type("circle")(),
            fill:    "rgba(0,0,0,.65)",
            stroke:  null,
        },
    };

    mdsplot = function(options) {
//         console.log("in init mds graph")

// init graph
        this.options = {};
        _.extend(this.options, defaults);

        if (options !== undefined) {
            _.extend(this.options, options);
        }
        this.options.base_attrs = _.clone(this.options.base_attrs);


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

        this.xlab = 'Dimension 1';
        this.ylab = 'Dimension 2';

        this.point_groups = null;
        this.current_selection = [];

// init data
        this.data = []; // sample and gene selected

        this.xdata = []; // mds data on x axis
        this.ydata = []; // mds data on y axis
    };

    mdsplot.prototype.resize = function(width, height) {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            d3.select(this.svg)
                .attr("width", width)
                .attr("height", height);
            this.reloadSelection();

        }
    };

    mdsplot.prototype.removeData = function(matcher) {
//         console.log("remove data")
        this.data = _.reject(this.data, matcher);
        this.xdata = [];
        this.ydata = [];
        this.draw();
    };

    mdsplot.prototype.reset = function () {
//         console.log("reset data")
        this.point_groups = null;
        this.data = [];
        this.current_selection = [];
        this.xdata = [];
        this.ydata = [];
        this.xform='';
    };

    mdsplot.prototype.datadict = function(vdata, ids) {
//         console.log("in datadict")

        var vals = {};
        for (var i=0; i<vdata.length; i++) {
            vals[ids[i]] = vdata[i];
        }
        return vals;
    };

    mdsplot.prototype.update = function() {
//         console.log("in update")
        var xy = this.getXYData();
        this.updatePoints(xy);
    };


    mdsplot.prototype.setXData = function(xdata, id_samples, redraw) {
        if (xdata !== undefined) {
            this.xdata = this.datadict(xdata, id_samples);
        } else {
            this.xdata = undefined;
        }
        if (redraw !== false) {
            this.update();
        }
    };

    mdsplot.prototype.setYData = function(ydata, id_samples, redraw) {
        if (ydata !== undefined) {
            this.ydata = this.datadict(ydata, id_samples);
        } else {
            this.ydata = undefined;
        }
        if (redraw !== false) {
            this.update();
        }
    };

    mdsplot.prototype.setXYmds = function(xdata, ydata, id_samples) {
        this.setXData(xdata, id_samples, false);
        this.setYData(ydata, id_samples, false);
    };

    mdsplot.prototype.pointIDs = function() {
//         console.log("in point ID")

        var ids = {};
        for (var i in this.data) {
            var d = this.data[i].data;
            for (var j in d) {
                ids[d[j].sample] = true;
            }
        }

        return _.keys(ids);
    };

    mdsplot.prototype.getGenes = function() {
        var genes = [];
        for (var i in this.data) {
            genes.push(this.data[i].gene);
        }
        return genes;
    };

    mdsplot.prototype.showLabels = function() {
       var pt_size = this.options.pt_size;
       var font_size = pt_size + 8;

       l = d3.selectAll('.circlelabel')[0].length;

       if ( l == 0) {
          d3.selectAll('.node')
                .append("text")
                .text(function(d) { return _.isUndefined(d) ? '' : d.k; })
                .attr('style', 'font-size:'+ font_size+"px;")
                .classed('circlelabel' , true);
       }
    };

    mdsplot.prototype.setBaseAttrs = function(cls) {
        this.options.base_attrs = {};
        _.extend(this.options.base_attrs, cls);

        this.updatePoints();
    };

    mdsplot.prototype.updateData = function(data) {
//         console.log("in updateData")

        var idxs = [];
        for (idx = 0; idx < this.data.length; ++idx) {
            if (data.gene == this.data[idx].gene) idxs.push(idx);
        }

        for (j=0; j< idxs.length; j++){
            var idx = idxs[j];
            if (idx == this.data.length) {
                return;
            }

            this.data[idx] = data;
            var i;
        }

    };

    mdsplot.prototype.getXYData = function() {
//         console.log("in getXYData")
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


// ##########################################################################################################################
// ##########################################################################################################################
// function : on selection
// ##########################################################################################################################
// ##########################################################################################################################


    mdsplot.prototype.getSelection = function() {
        var nodes = d3
            .select(this.svg)
            .selectAll("g.node.selected");
        var selected = _.map(nodes.data(), function(d) { return d.k; });
        return selected;
    };

//     mdsplot.prototype.getSelection = function() {
//         return this.current_selection;
//     };

    mdsplot.prototype.setSelection = function(selection, quiet) {
        if (!_.isEqual(this.current_selection, selection)) {
            this.current_selection = selection;
            if (!quiet) $(this.svg).trigger('updateselection', [selection]);
        }
    };

    mdsplot.prototype.notifySelectionChange = function(quiet) {
        var selection = this.getSelection();

        if (!_.isEqual(this.current_selection, selection)) {
            this.current_selection = selection;
            if (!quiet) $(this.svg).trigger('updateselection', [this.current_selection]);
        }

    };

    mdsplot.prototype.reloadSelection = function(){
        var my_selection = this.current_selection;
        this.current_selection = [];
        this.draw();
        this.setSelection(my_selection, true);
    };

// ##########################################################################################################################
// ##########################################################################################################################
// function : brush
// ##########################################################################################################################
// ##########################################################################################################################

    mdsplot.prototype.clearBrush = function() {
        this.brush.clear();
        d3.select(this.svg).select('.brush').select('text').remove();
        d3.select(this.svg).select('g.brush').call(this.brush);
    };

    mdsplot.prototype.brushstart = function() {
        var b = d3.select(this.svg).select('.brush').select('text').remove();
        $(this.svg).trigger('brushstart', [this]);
        var b = d3.select(this.svg).select('.brush');
        b.append('text');

    };

    mdsplot.prototype.brushed = function() {
        var self = this;
        var e = d3.event.target.extent();
        var circles  = d3
            .select(this.svg)
            .selectAll("g.node");
        var ntotal  = circles[0].length;
        circles = circles.filter(function(d) {
                var t = self.transformScale(d);
                return e[0][0] <= t.x && t.x <= e[1][0] && e[0][1] <= t.y && t.y <= e[1][1];
            });
        var selected = _.map(circles.data(), function(d) { return d.k; });
        this.setSelection(selected);
        nselected = selected.length;

        var p = nselected/ntotal*100;
        var r = d3.select(this.svg).select('rect.extent');
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

    mdsplot.prototype.brushend = function() {
        $(this.svg).trigger('brushstart', [this]);
    };


// ##########################################################################################################################
// ##########################################################################################################################
// function : point group
// ##########################################################################################################################
// ##########################################################################################################################

    mdsplot.prototype.legendSymbol = function(node, pg) {
        var attrs = {};

        _.extend(attrs, this.options.base_attrs);
        _.extend(attrs, pg.get('style'));
        if (attrs.fill === null) attrs.fill = 'none';
        if (attrs.fill === undefined) attrs.fill = '#aaa';

        var g = node
            .append('g')
            .classed('node', true);

        g.append('path')
            .each(function(d, i) {
                for (var i in attrs) {
                    d3.select(this).attr(i, attrs[i]);
                }
            });
    };


    // Info : add style of point groups in the graph (ie: color of each group)
    // comment :
    //  - i is not use
    mdsplot.prototype.pointAttrs = function(d, i) {
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

    // Info : reset add new point group to the graph
    // comment :
    mdsplot.prototype.setPointGroups = function(pgs) {
        if (this.point_groups !== null) {
            this.point_groups.off(null, null, this);
        }
        this.point_groups = pgs;
        if (this.point_groups !== null) {
            //bind updatePoints() to the pg (call this function when an action is done)
            this.point_groups.on('change:point_ids change:style add remove reset sort', function() { this.updatePoints(); }, this);
        }

        this.updatePoints();
    };



// ##########################################################################################################################
// ##########################################################################################################################
// function : display all the graphe
// ##########################################################################################################################
// ##########################################################################################################################


    mdsplot.prototype.clearLabels = function() {
       d3.selectAll('.circlelabel').remove();
    };

    mdsplot.prototype.toggleSelected = function(d, i) {
        var current_selection = this.nodes[0][i];
        d3.select(current_selection).classed('selected', !d3.select(current_selection).classed('selected'));
        this.notifySelectionChange();
    };

    mdsplot.prototype.setSelection = function(selection, quiet) {
        d3.select(this.svg)
            .selectAll('g.node')
            .classed('selected', function(d) { return _.contains(selection, d.k); });
        this.notifySelectionChange(quiet);
    };

    mdsplot.prototype._transformScale = function(v, scale) {
        var d = scale.domain();
        var r = scale.range();
        var o0 = this.options.outside_domain_pad[0] - this.options.pt_size;
        var o1 = this.options.outside_domain_pad[1] - this.options.pt_size;
        if (d[0] > v) return r[0] + o0 * (r[0]<r[1] ? -1 : +1);
        if (d[1] < v) return r[1] + o1 * (r[0]<r[1] ? -1 : +1);
        return scale(v);
    };

    mdsplot.prototype.transformScale = function(d) {
        return {
            x: this._transformScale(d.x, this.xScale),
            y: this._transformScale(d.y, this.yScale)
        };
    };

    mdsplot.prototype.makeAxes = function() {
        var self = this;
        var xScale = this.xScale;
        var yScale = this.yScale;

        var axes = d3.select(this.svg).select('g.axes');

        var xAxis = d3.svg.axis();
        var yAxis = d3.svg.axis();

        xAxis
            .scale(xScale)
            .orient('bottom');

        yAxis
            .scale(yScale)
            .orient('left');

        axes.append('g')
            .attr('class', 'axis axis-x')
            .attr('transform', 'translate(0,' + (this.height - this.options.padding[2] + this.options.outer) + ')')
            .call(xAxis);

        axes.append('g')
            .attr('class', 'axis axis-y')
            .attr('transform', 'translate(' + (this.options.padding[3] - this.options.outer) + ',0)')
            .call(yAxis);

        axes.selectAll('.axis path, .axis line')
            .attr('fill', 'none')
            .attr('stroke', 'black')
            .attr('shape-rendering', 'crispEdges');

        axes.selectAll('.axis text')
            .attr('style', 'font-family: helvetica; font-size: 11px; font-weight: 100');

        axes.select('g.axis-x')
            .append('g')
            .attr('class', 'axis-label-x')
            .attr('transform', 'translate(' + String((this.xScale.range()[0] + this.xScale.range()[1])/2.0) + ',' + String(this.options.ylab_offset) + ')')
            .append('text')
            .attr('x', 0.0)
            .attr('y', 0.0)
            .attr('dy', '6px')
            .attr('text-anchor', 'middle')
            .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 600')
            .text(this.xlab);

        axes.select('g.axis-y')
            .append('g')
            .attr('class', 'axis-label-y')
            .attr('transform', 'translate(' + String(this.options.xlab_offset) + ',' + String((this.yScale.range()[0] + this.yScale.range()[1])/2.0) + ') rotate(-90 0 0)')
            .append('text')
            .attr('x', 0.0)
            .attr('y', 0.0)
            .attr('dy', '6px')
            .attr('text-anchor', 'middle')
            .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 600')
            .text(this.ylab);
    };

    mdsplot.prototype.updatePoints = function(xy) {

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
                var t = self.transformScale(d);
                return "translate(" + [t.x, t.y] + ")";
            });

        g.append('path')
            .on('click', _.bind(this.toggleSelected, this));

        g.append('title');

        var transition = this.nodes.transition();

        transition
            .duration(500)
            .ease("linear")
            .attr("transform", function(d) {
                var t = self.transformScale(d);
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

    };

    mdsplot.prototype.draw = function() {
//         console.log("draw");

// reset svg
        var svg = d3.select(this.svg);
        svg.selectAll('*').remove();

// Check data
        if (this.data === undefined) {
            return;
        }
        if (this.xdata === undefined || this.ydata === undefined) {
            return;
        }

        if (this.data.length == 0) return;
        if (this.xdata.length == 0 || this.ydata.length == 0) return;

        xy = this.getXYData();


// init the scale
        var xScale, yScale;

        this.xScale = xScale = d3.scale
            .linear()
//doesn't work             .domain([d3.min(this.xdata) - deltaX/10,d3.max(this.xdata) + deltaX/10])
            .domain(d3.extent(xy, function(d) { return d.x; }))
            .range([this.options.padding[3], this.width - this.options.padding[1] ]);

        this.yScale = yScale = d3.scale
            .linear()
//doesn't work             .domain([d3.min(this.ydata) - deltaY/10,d3.max(this.ydata) + deltaY/10])
            .domain(d3.extent(xy, function(d) { return d.y; }))
            .range([this.height - this.options.padding[2], this.options.padding[0] ]);


        svg .append('rect')
            .attr('width', this.width - this.options.padding[1] - this.options.padding[3] + this.options.inner * 2)
            .attr('height', this.height - this.options.padding[0] - this.options.padding[2] + this.options.inner * 2)
            .attr('x', this.options.padding[3] - this.options.inner)
            .attr('y', this.options.padding[0] - this.options.inner)
            .attr('fill', 'white')
            .attr('stroke', 'rgba(0,0,0,.2)')
            .attr('stroke-width', '1')
            .attr('shape-rendering', 'crispEdges');

        svg.append('g').attr('class', 'axes');
        this.makeAxes();


// init brush


        // background rectangle
        var bkgx = this.options.padding[3] - this.options.inner;
        var bkgy = this.options.padding[0] - this.options.inner;

        var width = this.width - this.options.padding[1] - this.options.padding[3] + this.options.inner * 2;
        var height = this.height - this.options.padding[0] - this.options.padding[2] + this.options.inner * 2;

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

        this.updatePoints();

    };




    mdsplot.prototype.loader = function (config) {
//         console.log("draw");

// reset svg
        var svg = d3.select(this.svg);
        svg.selectAll('*').remove();
        var width = this.width / 8;
        var height = this.height / 8;

        var radius = Math.min(width, height) / 2;
        var tau = 2 * Math.PI;

        var arc = d3.svg.arc()
                .innerRadius(radius*0.5)
                .outerRadius(radius*0.9)
                .startAngle(0);

        var svg = d3.select(this.svg).append("svg")
            .attr("id", "loader")
            .attr("width", width)
            .attr("height", height)
          .append("g")
            .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

        var background = svg.append("path")
                .datum({endAngle: 0.33*tau})
                .style("fill", "#4D4D4D")
                .attr("d", arc)
                .call(spin, 1200);

        function spin(selection, duration) {
            selection.transition()
                .ease("linear")
                .duration(duration)
                .attrTween("transform", function() {
                    return d3.interpolateString("rotate(0)", "rotate(360)");
                });

            setTimeout(function() { spin(selection, duration); }, duration);
        }

        function transitionFunction(path) {
            path.transition()
                .duration(7500)
                .attrTween("stroke-dasharray", tweenDash)
                .each("end", function() { d3.select(this).call(transition); });
        }
    };






    mdsplot.prototype.updateXform = function(xform) {
        this.xform=xform;
    };








    mdsplot.prototype.addData = function(data) {
//         console.log("in addData")
        this.data.push(data);
        this.draw();
//         this.reloadSelection();
    };


})();


