define(["underscore", "d3", "djset", "node"], function(_, d3, dj, node) {
    "use strict"; // jshint ;_;

    var degrees = function(r) { return r * 180.0 / Math.PI; }
    var radians = function(d) { return d * Math.PI / 180.0; }
    var hypot = function(x, y) {
        var t;
        x = Math.abs(x);
        y = Math.abs(y);
        t = Math.min(x,y);
        x = Math.max(x,y);
        y = t;
        return x * Math.sqrt(1+(y/x)*(y/x));
    };

    var p2c = function(ang, rad) {
        ang = radians(ang);
        return [Math.cos(ang) * rad, Math.sin(ang) * rad ];
    };

    var c2p = function(x, y) {
        var ang = degrees(Math.atan2(y, x));
        return [ ang, hypot(x, y) ];
    }

    var arcplot = function(elem, options) {
        this.options = {
            max_weight:      1.0,
            cluster_minsize: 5,
            weight_inner:    1.0,
            weight_outer:    0.0,
            rad_inner:       50.0,
            rad_outer:       350.0,
            arc_increase:    0.0,
            scale_power:     4.0,
            font_size:       10.0,
            plot_dir:        180.0,
            plot_arc:        340.0,
            width:           1000,
            height:          750,
        };

        if (options !== undefined) {
            _.extend(this.options, options);
        }

        this.elem = $(elem);
        _.extend(this, Backbone.Events);
    };

    arcplot.prototype.zoom = function() {
        
        var S = d3.event.scale
        var T = d3.event.translate

/*
        if (T[0] > 0) T[0] = 0;
        if (T[1] > 0) T[1] = 0;
        if (T[0] + S * this.width < this.width) T[0] = this.width - (S * this.width);
        if (T[1] + S * this.height < this.height) T[1] = this.height - (S * this.height);
*/
        this.xform = { T: [T[0], T[1]], S: S };
        this.body.attr("transform", "translate(" + T + ")" + " scale(" + S + ")");

        this.updateLabels();
    };

    arcplot.prototype.resize = function() {
        setTimeout(_.bind(this._resize, this), 0);
    };

    arcplot.prototype._resize = function() {
        var curr_width = 0;
        var curr_height = 0;
        var svg = d3.select(this.elem[0]).select('svg');

        if (!svg.empty()) {
            curr_width = svg.attr('width');
            curr_height = svg.attr('height');
        } 

        var width = this.elem.width();
        var height = this.elem.height();

        if (curr_width != width || curr_height != height) {
            this.draw();
        }
    };

    arcplot.prototype.updateLabels = function() {
    	
        var self = this;
        var l = this.label_g.selectAll('g').data(this.labels);

        var g = l
          .enter()
            .append('g');

        g.append('circle')
            .attr('cx', 0)
            .attr('cy', 0)
            .attr('r', 4)
            .attr('stroke', '#eee')
            .attr('stroke-width', 1)
            .attr('fill',   '#000');
        g.append('rect').attr('height', 15).attr('x', 5).attr('y', -6).attr('fill', '#0074cc').attr('stroke', '#000');
        g.append('text').attr('x', 9).attr('y', 5);

        l
          .exit()
            .remove();

        l   .select('text')
            .text(function(d) { return _.has(d, 'text') ? d.text : d.id; });

        l.each(function(d) {
            var w = d3.select(this).select('text')[0][0].getBBox().width + 8;
            d3.select(this).select('rect').attr('width', w);
        });

        l
            .attr('transform', function(d) {
                var _x = self.xform.T[0] + self.xform.S * (d.pos[0] + self.width / 2);
                var _y = self.xform.T[1] + self.xform.S * (d.pos[1] + self.height / 2);
                return 'translate(' + String(_x) + ',' + String(_y) + ')';
            });
    };

    arcplot.prototype.scale = function(weight) {
        return Math.pow((weight - this.options.weight_inner) / (this.options.weight_outer - this.options.weight_inner), this.options.scale_power);
    };

    arcplot.prototype.invscale = function(scale) {
        return Math.pow(scale, 1.0/this.options.scale_power) * (this.options.weight_outer - this.options.weight_inner) + this.options.weight_inner;
    };

    arcplot.prototype.drawAxes = function() {
        var self = this;

        var axes = this.body
            .append('g')
            .attr('class', 'axes')
            .attr('transform', 'translate(' + String(this.width/2) + ',' + String(this.height/2) + ')');

        var ticks = [
            [1.0,   1],
            [0.5,   2],
            [0.4,   2],
            [0.3,   2],
            [0.25,  3],
            [0.2,   2],
            [0.15,  3],
            [0.1,   2],
            [0.075, 4],
            [0.05,  3],
            [0.025, 4],
            [0.0,   1]
        ];
        ticks = ticks.reverse();
        
        var w_lo = Math.min(this.options.weight_outer, this.options.weight_inner);
        var w_hi = Math.max(this.options.weight_outer, this.options.weight_inner);

        ticks = _.filter(ticks, function(x) { return w_lo <= x[0] && x[0] <= w_hi; });

        _.each(d3.range(30, 360, 60), function(ang) {
            var p1 = p2c(ang + self.options.plot_dir + 180.0, self.options.rad_inner);
            var p2 = p2c(ang + self.options.plot_dir + 180.0, self.options.rad_outer);
            axes
                .append('line')
                .attr('x1', p1[0]).attr('y1', p1[1])
                .attr('x2', p2[0]).attr('y2', p2[1])
                .attr('stroke', 'rgba(0,0,0,.2)')
                .attr('fill', 'none')
                .attr('stroke-width', '0.5');
        });

        _.each(ticks, function(tick) {
            var w = tick[0];
            var t = tick[1];

            var s = self.scale(w);
            var r = (1-s) * self.options.rad_inner + s * self.options.rad_outer;

            var a_start = degrees(Math.asin(self.options.font_size / r));

            var p1 = p2c(self.options.plot_dir + 180       + a_start, r);
            var p2 = p2c(self.options.plot_dir + 180 + 360 - a_start, r);
            var alpha = 0.5/t;
            axes
                .append('path')
                .attr('d',
                      'M' + String(p2[0]) + ',' + String(p2[1]) +
                      'A' + String(r) + ',' + String(r) + ' 0 1,0 ' + String(p1[0]) + ',' + String(p1[1]))
                .attr('stroke', 'rgba(0,0,0,' + String(alpha) + ')')
                .attr('fill', 'none')
                .attr('class', 'axis')
                .attr('stroke-width', '0.5')
                .on ('click', function(d) {d3.select(this).classed('selected', !d3.select(this).classed('selected')); })
                ;
                

            var p1 = p2c(self.options.plot_dir + 180, r);
            axes
                .append('text')
                .attr('x', p1[0])
                .attr('y', p1[1])
                .attr('dy', '.35em')
                .attr('text-anchor', 'middle')
                .attr('style', 'font-family: helvetica; font-size: ' + String(self.options.font_size) + 'px; font-weight: 600')
                .on ('click', function(d) {d3.select(this.previousSibling).classed('selected', !d3.select(this.previousSibling).classed('selected'));  })
                .text(String(1-w))
                ;
        });
    };

    arcplot.prototype._zoom = function() {
        this.zoom_behavior.scale(this.xform.S).translate(this.xform.T);

        this.body
            .transition()
            .duration(1000)
            .attr('transform', 'translate(' + this.xform.T + ') scale(' + this.xform.S + ')');

        var self = this;
        this.label_g.selectAll('g')
            .data(this.labels)
            .transition()
            .duration(1000)
            .attr('transform', function(d) {
                var _x = self.xform.T[0] + self.xform.S * (d.pos[0] + self.width / 2);
                var _y = self.xform.T[1] + self.xform.S * (d.pos[1] + self.height / 2);
                return 'translate(' + String(_x) + ',' + String(_y) + ')';
            });
    };
    
    arcplot.prototype.dezoom = function(){
        this.xform = { T: [0,0], S: 1 };
        this._zoom();
    };
    
    
    arcplot.prototype.zoomTo = function(id) {
        
        var arc = this.body
            .selectAll('path.arc')
            .classed('highlight', function(d) { return d.content.hasOwnProperty(id); });

        
        var hl = this.body
            .selectAll('path.arc.highlight');
        
        var S, T;
        
        if (hl[0].length === 1) {
            var bbox = hl[0][0].getBBox();

            S = Math.max(1, Math.min(20, 500.0/Math.max(bbox.width, bbox.height)));
            T = [
                (-(bbox.x + bbox.width/2) - this.width/2) * S + this.width/2,
                (-(bbox.y + bbox.height/2) - this.height/2) * S + this.height/2
            ];

            if (T[0] > 0) T[0] = 0;
            if (T[1] > 0) T[1] = 0;

            if (T[0] + S * this.width < this.width) T[0] = this.width - (S * this.width);
            if (T[1] + S * this.height < this.height) T[1] = this.height - (S * this.height);

        } else {
            console.log(id+' not found'); 
            return;
        }

        this.xform = { T: T, S: S };
        this._zoom();
    };

    arcplot.prototype.arcAngle = function(arc) {
        var weight = arc[0]
        var count = arc[1];
        var scale = this.scale(weight);
        var arc_divisions = this.arc_divisions * (1 + this.options.arc_increase * scale);
        var div_ang = this.options.plot_arc / arc_divisions;

        return count * div_ang;
    };

    arcplot.prototype.arc = function(arc_dir, arc) {
        var weight = arc[0]
        var count = arc[1];
        var scale = this.scale(weight);
        var arc_divisions = this.arc_divisions * (1 + this.options.arc_increase * scale);
        var div_ang = this.options.plot_arc / arc_divisions;

        return [ arc_dir - count * div_ang / 2.0, arc_dir + count * div_ang / 2.0 ];
    };

    arcplot.prototype.arcEndpoints = function(arc_dir, arc) {
        var a = this.arc(arc_dir, arc);
        var s = this.scale(arc[0]);
        var r = (1-s) * this.options.rad_inner + s * this.options.rad_outer;

        var p1 = p2c(a[0], r);
        var p2 = p2c(a[1], r);
        return { x1: p1[0], y1: p1[1], x2: p2[0], y2: p2[1] }
    };

    arcplot.prototype.collapseUnbranched = function(subtree) {
        var p, n;

        for (p = new node.PostorderTraversal(subtree); (n = p.next()) !== null; ) {
            if (n.children.length === 1) {
                var c = n.children[0];
                n.lev = n.lev.concat(c.lev);
                _.extend(c.content, n.content);
                n.content = c.content;
                n.children = c.children;
            }
        }
    };

    arcplot.prototype.findBestMatches = function(
        clusters,
        statistic,
        comparator) {
        var i, j;

        var my_ids = this.root.getContent();
        var cids = {}
        var c_counts = [];

        var total = 0;

        var r = this.root.getContent();

        for (i = 0; i < clusters.length; ++i) {
            var k = _.keys(clusters[i]);
            var k_count = 0;
            for (j = 0; j < k.length; ++j) {
                if (!_.has(r, k[j])) continue;
                if (!_.has(cids, k[j])) {
                    cids[k[j]] = [];
                    total++;
                }
                cids[k[j]].push(c_counts.length);
                k_count++;
            }
            c_counts.push(k_count);
        }

        var n_clusters = c_counts.length;
        var n, p;

        for (p = new node.PostorderTraversal(this.root); (n = p.next()) !== null; ) {
            n.__pp = new Array(n_clusters);
            n.__pn = new Array(n_clusters);

            for (i = 0; i < n_clusters; ++i) {
                n.__pp[i] = n.__pn[i] = 0;
            }

            for (i = 0; i < n.children.length; ++i) {
                var c = n.children[i];
                for (j = 0; j < n_clusters; ++j) {
                    n.__pp[j] += c.__pp[j];
                    n.__pn[j] += c.__pn[j];
                }
            }

            var content = _.keys(n.content);

            var __pn = 0
            for (i = 0; i < content.length; ++i) {
                if (_.has(cids, content[i])) ++__pn;
            }

            for (i = 0; i < n_clusters; ++i) {
                n.__pn[i] += __pn;
            }

            var n_missed = 0;

            for (i = 0; i < content.length; ++i) {
                var id = content[i];
                if (_.has(cids, id)) {
                    var x = cids[id];
                    for (j = 0; j < x.length; ++j) {
                        n.__pp[x[j]]++;
                        n.__pn[x[j]]--;
                    }
                } else {
                    console.log('missed ids: ', id);
                    n_missed++;
                }
            }

            var x_max = -1.0;
            var x_max_i = -1;
            var x_tab = [ 0, 0, 0, 0 ];

            for (i = 0; i < n_clusters; ++i) {
                var __pp = n.__pp[i];
                var __pn = n.__pn[i];
                var __np = c_counts[i] - n.__pp[i];
                var __nn = total - n.__pn[i] - __np - n.__pp[i];

                // This is to avoid quantifying a depletion of the (now smaller) background as an
                // enrichment in the cluster.  It will also very slightly speed up computations.
                if (__pp + __pn > __np + __nn) continue;

                var x = statistic (__pp, __pn, __np, __nn);
                if (x === undefined) continue;
                
                if (comparator (x, x_max)) {
                    // if (x > 0.001) {
                    //   console.log ("significant", __pp, __pn, __np, __nn, x);
                    // }
                    x_max = x;
                    x_max_i = i;
                    x_tab = [ __pp, __pn, __np, __nn ];
                }
            }

            n.__x_max = x_max;
            n.__x_max_i = x_max_i;
            n.__x_tab = x_tab;

            for (i = 0; i < n.children.length; ++i) {
                var c = n.children[i];
                delete c.__pp;
                delete c.__pn;
            }
        }
    };

    arcplot.prototype._goLabels = function() {
        for (var i = 0; i < this.labels.length; ++i) {
            var go_term = go_cache.get(this.labels[i].id);
            if (go_term !== undefined) {
                this.labels[i].text = '[' + go_term.id + '] ' + go_term.get('desc');
            }
        }
        this.updateLabels();
    };

    arcplot.prototype.goLabels = function() {
        var unfetched = [];

        for (var i = 0; i < this.labels.length; ++i) {
            var go_term = go_cache.get(this.labels[i].id);
            if (go_term !== undefined) {
                this.labels[i].text = go_term.get('desc');
            } else {
                unfetched.push(this.labels[i].id);
            }
        }

        this.updateLabels();

        if (unfetched.length) {
            var qs = ''
            for (var i = 0; i < unfetched.length; ++i) {
                if (qs.length) qs += '&';
                qs += $.param({ id: unfetched[i] });
            }
            go_cache.on('all', _.bind(this._goLabels, this));
            go_cache.fetch({ data: qs, update: true });
        }
    };

    arcplot.prototype.clearLabels = function() {
        go_cache.off('all');
        this.labels = [];
        this.label_g.selectAll('g').remove();
    };

    arcplot.prototype.colourByClusterNumber = function(clusters, statistic, comparator, cluster_info) {
        this.findBestMatches(clusters, statistic, comparator);

        var n_nodes = 0;
        for (var p = new node.PostorderTraversal(this.root); (n = p.next()) !== null; ) {
            n.__idx = n_nodes++;
        }

        var groups = new dj.djset(n_nodes);
        for (var p = new node.PostorderTraversal(this.root); (n = p.next()) !== null; ) {
            for (var i = 0; i < n.children.length; ++i) {
                if (n.__x_max_i == n.children[i].__x_max_i) {
                    groups.merge_sets(n.__idx, n.children[i].__idx);
                }
            }
        }

        var grp_lookup = {};
        var grp_content = [];
        for (var p = new node.PostorderTraversal(this.root); (n = p.next()) !== null; ) {
            var i = groups.find_set_head(n.__idx);
            if (_.has(grp_lookup, i)) {
                grp_content[grp_lookup[i]].push(n);
            } else {
                grp_lookup[i] = grp_content.length;
                grp_content[grp_lookup[i]] = [n];
            }
        }

        this.clearLabels();

        var is_max = {};
        for (var i = 0; i < grp_content.length; ++i) {
            var max_j = 0;
            for (var j = 0; j < grp_content[i].length; ++j) {
                if (grp_content[i][max_j].__x_max < grp_content[i][j].__x_max) {
                    max_j = j;
                }
            }

            var max_node = grp_content[i][max_j];
            if (max_node.__x_max_i == -1) continue;

            var l = _.extend({},
                             cluster_info[max_node.__x_max_i],
                             { pos: this.nodeMidpoint(max_node) });
            this.labels.push(l);
        }
        this.updateLabels();

        var cids = {};
        for (var p = new node.PostorderTraversal(this.root); (n = p.next()) !== null; ) {
            cids[n.__x_max_i] = true;
        }

        var cid_keys = _.keys(cids);
        for (var i = 0; i < cid_keys.length; ++i) {
            cids[cid_keys[i]] = d3.rgb(
                Math.min(255, Math.floor(Math.random() * 256)),
                Math.min(255, Math.floor(Math.random() * 256)),
                Math.min(255, Math.floor(Math.random() * 256))
            )
        }
        cids[-1] = '#000';

        this.body
            .selectAll('path.arc')
            .attr('fill', function(d) { return cids[d.__x_max_i]; });
    };

    arcplot.prototype.colourByClusterMatch = function(clusters, statistic, comparator, ramp) {
        this.findBestMatches(clusters, statistic, comparator);
        this.body
            .selectAll('path.arc')
            .attr('fill', function(d) { return d.__x_max_i == -1 ? ramp (0) : ramp(d.__x_max); });
    };

    arcplot.prototype.removeColour = function() {
        var arcs = this.body
            .selectAll('path.arc')
            .attr('fill', '#000');
    };

    arcplot.prototype.setGraphInfo = function(graph_info) {
        // graph_info is a list of element to be displayed at the top-left position in the svg image 
        // see .draw function for actual display
        
        this.graph_info = graph_info;
    };

    arcplot.prototype.setData = function(roots) {
        var self = this;

        roots = _.map(roots, function(x) { return x.collapse(self.options.cluster_minsize); });

        var total_size = 0;
        _.each(roots, function(x) {
            total_size += x.size;
        });

        this.arc_divisions = total_size;

        this.root = new node.Node({
            content:  {},
            size:     total_size,
            children: roots,
            weight:   this.options.max_weight,
            arc_dir:  this.options.plot_dir
        });

        var n, p;

        for (p = new node.PreorderTraversal(this.root); (n = p.next()) !== null; ) {
            n.lev = [ [n.weight, n.size] ];
        }

        this.collapseUnbranched(this.root);

        for (p = new node.PreorderTraversal(this.root); (n = p.next()) !== null; ) {
            var arc_tot = 0;
            _.each(n.children, function(c) {
                arc_tot += c.size;
            });

            var arc_pos = 0.0;
            _.each(n.children, function(c) {
                var arc = self.arc(n.arc_dir, _.last(n.lev));
                var arc_frac = c.size / arc_tot;
                c.lev.splice(0, 0, [ _.last(n.lev)[0], c.size ]);
                c.arc_dir = arc[0] + (arc[1]-arc[0]) * (arc_pos/arc_tot + arc_frac/2.0);
                arc_pos += c.size;
            });
        }
    };

    arcplot.prototype.nodeMidpoint = function(n) {
        var s1 = this.scale(_.first(n.lev)[0]);
        var r1 = (1-s1) * this.options.rad_inner + s1 * this.options.rad_outer;

        var s2 = this.scale(_.last(n.lev)[0]);
        var r2 = (1-s2) * this.options.rad_inner + s2 * this.options.rad_outer;

        return p2c(n.arc_dir, (r1 + r2) / 2);
    };

    arcplot.prototype.nodePath = function(n) {
        var self = this;

        var lev = n.lev;

        if (lev.length === 1) {
            lev = [ lev[0], lev[0] ];
        }

        var s1 = this.scale(_.first(lev)[0]);
        var r1 = (1-s1) * this.options.rad_inner + s1 * this.options.rad_outer;

        var s2 = this.scale(_.last(lev)[0]);
        var r2 = (1-s2) * this.options.rad_inner + s2 * this.options.rad_outer;

        var ae = _.map(lev, function(l) {
            return self.arcEndpoints(n.arc_dir, l);
        });

        var path;
        var a_short;

        path = 'M' + String(ae[0].x1) + ',' + String(ae[0].y1);

        for (var i = 1; i < ae.length; ++i) {
            path += 'L' + String(ae[i].x1) + ',' + String(ae[i].y1);
        }

        a_short = this.arcAngle(_.last(lev)) < 180.0;
        path += 'A' + String(r2) + ',' + String(r2) + ' 0 ' + (a_short ? '0' : '1') + ',1 ' + String(ae[ae.length-1].x2) + ',' + String(ae[ae.length-1].y2);

        for (var i = ae.length - 2; i >= 0; --i) {
            path += 'L' + String(ae[i].x2) + ',' + String(ae[i].y2);
        }

        a_short = this.arcAngle(_.first(lev)) < 180.0;
        path += 'A' + String(r1) + ',' + String(r1) + ' 0 ' + (a_short ? '0' : '1') + ',0 ' + String(ae[0].x1) + ',' + String(ae[0].y1);

        path += 'Z';

        return path;
    };

    arcplot.prototype.click = function(n) {
        this.trigger('click:cluster', _.keys(n.getContent()));
    };

    arcplot.prototype.draw = function() {
        
        var self = this;
        
        
        this.width = this.elem.width();
        this.height = this.elem.height();

        // reset the container 
        this.elem.empty();
        
        
        d3.select(this.elem[0])
            .append('svg')
            .attr("width", this.width)
            .attr("height", this.height)
            .attr('version', '1.1')
            .attr('baseProfile', 'full')
            .attr("pointer-events", "all")
            .attr('xmlns', 'http://www.w3.org/2000/svg');

        this.svg  = d3.select(this.elem[0]).select('svg');
        
        this.zoom_behavior =
          d3.behavior.zoom()
            .scaleExtent([0.75, 50])
            .on("zoom", _.bind(this.zoom, this))
        
        this.zoom_g = this.svg
            .append('g')
            .call(this.zoom_behavior);
 
        this.xform = { T: [ 0, 0 ], S: 1.0 };
        
        this.body = this.zoom_g
            .append('g');

        this.labels = [];

        this.label_g = this.svg
            .append('g')
            .attr('class', 'labels')
            .attr('style', 'font-family: helvetica; font-size: 10px; font-weight: 400')
            .attr('dy', 5)
            .attr('fill', '#fff')
            .attr("pointer-events", "none");        

        this.body
            .append('rect')
            .attr('width', 4*this.width)
            .attr('height', 4*this.height)
            .attr('x', -2*this.width)
            .attr('y', -1.5*this.height)
            .attr('fill', 'white')
            .attr('stroke', 'rgba(0,0,0,.2)')
            .attr('stroke-width', '1')
            .attr('shape-rendering', 'crispEdges');

        this.body
            .append('g')
            .attr('class', 'graph_info')
            .attr('transform', 'translate(10,20)');
            
        // should have a better way than a fixed offset? http://www.w3.org/TR/SVG/text.html    
        for (var i=0;i<this.graph_info.length;i++) {    
            this.body
                .select('g.graph_info')
                .append('text')
                .attr('x', 0)
                .attr('y', i*15)
                .text(this.graph_info[i])
        }
        
        this.drawAxes();

        this.body
            .append('g')
            .attr('class', 'plot')
            .attr('transform', 'translate(' + String(this.width/2) + ',' + String(this.height/2) + ')');

        var nodes = [];
        var n, p;
        for (p = new node.PreorderTraversal(this.root); (n = p.next()) !== null; ) {
            nodes.push(n);
        }
        
        this.body
            .select('g.plot')
            .selectAll('path.arc')
            .data(nodes)
            .enter()
            .append('path')
            .attr('class', 'arc')
            .attr('d', function(n) { return self.nodePath(n); })
            .attr('fill', 'black')
            .attr('stroke', 'none')
            .on('click', _.bind(this.click, this));
            
    
    };

    return {
        arcplot: arcplot
    };
});
