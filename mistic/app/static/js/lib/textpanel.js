(function() {
    textpanel = function(options, xdata, ydata) {
        this.options = {
            padding: [ 20,20,60,60 ], // amount that the plot region is inset by. [ top, right, bottom, left ]
            inner: 10,   // amount that the plot background is expanded by.
            outer: 15,   // amount that the plot axes are moved by.
            width: 1000,
            height: 1000,
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
            .attr('xmlns', 'http://www.w3.org/2000/svg');

        this.xdata = undefined;
        this.ydata = undefined;

        this.setXData(xdata, false);
        this.setYData(ydata, false);

        this.draw();
    };

    textpanel.prototype.resize = function(width, height) {
        if (this.width != width || this.height != height) {
            this.width = width;
            this.height = height;

            d3.select(this.svg)
                .attr("width", width)
                .attr("height", height);

            this.draw();

        }
    };

    textpanel.prototype.datadict = function(data) {
        var vals = {};
        for (var i in data) {
            var pt = data[i];
            vals[pt.sample] = pt.expr;
        }
        return vals;
    };

    textpanel.prototype.setLog = function(l) {
        this.options.lg=l;
    };

    textpanel.prototype.setXData = function(xdata, redraw) {
        if (xdata !== undefined) {
            this.xlab = xdata.symbol;
            this.xdata = this.datadict(xdata.data);
        } else {
            this.xdata = undefined;
        }
        if (redraw !== false) this.draw();
    };

    textpanel.prototype.setYData = function(ydata, redraw) {
        if (ydata !== undefined) {
            this.ylab = ydata.symbol;
            this.ydata = this.datadict(ydata.data);
        } else {
            this.ydata = undefined;
        }
        if (redraw !== false) this.draw();
    };

    textpanel.prototype.draw = function(data) {
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

        var fsize = 12-100/width;

        svg .append('rect')
            .attr('width', width)
            .attr('height', height)
            .attr('x', this.options.padding[3] - this.options.inner)
            .attr('y', this.options.padding[0] - this.options.inner)
            .attr('fill', 'white');
        if (fsize > 8) {
            this.corr = svg .append('text')
                .attr('x', this.options.padding[3]+ width/20)
                .attr('y', this.options.padding[0]+ height/3)
                .attr('text-anchor', 'left')
                .attr('style', 'font-family: helvetica; font-size: '+ fsize+ 'px; font-weight: 300');
            if (lg) {
                var rtext = fsize>=11 ? 'r(log+k) = ' : '';
                this.corr.text(rtext + r_log.toFixed(2));
            } else {
                var rtext = fsize>=11 ? 'r = ' : '';
                this.corr.text(rtext + r.toFixed(2));
            }
        }
    };
})();
