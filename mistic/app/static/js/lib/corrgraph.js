(function() {
    corrgraph = function(data, elem) {
        this.options = {
            padding: [ 80, 80, 80, 80 ],
            inner: 10,
            outer: 15,
            xlab_offset: -50,
            ylab_offset: 40,
        };

        this.elem = $(elem);

        this.genes = undefined;

        this.setData(data);

        this.xlab = 'Gene index';
        this.ylab = 'Correlation';
    };

    corrgraph.prototype.resize = function() {
        setTimeout(_.bind(this._resize, this), 0);
    };

    corrgraph.prototype._resize = function() {
        var svg = d3.select(this.elem[0]).select('svg');
        if (svg.empty()) return;

        var width = this.elem.width();
        var height = this.elem.height();

        var curr_width = svg.attr('width');
        var curr_height = svg.attr('height');

        if (curr_width != width || curr_height != height) {
            this.draw();
        }
    };

    corrgraph.prototype.markGenes = function(genes) {
        this.genes = genes
        this.updateGeneTicks();
    };

    corrgraph.prototype.setData = function(data) {
        this.data = data;
        this.data.sort(function(a,b) { return b.corr - a.corr; });
        for (var i = 0; i < this.data.length; ++i) {
            this.data[i].idx = i;
        }

        _.each(this.data,              function(d) { d.labelled = false; });
        _.each(_.first(this.data, 20), function(d) { d.labelled = true; });
        // _.each(_.first(_.last(this.data, 9490), 80), function(d) { d.labelled = true; });
        _.each( _.last(this.data, 20), function(d) { d.labelled = true; });
    }

    corrgraph.prototype.AUC = function() {
        if (this.genes === undefined) return undefined;
        
        var n1 = 0;
        var n2 = 0;
        var R1 = 0;
        var R2 = 0;
        var idx = 1;
        for (var i in this.data) {
            if (_.include(this.genes, this.data[i].gene)) {
                R1 += idx;
                n1 += 1;
            } else {
                R2 += idx;
                n2 += 1;
            }
            ++idx;
        }

        var U1 = R1 - n1 * (n1 + 1) / 2;
        var U2 = R2 - n2 * (n2 + 1) / 2;
        console.log('U-test:', U1, U2, U1+U2, n1*n2);

        var z = (U1 - (n1*n2) / 2) / Math.sqrt(n1*n2*(n1+n2+1) / 12);
        return { U: U1, z: z, p: stats.z_low(z) };
    };

    corrgraph.prototype.labelMaker = function() {
        var self = this;
        var xScale = this.xScale;
        var yScale = this.yScale;

        var TOP = 100;
        var BTM = d3.select(this.elem[0]).select('svg').attr('height') - 100;

        var SEP = { x: 10, y: 24 }; // interbox separation
        var LAB = { x: 60, y: 12 }; // size of one label

        var MAX_DIST = 300; // max horizontal distance from point to box
        var MIN_DIST = 100;  // min horizontal distance from point to box

        var boxes = [
            {
                x1: -LAB.x - SEP.x, y1: TOP,
                x2: -SEP.x,         y2: BTM,
                a: +1
            }
        ];

        var between = function(a, b) {
            return b[0] <= a && a <= b[1];
        };

        var overlaps = function(r1, r2) {
            return !(r2[1] <= r1[0] || r1[1] <= r2[0]);
        };

        var clamp = function(x, lo, hi) {
            if (x <= lo) return lo;
            if (x >= hi) return hi;
            return x;
        };

        var y_exclusion = function(lo, hi) {
            var lo_i = clamp(Math.floor(xScale.invert(lo)), 0, self.data.length - 1);
            var hi_i = clamp(Math.ceil(xScale.invert(hi)),  0, self.data.length - 1);

            var y_lo = yScale(self.data[lo_i].corr);
            var y_hi = yScale(self.data[hi_i].corr);

            return [
                Math.max(TOP, Math.min(y_lo, y_hi) - 5 - LAB.y),
                Math.min(BTM, Math.max(y_lo, y_hi) + 5)
            ];
        };

        var can_add_to_box = function(d, box) {
            var x = xScale(d.idx);
            var y_ex = y_exclusion(box.x1, box.x2);
            var label_y = [ box.y2, box.y2 + LAB.y ];

            console.log('       x:', x);
            console.log('    y_ex:', JSON.stringify(y_ex));
            console.log(' label_y:', JSON.stringify(label_y));
            console.log('  cond 1:', label_y[0] < TOP);
            console.log('  cond 2:', label_y[1] >= BTM);
            console.log('  cond 3:', overlaps(label_y, y_ex));
            console.log('  cond 4:', (x > box.x2 && (box.a == +1 || !between(x - box.x2, [ MIN_DIST, MAX_DIST ]))));
            console.log('  cond 5:', (x < box.x1 && (box.a == -1 || !between(box.x1 - x, [ MIN_DIST, MAX_DIST ]))));
            console.log('        :', x < box.x1, box.a == -1, box.x1-x, [MIN_DIST, MAX_DIST], !between(box.x1 - x, [ MIN_DIST, MAX_DIST ]));

            if (label_y[0] < TOP || 
                label_y[1] >= BTM ||
                overlaps(label_y, y_ex) ||
                (x > box.x2 && (box.a == +1 || !between(x - box.x2, [ MIN_DIST, MAX_DIST ]))) ||
                (x < box.x1 && (box.a == -1 || !between(box.x1 - x, [ MIN_DIST, MAX_DIST ])))) {

                console.log(JSON.stringify(d), 'can\'t fit into box:', JSON.stringify(box));

                return false;
            }
            return true;
        }

        var allocate_to_box = function(d) {
            var x = xScale(d.idx);

            var box = curr = boxes[boxes.length-1];

            if (!can_add_to_box(d, box)) {
                var fitted = false;

                console.log('* try continuation');
                // try directly under current box.
                box = {
                    x1: curr.x1, y1: curr.y2 + SEP.y,
                    x2: curr.x2, y2: curr.y2 + SEP.y,
                    a: curr.x2 < x ? -1 : +1
                };

                fitted = can_add_to_box(d, box);

                if (!fitted) {
                    console.log('* try under graph');
                    // try below data points.
                    var y_ex = y_exclusion(box.x1, box.x2);
                    if (curr.y2 < y_ex[1]) {
                        box.y1 = box.y2 = y_ex[1];
                        fitted = can_add_to_box(d, box);
                    }
                }

                if (!fitted) {
                    console.log('* try new adjacent column');
                    console.log('curr =', JSON.stringify(curr));
                    // try a new column immediately to the the right of the current column.
                    console.log(typeof curr.x2, typeof SEP.x, curr.x2, SEP.x);
                    box = {
                        x1: curr.x2 + SEP.x,
                        y1: TOP,
                        x2: curr.x2 + SEP.x + LAB.x,
                        y2: TOP,
                        a:  curr.x2 + SEP.x < x ? -1 : +1
                    };
                    console.log('testing', JSON.stringify(box));
                    fitted = can_add_to_box(d, box);
                }

                if (!fitted) {
                    // consider a new column to the left as far away as possible.
                    console.log('* try new left column');
                    box.x1 = x - MAX_DIST + 10 - LAB.x;
                    box.x2 = x - MAX_DIST + 10;
                    box.a = -1;
                    if (box.x1 > curr.x2 + SEP.x) {
                        fitted = can_add_to_box(d, box);
                    }
                }

                if (!fitted) {
                    // consider a new column to the right as close as possible.
                    console.log('* try new right column');
                    box.x1 = x + MIN_DIST + 10;
                    box.x2 = x + MIN_DIST + 10 + LAB.x;
                    box.a = +1;
                    if (box.x1 > curr.x2 + SEP.x) {
                        fitted = can_add_to_box(d, box);
                    }
                }

                if (!fitted) {
                    console.log('* everything failed');
                }

                boxes.push(box);
            }

            var r = { 
                a: box.a,
                x: box.a == +1 ? box.x1 : box.x2,
                y: box.y2
            };

            box.y2 += LAB.y;

            return r;
        };

        return function(d) {
            if (!d.labelled) return null;

            var l = allocate_to_box(d);

            l.id = d.gene;
            l.hl = d.in_gene_set;
            l.t = d.symbol === '' ? d.gene : d.symbol;

            var tangent;

            var lo = Math.max(0, d.idx - 10);
            var hi = Math.min(self.data.length-1, d.idx + 10);

            tangent = Math.atan2(
                yScale(self.data[hi].corr - self.data[lo].corr) - yScale(0),
                xScale(hi - lo) - xScale(0));

            var x1 = xScale(d.idx);
            var y1 = yScale(d.corr);
            var x2 = l.x;
            var y2 = l.y + 5.5;

            var dx1 = Math.cos(tangent - Math.PI / 2.0);
            var dy1 = Math.sin(tangent - Math.PI / 2.0);

            if ((x2-x1)*dx1 + (y2-y1)*dy1 < 0.0) { dx1 = -dx1; dy1 = -dy1; }

            var dx2 = -l.a;
            var dy2 = 0;

            x1 += 4 * dx1; y1 += 4 * dy1;
            x2 += 4 * dx2; y2 += 4 * dy2;

            var x1c = x1 + 50 * dx1;
            var y1c = y1 + 50 * dy1;
            var x2c = x2 + 100 * dx2;
            var y2c = y2 + 100 * dy2;
            
            l.p = 'M ' + x1 + ' ' + y1 + ' C ' + x1c + ' ' + y1c + ' ' + x2c + ' ' + y2c + ' ' + x2 + ' ' + y2

            return l;
        };
    };

    corrgraph.prototype.updateLabels = function() {
        var subset = _.filter(this.data, function(d) { return d.labelled === true; });

        subset = _.map(subset, this.labelMaker())

        var label_g = d3.select(this.elem[0]).selectAll('g.labels');

        var current_box = null;

        var labels = label_g
            .selectAll('.label')
            .data(subset, function(d) { return d.id; });

        labels
            .attr('x', function(d, i) { return d.x; })
            .attr('y', function(d, i) { return d.y; });

        labels
          .enter()
            .append('text')
            .attr('class', 'label')
            .attr('style', 'font-family: helvetica; font-size: 11px; font-weight: 100')
            .attr('x', function(d, i) { return d.x; })
            .attr('y', function(d, i) { return d.y; })
            .attr('dx', '2px')
            .attr('dy', '11px')
            .attr('text-anchor', function(d, i) { return [ 'end', 'middle', 'start' ][d.a+1]; })
            .attr('fill', function (d) { return d.hl ? 'blue' : 'black'; })
            .text(function (d) { return d.t; });

        labels
          .exit()
            .remove();

        var lines = label_g
            .selectAll('.label-path')
            .data(subset, function(d) { return d.gene; });

        lines
            .attr('d', function(d, i) { return d.p; })

        lines
          .enter()
            .append('path')
            .attr('class', 'label-path')
            .attr('fill', 'none')
            .attr('stroke', '#123')
            .attr('opacity', .5)
            .attr('stroke-width', '0.5')
            .attr('d', function(d, i) { return d.p; })

        lines
          .exit()
            .remove();
    };

    corrgraph.prototype.updateGeneTicks = function() {
        var ticks = d3.select(this.elem[0]).selectAll('g.gene-ticks');
        var xScale = this.xScale;
        var yScale = this.yScale;
        var subset = [];

        if (this.genes !== undefined) {
            var gene_hash = {};
            _.each(
                this.genes,
                function(d) {
                    gene_hash[d] = true;
                });

            subset = _.filter(
                this.data,
                function(d) {
                    return d.in_gene_set = (gene_hash[d.gene] === true);
                });
        }

        var geneticks = ticks
            .selectAll('line')
            .data(subset, function(d) { return d.gene; });

        geneticks
          .enter()
            .append('line')
            .attr('stroke', '#00f')
            .attr('stroke-width', '0.5')
            .attr('x1', function(d) { return xScale(d.idx); })
            .attr('y1', function(d) { return yScale(0.0) - 4; })
            .attr('x2', function(d) { return xScale(d.idx); })
            .attr('y2', function(d) { return yScale(0.0) + 4; });

        geneticks
          .exit()
            .remove();
    };

    corrgraph.prototype.makeAxes = function() {
        var self = this;
        var xScale = this.xScale;
        var yScale = this.yScale;

        var axes = d3.select(this.elem[0]).select('g.axes');

        var xAxis = d3.svg.axis();
        var yAxis = d3.svg.axis();

        var ticks = d3.range(0, this.data.length - 1, 1000);
        if (ticks[ticks.length-1] != this.data.length - 1) {
            ticks.push(this.data.length - 1);
        }

        xAxis
	    .scale(xScale)
	    .orient('bottom')
            .tickValues(ticks);

	yAxis
	    .scale(yScale)
	    .orient('left')
            .tickValues([ -1.0, -0.95, -0.9, -0.8, -0.7, -0.6, -0.5, -0.25, 0.0, 0.25, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0 ])
            .tickFormat(d3.format('.2f'))
            .tickSize(6);

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

        axes.append('g').attr('class', 'grid-lines').attr('opacity', .5);

        axes.select('g.grid-lines')
            .append('g').attr('class', 'grid-lines-y')
            .selectAll('line')
            .data(yAxis.tickValues())
            .enter()
            .append('line')
            .attr('stroke', '#aaa')
            .attr('stroke-width', '0.5')
            .attr('x1', xScale(0))
            .attr('y1', function (y) { return yScale(y); })
            .attr('x2', xScale(this.data.length-1))
            .attr('y2', function (y) { return yScale(y); });

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

    corrgraph.prototype.draw = function() {
        if (this.data === undefined) {
            return;
        }

        this.width = this.elem.width();
        this.height = this.elem.height();

        if (this.height == 0) return;

        console.log('draw');

        this.elem.empty();

        var svg = d3.select(this.elem[0])
            .append('svg')
            .attr('width', this.width)
            .attr('height', this.height)
            .attr('version', '1.1')
            .attr('xmlns', 'http://www.w3.org/2000/svg');

        var xScale, yScale;

        this.xScale = xScale = d3.scale
            .linear()
	    .domain([0, this.data.length - 1])
	    .range([this.options.padding[3], this.width - this.options.padding[1] ]);

	this.yScale = yScale = d3.scale
            .linear()
	    .domain([ -1.0, +1.0 ])
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

	svg.append('g').attr('class', 'gene-ticks')
        svg.append('g').attr('class', 'labels')
        svg.append('g').attr('class', 'axes')

        this.makeAxes();
        this.updateGeneTicks();
        this.updateLabels();

        var data = svg
            .append('g')
	    .attr('class', 'data')
            .selectAll('circle')
            .data(this.data, function(d) { return d.gene; })

        data
          .enter()
            .append('circle')
            .attr('fill', '#050')
            .attr('cx', function(d) { return xScale(d.idx); })
            .attr('cy', function(d) { return yScale(d.corr); })
            .attr('r',  2);
    };
})();
