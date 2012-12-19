(function() {
    var GRID_DIV = 16;
    var distance = function(a, b) {
        var t;
        x = Math.abs(a.x - b.x);
        y = Math.abs(a.y - b.y);
        t = Math.min(x,y);
        x = Math.max(x,y);
        y = t;
        return x * Math.sqrt(1+(y/x)*(y/x));
    };

    mstplot = function(options) {
        this.options = {
            width:           1000,
            height:          750,
            scale:           740,
            dx:              130,
            dy:              5,
            padding:         10,
            ramp:            YlGnBl,
            node_r:         undefined, // node radius.
            node_w:         undefined, // node stroke-width.
            edge_w:         undefined, // edge stroke-width.
        };

        if (options !== undefined) {
            _.extend(this.options, options);
        }

        this.selected_ids = {};

        this.svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
 
        this.width = this.options.width;
        this.height = this.options.height;

        this.S = 1.0;
        this.T = [ 0.0, 0.0 ];

        d3.select(this.svg)
            .attr("width", this.width)
            .attr("height", this.height)
            .attr('version', '1.1')
            .attr("pointer-events", "all")
            .attr('xmlns', 'http://www.w3.org/2000/svg');

        this.zoom_g = d3.select(this.svg)
            .append('g')
            .call(d3.behavior
                  .zoom()
                  .scaleExtent([1, 100])
                  .on("zoom", _.bind(this.zoom, this)));

        this.body = this.zoom_g
            .append('g');

        this.labels = d3.select(this.svg)
            .append('g')
            .attr('class', 'labels')
            .attr('style', 'font-family: helvetica; font-size: 10px; font-weight: 100')
            .attr('dy', 5)
            .attr('fill', '#fff')
            .attr("pointer-events", "none");
    };

    _.extend(mstplot, Backbone.Events);

    mstplot.prototype.weightColour = function(w) {
        return this.options.ramp(1-w);
    };

    mstplot.prototype.screenToView = function(x, y) {
        return {
            x: (x - this.T[0]) / this.S,
            y: (y - this.T[1]) / this.S
        };
    }

    mstplot.prototype.viewToScreen = function(x, y) {
        return {
            x: (x * this.S) + this.T[0],
            y: (y * this.S) + this.T[1]
        };
    }

    mstplot.prototype.screenToPlot = function(x, y) {
        return {
            x: (((x - this.T[0]) / this.S) - this.options.dx) / this.options.scale,
            y: (((y - this.T[1]) / this.S) - this.options.dy) / this.options.scale
        };
    }

    mstplot.prototype.plotToScreen = function(x, y) {
        return {
            x: (((x - this.T[0]) / this.S) - this.options.dx) / this.options.scale,
            y: (((y - this.T[1]) / this.S) - this.options.dy) / this.options.scale
        };
    }

    mstplot.prototype.visibleLabels = function(translate, scale) {
        var xlo = Math.floor((((-100 - translate[0]) / scale) - this.options.dx) / this.options.scale * GRID_DIV);
        var ylo = Math.floor((((-100 - translate[1]) / scale) - this.options.dy) / this.options.scale * GRID_DIV);
        var xhi = Math.ceil( (((1100 - translate[0]) / scale) - this.options.dx) / this.options.scale * GRID_DIV);
        var yhi = Math.ceil( (((1100 - translate[1]) / scale) - this.options.dy) / this.options.scale * GRID_DIV);

        xlo = Math.max(0, Math.min(xlo, GRID_DIV));
        ylo = Math.max(0, Math.min(ylo, GRID_DIV));
        xhi = Math.max(0, Math.min(xhi, GRID_DIV));
        yhi = Math.max(0, Math.min(yhi, GRID_DIV));


        var result = [];

        for (var x = xlo; x < xhi; ++x) {
            for (var y = ylo; y < yhi; ++y) {
                result.push.apply(result ,this.grid[y][x]);
            }
        }

        return result;
    };

    mstplot.prototype.labelText = function(id) {
        var gene_info = this.info[id];
        if (gene_info === undefined) return id;
        if (gene_info.hasOwnProperty('sym') && gene_info.sym !== null) {
            return gene_info.sym;
        }
        return id;
    };

    mstplot.prototype.zoom = function() {
        var self = this;

        var S = d3.event.scale
        var T = d3.event.translate

        if (T[0] > 0) T[0] = 0;
        if (T[1] > 0) T[1] = 0;

        if (T[0] + S * this.width < this.width) T[0] = this.width - (S * this.width);
        if (T[1] + S * this.height < this.height) T[1] = this.height - (S * this.height);

        this.S = S
        this.T = [ T[0], T[1] ];

        this.body
            .attr("transform",
                  "translate(" + T + ")" + " scale(" + S + ")");

        this.updateLabels();
    };
    
    mstplot.prototype.updateLabels = function() {
        var self = this;
        var labels = [];

        var selected = _.keys(this.selected_ids);
        for (var i = 0; i < selected.length; ++i) {
            if (this.nodes_by_id.hasOwnProperty(selected[i])) {
                labels.push(this.nodes_by_id[selected[i]]);
            }
        }

        if (this.options.node_r * this.S >= 10) {
            var visible = this.visibleLabels(this.T, this.S);
            for (var i = 0; i < visible.length; ++i) {
                if (!this.selected_ids.hasOwnProperty(visible[i].id)) {
                    labels.push(visible[i]);
                }
            }
        }

        var l = this.labels.selectAll('g').data(labels, function(d) { return d.idx; });

        var g = l
          .enter()
            .append('g');

        g.append('circle')
            .attr('cx', 0)
            .attr('cy', 0)
            .attr('r', 4)
            .attr('stroke', '#eee')
            .attr('stroke-width', 2)
            .attr('fill',   '#000');
        g.append('rect')
            .attr('height', 15)
            .attr('x', 6).attr('y', -7.5)
            .attr('fill', '#0074cc')
            .attr('stroke', '#000');
        g.append('text')
            .attr('x', 10)
            .attr('y', 3.5)
            .text(function(d) { return self.labelText(d.id); });

        g.each(function(d) {
            var w = d3.select(this).select('text')[0][0].getBBox().width + 8;
            d3.select(this).select('rect').attr('width', w);
        });

        l
          .exit()
            .remove();

        l
            .attr('transform', function(d) {
                var pos = self.viewToScreen(d.x, d.y);
                return 'translate(' + String(pos.x) + ',' + String(pos.y) + ')';
            });
    };

    mstplot.prototype.setData = function(nodes, edges, info, pos) {
        var self = this;

        this.info = info;

        this.nodes = [];
        this.nodes_by_id = {};

        for (var i = 0; i < nodes.length; ++i) {
            var n = {
                id: nodes[i],
                x: pos[i][0],
                y: pos[i][1],
                idx: i
            };
            this.nodes.push(n);
            this.nodes_by_id[n.id] = n;
        }

        var x_range = d3.extent(this.nodes, function(d) { return d.x; });
        var y_range = d3.extent(this.nodes, function(d) { return d.y; });

        var scale = Math.max(x_range[1] - x_range[0], y_range[1] - y_range[0]);

        var centre = {
            x: (x_range[1] + x_range[0]) / 2.0,
            y: (y_range[1] + y_range[0]) / 2.0
        };

        for (var i = 0; i < this.nodes.length; ++i) {
            this.nodes[i]._x = Math.max(0.0, Math.min(1.0, (this.nodes[i].x - centre.x) / scale + 0.5));
            this.nodes[i]._y = Math.max(0.0, Math.min(1.0, (this.nodes[i].y - centre.y) / scale + 0.5));
            this.nodes[i].x = this.nodes[i]._x * this.options.scale + this.options.dx;
            this.nodes[i].y = this.nodes[i]._y * this.options.scale + this.options.dy;
        }

        this.grid = [];

        for (var y = 0; y < GRID_DIV; ++y) {
            this.grid.push([]);
            for (var x = 0; x < GRID_DIV; ++x) {
                this.grid[y].push([]);
            }
        }

        for (var i = 0; i < this.nodes.length; ++i) {
            var gx = Math.min(GRID_DIV-1, Math.floor(this.nodes[i]._x * GRID_DIV));
            var gy = Math.min(GRID_DIV-1, Math.floor(this.nodes[i]._y * GRID_DIV));
            this.grid[gy][gx].push(this.nodes[i]);
        }

        this.edges = [];

        for (var i = 0; i < edges.length; ++i) {
            var src = edges[i][0][0];
            var tgt = edges[i][0][1];
            if (src >= this.nodes.length || tgt >= this.nodes.length) continue;
            var e = { src: src, tgt: tgt, w: edges[i][1] };
            this.edges.push(e);
        }

        // edges drawn from highest weight to lowest.
        this.edges.sort(function(a,b) { return b.w - a.w; });

        var avg_len = 0.0;

        for (var i = 0; i < this.edges.length; ++i) {
            avg_len += distance(this.nodes[e.src], this.nodes[e.tgt]);
        }

        avg_len /= this.edges.length;

        this.avg_edge_len = avg_len;

        if (this.options.edge_w == undefined) {
            this.options.edge_w = this.avg_edge_len / 10.0;
        }

        if (this.options.node_r == undefined) {
            this.options.node_r = this.avg_edge_len / 4.0;
        }

        if (this.options.node_w == undefined) {
            this.options.node_w = this.avg_edge_len / 40.0;
        }
    };

    mstplot.prototype.click = function(node) {
        this.trigger('click:cluster', _.keys(node.getContent()));
    };

    mstplot.prototype.draw = function() {
        var self = this;

        this.body
            .append('rect')
            .attr('width', this.width)
            .attr('height', this.height)
            .attr('x', 0.0)
            .attr('y', 0.0)
            .attr('fill', 'white')
            .attr('stroke', 'rgba(0,0,0,.2)')
            .attr('stroke-width', '1')
            .attr('shape-rendering', 'crispEdges');

        var mst = this.body
            .append('g')
            .attr('class', 'mst');

        mst .selectAll('line.edge')
            .data(this.edges)
          .enter()
            .append('line')
            .attr('class', 'edge')
            .attr('x1', function(d) { return self.nodes[d.src].x; })
            .attr('y1', function(d) { return self.nodes[d.src].y; })
            .attr('x2', function(d) { return self.nodes[d.tgt].x; })
            .attr('y2', function(d) { return self.nodes[d.tgt].y; })
            .attr('stroke', function(d) { return self.weightColour(d.w); })
            .attr('stroke-width', this.options.edge_w)
            .attr('fill',   'none');

        mst .selectAll('circle.node')
            .data(this.nodes, function(d) { return d.idx; })
          .enter()
            .append('circle')
            .attr('class', 'node')
            .attr('cx', function(d) { return d.x; })
            .attr('cy', function(d) { return d.y; })
            .attr('r', this.options.node_r)
            .attr('stroke', '#eee')
            .attr('stroke-width', this.options.node_w)
            .attr('fill',   '#081D58');
    };
})();
