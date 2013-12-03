(function() {
    var defaults = {
        padding: [ 20,20,20,20 ], // amount that the plot region is inset by. [ top, right, bottom, left ]
        separation: 10,
        width: 1000,
        height: 1000,
        axes: true,
        minimalAxes: false,

        base_attrs: {
            d:       d3.svg.symbol().type("circle")(),
            fill:    "#000",
            stroke:  null,
            opacity: 0.65,
        },

        class_attrs: {
            g1: { fill: "#fc8403", stroke: null },
            g2: { fill: "#0bbede", stroke: null },
            g3: { fill: "#249924", stroke: null },
            g4: { fill: "#9b2a8d", stroke: null },
        }
    };

    pairplot = function(xdata, ydata, elem, options) {
        this.options = {};

        _.extend(this.options, defaults);

        if (options !== undefined) {
            _.extend(this.options, options);
        }

        this.options.base_attrs = _.clone(this.options.base_attrs)
        this.options.class_attrs = _.clone(this.options.class_attrs)

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

        this.point_class = {};

        this.data = [];
        this.current_selection = [];
        this.subgraphs = [];
    };

    pairplot.prototype.setMinimalAxes = function(b) {
      this.options.minimalAxes = b;
    };

    pairplot.prototype.resize = function(width, height) {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            d3.select(this.svg)
                .attr("width", width)
                .attr("height", height);

            this.draw();
        }
    };

    pairplot.prototype.removeData = function(matcher) {
        this.data = _.reject(this.data, matcher);
        this.draw();
    };

    pairplot.prototype.addData = function(data) {
        this.data.push(data);
        this.draw();
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

    pairplot.prototype.childSelectionUpdated = function(event, selection) {
        this.setSelection(selection);
    };

    pairplot.prototype.setBaseAttrs = function(cls) {
        this.options.base_attrs = {};
        _.extend(this.options.base_attrs, cls);

        _.each(this.subgraphs, function(s) {
            s.setBaseAttrs(this.options.base_attrs);
        });
    };

    pairplot.prototype.setClassAttrs = function(grp, cls) {
        this.options.class_attrs[grp] = cls;

        _.each(this.subgraphs, function(s) {
            s.setClassAttrs(this.options.class_attrs);
        });
    };

    pairplot.prototype.pointsWithClass = function(cls) {
        var self = this;
        return _.filter(_.keys(this.point_class), function(key) { return !!self.point_class[key][cls]; });
    };

    pairplot.prototype.hasPointClass = function(key, cls) {
        return !!this.pointclass[key][cls]
    };

    pairplot.prototype.setPointClasses = function(clsdata) {
        this.point_class = {};
        for (var i in clsdata) {
            this.point_class[i] = _.clone(clsdata[i]);
        }
        _.each(this.subgraphs, function(s) {
            s.setPointClasses(clsdata);
        });
    };

    pairplot.prototype.addPointClass = function(keys, cls) {
        var self = this;
        _.each(keys, function(k) {
            if (self.point_class[k] === undefined) {
                self.point_class[k] = {};
            }
            self.point_class[k][cls] = true;
        });
        _.each(this.subgraphs, function(s) {
            s.addPointClass(keys, cls);
        });
    };

    pairplot.prototype.remPointClass = function(keys, cls) {
        var self = this;
        _.each(keys, function(k) {
            if (self.point_class[k] !== undefined) {
                delete self.point_class[k][cls];
            }
        });
        _.each(this.subgraphs, function(s) {
            s.remPointClass(keys, cls);
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
            class_attrs: this.options.class_attrs
        };

        this.subgraphs = []

        var sep = this.options.separation;

        if (this.options.axes && N < n_axis) {
            _.extend(s_opts, { padding: [ 5,20,46,50 ], pt_size: 11*1/N});

        } else {
            _.extend(s_opts, { padding: [ 5,5,5,5 ], pt_size: 1.5});
            sep = 5;
        }

        for (x = 0; x < N; ++x) {
            for (y = 0; y < N; ++y) {
                xlo = Math.floor(this.options.padding[3] + s_w * x / N);
                ylo = Math.floor(this.options.padding[0] + s_h * y / N);
                xhi = Math.floor(this.options.padding[3] + s_w * (x+1) / N - sep);
                yhi = Math.floor(this.options.padding[0] + s_h * (y+1) / N - sep);

                var g = svg.append('g').attr('transform', 'translate(' + String(xlo) + ',' + String(ylo) +')');

                if (x != y) {
                    _.extend(s_opts, { width: xhi - xlo, height: yhi - ylo });

                    var d = x-y;

                    _.extend(s_opts, {axes:((d==1 && N < n_axis) ? true : false)});

                    var s;
                    if (x < y ) {
                        s = new textpanel(s_opts, this.data[x], this.data[y]);
                    } else if (x > y ) {
                        s = new scatterplot(s_opts, this.data[x], this.data[y]);
                        s.setSelection(this.current_selection, true);
                        s.setPointClasses(this.point_class);
                        this.subgraphs.push(s);
                    }
                    $(g[0]).append(s.svg);
                }

                else {
                    //console.log(JSON.stringify(this.data[x].symbol));

                     var fsize_symbol = 25-N;
                     var name_length = this.data[x].name.length;
                     var name = this.data[x].name  ?  this.data[x].name  : this.data[x].gene;
                     var name_space = this.width/(N)-this.options.padding[3]*N*2 - 50;

                     if ((name_space)<name_length) {
                        if ((name_space)>3) {   name = name.slice(1,name_space)+'...';}
                        else {name = '';}
                     }

                     var fsize_name = 16-N;


                     g.append('text')
                        .attr('x', (xhi-xlo)/2)
                        .attr('y', (yhi-ylo)/5-8)
                        .attr('dy', '12px')
                        .attr('text-anchor', 'middle')
                        .attr('style', 'font-family: helvetica; font-size: ' + fsize_symbol + 'px; font-weight: 600')
                        .attr('id', 'text-symbol')
                        .text(this.data[x].symbol ? this.data[x].symbol : this.data[x].gene);

                     if (name!='') {
                     g.append('text')
                        .attr('x', (xhi-xlo)/2)
                        .attr('y', (yhi-ylo)/5+8)
                        .attr('dy', '12px')
                        .attr('text-anchor', 'middle')
                        .attr('style', 'font-family: helvetica; font-size: '+ fsize_name +'px; font-weight: 600')
                        .attr('id', 'text-name')
                        .text(name);
                     }

                     var fsize = 16-N, d=40, p=15;

                     if (N>4){  p=11, d= 38;}
                     if (name=='') {d = d-10;}

                     var expr = _.map(this.data[x].data, function(d) {return d.expr});

                     var sd_e = stats.stdev(expr);
                     var mu_e = stats.average(expr);
                     var rg_e = stats.range(expr);

                     if (fsize >= 10) {

                     g.append('text')
                        .attr('x', (xhi-xlo)/2)
                        .attr('y', (yhi-ylo)/5+d)
                        .attr('text-anchor', 'middle')
                        .attr('style', 'font-family: helvetica; font-size: '+fsize+'px; font-weight: 600')
                        .text('Mean =  ' + mu_e.toFixed(2));


                     g.append('text')
                        .attr('x', (xhi-xlo)/2)
                        .attr('y', (yhi-ylo)/5+d+p)
                        .attr('text-anchor', 'middle')
                        .attr('style', 'font-family: helvetica; font-size: '+fsize+'px; font-weight: 600')
                        .text('Std =  ' + sd_e.toFixed(2));
                     }

                    else { p=0; fsize=11;}

                     g.append('text')
                        .attr('x', (xhi-xlo)/2)
                        .attr('y', (yhi-ylo)/5+d+2*p)
                        .attr('text-anchor', 'middle')
                        .attr('style', 'font-family: helvetica; font-size: '+fsize+'px; font-weight: 600')
                        .text(' [' + rg_e[0].toFixed(2) +", "+ rg_e[1].toFixed(2)+"]");


                }
            }
        }
        $('svg', this.svg).on('updateselection', _.bind(this.childSelectionUpdated, this));

    };


})();


