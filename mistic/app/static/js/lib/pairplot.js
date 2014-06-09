(function() {
    var defaults = {
        padding: [ 20,20,20,20 ], // amount that the plot region is inset by. [ top, right, bottom, left ]
        separation: 10,
        width: 1000,
        height: 1000,
        axes: true,
        minimalAxes: false,
        x_log: false,
        y_log: false,
        xform: '', 

        base_attrs: {
            _shape:  'circle',
            d:       d3.svg.symbol().type("circle")(),
            fill:    "rgba(0,0,0,.65)",
            stroke:  null,
        },
    };

    pairplot = function(xdata, ydata, elem, options) {
        this.options = {};

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
            .classed('pairplot', true);

        this.point_groups = null;

        this.data = [];
        this.current_selection = [];
        this.subgraphs = [];
        this.plot_matrix = [];
    };

    pairplot.prototype.setMinimalAxes = function(b) {
      this.options.minimalAxes = b;
      _.each(this.subgraphs, function (s) { s.options.minimal = b; s.updateAxes(); });
    };

    pairplot.prototype.resize = function(width, height) {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            d3.select(this.svg)
                .attr("width", width)
                .attr("height", height);
            this.reloadSelection();
            
        }
    };

    pairplot.prototype.removeData = function(matcher) {
        this.data = _.reject(this.data, matcher);
        this.draw();
    };
    pairplot.prototype.reset = function () {
        this.point_groups = null;
        this.data = [];
        this.current_selection = [];
        this.subgraphs = [];
        this.plot_matrix = [];
        this.xform='';
    };

    pairplot.prototype.updateXform = function(xform) {
        this.xform=xform;
        this.draw();
    };
    
    pairplot.prototype.updateData = function(data) {
       
        var idxs = [];
        var my_selection = this.current_selection;
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
            for (i = 0; i < this.data.length; ++i) {
             this.plot_matrix[idx][i].setXData(data, false);
             this.plot_matrix[i][idx].setYData(data, false);
             this.plot_matrix[idx][i].update();
             if (i != idx) this.plot_matrix[i][idx].update();
        }     
      }
      _.each(this.subgraphs, function(g){g.setSelection(my_selection);});
    };

    pairplot.prototype.addData = function(data) {
        this.data.push(data);
        this.reloadSelection();
    };

    pairplot.prototype.pointIDs = function() {
        var ids = {};
        for (var i in this.data) {
            var d = this.data[i].data;
            for (var j in d) {
                ids[d[j].sample] = true;
            }
        }
        return _.keys(ids);
    };

    pairplot.prototype.getSelection = function() {
        return this.current_selection;
    };

    pairplot.prototype.setSelection = function(selection, quiet) {
        if (!_.isEqual(this.current_selection, selection)) {
            this.current_selection = selection;
            _.each(this.subgraphs, function(g) { g.setSelection(selection, quiet); });
            if (!quiet) $(this.svg).trigger('updateselection', [selection]);
        }
    };

    pairplot.prototype.reloadSelection = function(){
        var my_selection = this.current_selection;
        this.current_selection = [];
        this.draw();
        this.setSelection(my_selection, true);
    };
    
    pairplot.prototype.showLabels = function() {
        _.each(this.subgraphs, function(g) { g.showLabels(); });
    };
    
    pairplot.prototype.clearLabels = function() {
        _.each(this.subgraphs, function(g) { g.clearLabels(); });
    };
    
    pairplot.prototype.clearBrush = function() {
        _.each(this.subgraphs, function(g) { g.clearBrush(); });
    };

    pairplot.prototype.clearOtherBushes = function(event, scatterplot) {
        _.each(this.subgraphs, function(g) { if (g !== scatterplot) g.clearBrush(); });
    };

    pairplot.prototype.childSelectionUpdated = function(event, selection) {
        this.setSelection(selection);
    };

    pairplot.prototype.setScaleType = function(x_log, y_log) {
        this.options.x_log = x_log;
        this.options.y_log = y_log;
        _.each(this.subgraphs, function(s) { s.setScaleType(x_log, y_log); });
    };

    pairplot.prototype.setBaseAttrs = function(cls) {
        this.options.base_attrs = {};
        _.extend(this.options.base_attrs, cls);

        _.each(this.subgraphs, function(s) {
            s.setBaseAttrs(this.options.base_attrs);
        });
    };

    pairplot.prototype.setPointGroups = function(pgs) {
        this.point_groups = pgs;

        _.each(this.subgraphs, function(s) { s.setPointGroups(pgs); });
    };

    pairplot.prototype.legendSymbol = function(node, pg) {
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

    pairplot.prototype.draw = function() {
        var svg = d3.select(this.svg)

        svg.selectAll('*').remove();

        if (this.data.length == 0) return;

        var s_w = this.width  - this.options.padding[1] - this.options.padding[3] + this.options.separation;
        var s_h = this.height - this.options.padding[0] - this.options.padding[2] + this.options.separation;
        var N = this.data.length;
        var x, y;
        var xlo, xhi, ylo, yhi;

        var n_axis = 5;

        var s_opts = {
            inner: 3,
            outer: 5,
            axis_labels: false,
            display_corr: false,
            background: true,
            axes: false,
            makeGridLine: false,
            textOnly: false,
            minimal: this.options.minimalAxes,
            base_attrs: this.options.base_attrs,
            x_log: this.options.x_log,
            y_log: this.options.y_log,
        };

        this.subgraphs = []

        var sep = this.options.separation;

        if (this.options.axes && N < n_axis) {
            _.extend(s_opts, { padding: [ 5,20,46,50 ], pt_size: 11*1/N});

        } else {
            _.extend(s_opts, { padding: [ 5,5,5,5 ], pt_size: 1.5});
            sep = 5;
        }

        this.plot_matrix = new Array(N);
        for (x = 0; x < N; ++x) {
            this.plot_matrix[x] = new Array(N);
            for (y = 0; y < N; ++y) {
                var s;

                xlo = Math.floor(this.options.padding[3] + s_w * x / N);
                ylo = Math.floor(this.options.padding[0] + s_h * y / N);
                xhi = Math.floor(this.options.padding[3] + s_w * (x+1) / N - sep);
                yhi = Math.floor(this.options.padding[0] + s_h * (y+1) / N - sep);

                var g = svg.append('g').attr('transform', 'translate(' + String(xlo) + ',' + String(ylo) +')');

                if (x != y) {
                    _.extend(s_opts, { width: xhi - xlo, height: yhi - ylo });

                    var d = x-y;

                    _.extend(s_opts, {axes:((d==1 && N < n_axis) ? true : false)});

                    if (x < y ) {
                        s = new textpanel(s_opts, this.data[x], this.data[y]);
                        s.setXform(this.xform);
                    } else if (x > y ) {
                        s = new scatterplot(s_opts, this.data[x], this.data[y]);
                       
                        s.setSelection(this.current_selection, true);
                        s.setPointGroups(this.point_groups);
                        this.subgraphs.push(s);
                    }
                } else {
                    var gi_opts = { fsize_head: Math.max(12, 25 - N), fsize: Math.max(10, 16 - N), width: xhi - xlo, height: yhi - ylo };
                    s = new geneinfo(gi_opts, this.data[x]);
                }
                $(g[0]).append(s.svg);
                this.plot_matrix[x][y] = s;
                s.draw();
            }
        }
        $('svg.scatterplot', this.svg).on('updateselection', _.bind(this.childSelectionUpdated, this));
        $('svg.scatterplot', this.svg).on('brushstart',      _.bind(this.clearOtherBushes, this));
    };
})();


