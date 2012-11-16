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
            axis_labels: true,
            background: true,
            axes: true,
            display_corr: true,
            pt_size: 4,
            makeGridLine:false,
            gridValue: 10,  // rpkm
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
            .attr('xmlns', 'http://www.w3.org/2000/svg');

        this.xdata = undefined;
        this.ydata = undefined;
        this.go_term = undefined;

        this.setXData(xdata, false);
        this.setYData(ydata, false);

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

    scatterplot.prototype.setXData = function(xdata, redraw) {
        if (xdata !== undefined) {
            this.xlab = xdata.symbol;
            this.xdata = this.datadict(xdata.data);
        } else {
            this.xdata = undefined;
        }
        if (redraw !== false) this.draw();
    };

    scatterplot.prototype.setYData = function(ydata, redraw) {
        if (ydata !== undefined) {
            this.ylab = ydata.symbol;
            this.ydata = this.datadict(ydata.data);
        } else {
            this.ydata = undefined;
        }
        if (redraw !== false) this.draw();
    };

							 
	scatterplot.prototype.highlightCircle = function (d){
		

        var circles = d3.selectAll('#graph svg').selectAll('circle'); 
	
		for (i=0; i<circles.data().length; i++){
			var c = circles[0][i];
			var e = circles.data()[i];					
			if (e.k==d.k){
                d3.select(c).classed('highlighted', !d3.select(c).classed('highlighted'))

			}	
		}	
		addInformation(d.k);
		
	};
	
    scatterplot.prototype.makeAxes = function() {
        var xAxis = d3.svg
            .axis()
	    .scale(this.xScale)
	    .orient("bottom")
            .tickFormat(this.xScale.tickFormat(5, d3.format(".1f")))
	    .ticks(5);

		var yAxis = d3.svg
            .axis()
	    .scale(this.yScale)
	    .orient("left")
            .tickFormat(this.xScale.tickFormat(5, d3.format(".1f")))
	    .ticks(5);

        var svg = d3.select(this.svg);

        svg .append("g")
	    .attr("class", "axis axis-x")
	    .attr("transform", "translate(0," + (this.height - this.options.padding[2] + this.options.outer) + ")")
	    .call(xAxis);

	    svg .append("g")
	    .attr("class", "axis axis-y")
	    .attr("transform", "translate(" + (this.options.padding[3] - this.options.outer) + ",0)")
	    .call(yAxis);

        svg .selectAll('.axis path, .axis line')
            .attr('fill', 'none')
            .attr('stroke', 'black')
            .attr('shape-rendering', 'crispEdges');

        svg .selectAll('.axis text')
            .attr('style', 'font-family: helvetica; font-size: 11px; font-weight: 100');

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
	scatterplot.prototype.makeGridLine = function(){

		var self = this;
        var svg = d3.select(this.svg);
    		  
        svg.append('g')
        		.attr('class', 'grid-lines').attr('opacity', .5);
        		
        if (this.yScale.domain()[0]< 10 ){
       		svg.select('g.grid-lines')	
       			.selectAll('rect')
       			.data([this.options.gridValue])
       			.enter()
       			.append('rect')
       			.attr('class', 'grid-lines-y')
       			.attr('width', this.xScale.range()[1]-this.xScale.range()[0])
            	.attr('height', function (d) { var y=d3.min([d, self.yScale.domain()[1]]); return (self.yScale.range()[0]-self.yScale(y)); } )
            	.attr('x', this.xScale.range()[0])
            	.attr('y', function(d) {var y=d3.min([d, self.yScale.domain()[1]]); return self.yScale(y)})
            	//.attr('fill', 'rgba(0,0,0,.08)');
            	.attr('fill', 'url(#hatch00)');
     	}
     	
        if (this.xScale.domain()[0]< 10 ){
               
       		svg.select('g.grid-lines')	
       			.append('rect')
       			.attr('class', 'grid-lines-x')
       			.attr('width', function (d) {var x=d3.min([self.options.gridValue, self.xScale.domain()[1]]);return self.xScale(x)-self.xScale.range()[0];})
            	.attr('height', this.yScale.range()[0]-this.yScale.range()[1])
            	.attr('x', this.xScale.range()[0])
            	.attr('y', this.yScale.range()[1])
            	//.attr('fill', 'rgba(0,0,0,.08)');
            	.attr('fill', 'url(#hatch01)');
            	
        }
	}
	
    
    scatterplot.prototype.draw = function(data) {
    	clearInformation();  //utils.js  
    	
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
        for (var i in keys) {
            var k = keys[i];
            var x = this.xdata[k];
            var y = this.ydata[k];
            xy.push({ x: x < 0.0105 ? 0.01 : x, y: y < 0.0105 ? 0.01 : y , k: k});
            v1.push(x);
            v2.push(y);
            v1_log.push(Math.log(x + 1/1024));
            v2_log.push(Math.log(y + 1/1024));
            v1_anscombe.push(2 * Math.sqrt(x + 3/8));
            v2_anscombe.push(2 * Math.sqrt(y + 3/8));
        }

        var r = stats.pearson(v1, v2);
        var r_log = stats.pearson(v1_log, v2_log);
        var r_anscombe = stats.pearson(v1_anscombe, v2_anscombe);

        this.xScale = d3.scale
            .log()
	    .domain(d3.extent(xy, function(d) { return d.x; }))
	    .range([ this.options.padding[3], this.width - this.options.padding[1] ])
            .nice();

		this.yScale = d3.scale
            .log()
	    .domain(d3.extent(xy, function(d) { return d.y; }))
	    .range([ this.height - this.options.padding[2], this.options.padding[0] ])
            .nice();
            

        if (this.options.background) {
            svg .append('rect')
                .attr('width', this.width - this.options.padding[1] - this.options.padding[3] + this.options.inner * 2)
                .attr('height', this.height - this.options.padding[0] - this.options.padding[2] + this.options.inner * 2)
                .attr('x', this.options.padding[3] - this.options.inner)
                .attr('y', this.options.padding[0] - this.options.inner)
                .attr('fill', 'white')
                .attr('stroke', 'rgba(0,0,0,.2)')
                .attr('stroke-width', '1')
                .attr('shape-rendering', 'crispEdges');
           
        }
        if (this.options.makeGridLine) {
			this.makeGridLine();
        }
        
        svg .selectAll("circle")
            .data(xy)
            .enter()
            .append('circle')
            .attr('cx', function(d) { return self.xScale(d.x); })
            .attr('cy', function(d) { return self.yScale(d.y); })
            .attr('r',  this.options.pt_size)
           	.attr('opacity', 0.5)
           	.on('click', this.highlightCircle)
           	.append('title')
            .text(function(d) {return 'ID='+d.k+'  ('+d.x.toFixed(2)+', '+d.y.toFixed(2)+')';});
           
        var pt_size = this.options.pt_size;
        var font_size = pt_size + 8; 
     	svg .selectAll("text")
     		.data(xy)
     		.enter()	
     		.append("text")
           	.text(function(d) {return d.k;} )
           	.attr('x', function(d) { return self.xScale(d.x)+pt_size; })
           	.attr('y', function(d) { return self.yScale(d.y)+pt_size;})
           	.attr('style', 'font-size:'+ font_size+"px;")
           	.classed('circlelabel invisible', true);
        

        if (this.options.display_corr) {
            svg .append('text')
                .attr('x', this.options.padding[3])
                .attr('y', this.options.padding[0] + 12)
                .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 300')
                .text('r = ' + r.toFixed(2));

            svg .append('text')
                .attr('x', this.options.padding[3])
                .attr('y', this.options.padding[0] + 28)
                .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 300')
                .text('r(log) = ' + r_log.toFixed(2));

            svg .append('text')
                .attr('x', this.options.padding[3])
                .attr('y', this.options.padding[0] + 44)
                .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 300')
                .text('r(anscombe) = ' + r_anscombe.toFixed(2));
        }

        if (this.options.axes) {
            this.makeAxes();
        }
       
        
    };
})();
