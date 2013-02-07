(function() {
    pairplot = function(xdata, ydata, elem) {
        this.options = {
            padding: [ 20,20,20,20 ], // amount that the plot region is inset by. [ top, right, bottom, left ]
            separation: 20,
            width: 1000,
            height: 1000,
            axes: true,
        };

        this.svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
 
        this.width = this.options.width;
        this.height = this.options.height;

        d3.select(this.svg)
            .attr("width", this.width)
            .attr("height", this.height)
            .attr('version', '1.1')
            .attr('xmlns', 'http://www.w3.org/2000/svg');

        this.data = [];
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


    pairplot.prototype.draw = function() {
        var svg = d3.select(this.svg)

        svg.selectAll('*').remove();

        if (this.data.length == 0) return;

        var s_w = this.width  - this.options.padding[1] - this.options.padding[3] + this.options.separation;
        var s_h = this.height - this.options.padding[0] - this.options.padding[2] + this.options.separation;
        var N = this.data.length;
        var x, y;
        var xlo, xhi, ylo, yhi;
            
        var s_opts = {
            inner: 3,
            outer: 5,
            axis_labels: false,
            display_corr: false,
            background: true,
            axes: false,
            makeGridLine:true,
        };
		
        var sep = this.options.separation;

        if (this.options.axes && N < 4) {
            _.extend(s_opts, { padding: [ 5,20,46,50 ], axes:true });
        } else {
            _.extend(s_opts, { padding: [ 5,5,5,5 ],axes:true,  axis_labels:false,  pt_size: 2 });
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

                    var s = new scatterplot(s_opts, this.data[x], this.data[y]);
                    var result = s.svg;
  
                    $(g[0]).append(result);
                } else {
                    console.log(JSON.stringify(this.data[x].symbol));
                    g   .append('text')
                        .attr('x', (xhi-xlo)/2)
                        .attr('y', (yhi-ylo)/2)
                        .attr('dy', '12px')
                        .attr('text-anchor', 'middle')
                        .attr('style', 'font-family: helvetica; font-size: 24px; font-weight: 600')
                        .text(this.data[x].symbol ? this.data[x].symbol : this.data[x].gene);
                }
            }
        }
        
     
    };
      
        
})();

