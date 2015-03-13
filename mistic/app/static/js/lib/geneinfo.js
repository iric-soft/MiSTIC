(function() {
    geneinfo = function(options, data) {
        this.options = {
            width: 1000,
            height: 1000,
            fsize_head: 25,
            fsize: 16,
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

        this.setData(data, false);
    };

    geneinfo.prototype.setXData = function(data, redraw) {
        this.data = data;

        if (redraw) this.draw();
    };

    geneinfo.prototype.setYData = function(data, redraw) {
    };

    geneinfo.prototype.setData = geneinfo.prototype.setXData;

    geneinfo.prototype.draw = function() {
        var self = this;

        var svg = d3.select(this.svg);
        svg.selectAll('*').remove();

        var g = svg.append('g');

        var expr = _.map(this.data.data, function(d) {return d.expr;});

        var sd_e = stats.stdev(expr);
        var mu_e = stats.average(expr);
        var rg_e = stats.range(expr);

        var head = this.data.symbol ? this.data.symbol : this.data.gene;
        var name = this.data.name ? this.data.name : this.data.gene;

        var data = [
            { key: 1, pri: 3, text: head,                                                   weight: 600, fsize: this.options.fsize_head },
            { key: 2, pri: 0, text: name,                                                   weight: 600, fsize: this.options.fsize },
            { key: 3, pri: 1, text: "Mean = " + mu_e.toFixed(2),                            weight: 600, fsize: this.options.fsize },
            { key: 4, pri: 1, text: "Std = " + sd_e.toFixed(2),                             weight: 600, fsize: this.options.fsize },
            { key: 5, pri: 2, text: "[" + rg_e[0].toFixed(2) +", "+ rg_e[1].toFixed(2)+"]", weight: 600, fsize: this.options.fsize },
        ];

        g.selectAll('text')
            .data(data, function (d) { return d.key; })
          .enter()
            .append('text')
            .attr('style', function (d) { return 'font-family: helvetica; font-size: ' + d.fsize + 'px; font-weight: ' + d.weight; })
            .text(function (d) { return d.text; });

        g.selectAll('text')
            .each(function(d) {
                try {
                    d.bbox = this.getBBox();
                }
                // firefox error
                catch(err) {
                    mysvg = $(this).parents()[1];
                    d.bbox = mysvg.createSVGRect ();
                }
                for (var i = d.text.length-1; d.bbox.width > self.width && i >= 0; --i) {
                    d3.select(this).text(d.text.substring(0, i) + '...');
                    d.bbox = this.getBBox();
                }
            });

        var total_height = _.reduce(data, function(a,d) { return a + d.bbox.height; }, 0);

        var pri = 1;

        while (total_height > this.height) {
            console.log('pri='+pri);
            data = _.reject(data, function (d) { return d.pri < pri; });
            total_height = _.reduce(data, function(a,d) { return a + d.bbox.height; }, 0);
            pri += 1;
        }

        g.selectAll('text')
            .data(data, function (d) { return d.key; })
            .exit()
            .remove();

        y = this.height / 2 - total_height / 2;

        g.selectAll('text')
            .each(function(d) {
                y += d.bbox.height;
                d3.select(this)
                    .attr('x', self.width/2 - d.bbox.width/2)
                    .attr('y', y);
            });
    };

    geneinfo.prototype.update = geneinfo.prototype.draw;
})();
