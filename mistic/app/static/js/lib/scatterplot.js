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
            axis_labels: false,
            background: true,
            axes: true,
            display_corr: true,
            pt_size: 4,
            makeGridLine:false,
            gridValue: 10, 
            textOnly : false,
            minimal : true,
            
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

							 
	scatterplot.prototype.highlightCircle = function (e){
		
		d3.selectAll('#graph svg').selectAll('circle')
			.filter(function(d, i) {return (d.k==e.k);})
			.classed('highlighted', !d3.select(this).classed('highlighted'));
		addInformation(e.k);
		
	};
	
  scatterplot.prototype.brushstart= function () {
    d3.selectAll('.brush').selectAll('.extent').attr('width', '0').attr('height','0');
  };
  
  scatterplot.prototype.brushed= function () {
   
    var e = d3.event.target.extent();
    var circles  = d3.select(this.parentNode).selectAll("circle")
      .filter(function(d) { return e[0][0] <= d.x && d.x <= e[1][0] && e[0][1] <= d.y && d.y <= e[1][1] });
    var selected =  _.map(circles.data(), function(c) {return c.k;});
    d3.selectAll('#graph svg').selectAll("circle")
      .classed('highlighted', function(d) {return _.contains(selected, d.k);  });
      
  };

  scatterplot.prototype.brushend = function () {
  
    var circles = d3.select('#graph svg').selectAll("circle")
            .filter (function () {return this.className.baseVal=='highlighted'});
    var selected =  _.map(circles.data(), function(c) { return c.k;});
    selected = _.uniq(selected);
    clearInformation();
    _.each(selected, addInformation);
    
  };
	
    scatterplot.prototype.makeAxes = function() {
    
    	if (this.options.minimal)  {
    	  xmean = stats.average(_.values(this.xdata)); 
    	  ymean = stats.average(_.values(this.ydata)); 
        xrg = stats.range(_.values(this.xdata));
        yrg = stats.range(_.values(this.ydata));
      
       var xAxis = d3.svg
            .axis()
       .scale(this.xScale)
       .orient("bottom")
       .tickValues([xrg[0]+0.001, xmean, xrg[1]])
       .tickFormat(d3.format(",.1f"));
       
      
    
      var yAxis = d3.svg
            .axis()
      .scale(this.yScale)
      .orient("left")
      .tickValues([yrg[0]+0.01, ymean, yrg[1]])
      .tickFormat(d3.format(",.1f"));
        
        
        
        
    	}
    	else {
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
	   }

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
            .attr('opacity', .3)
            .attr('shape-rendering', 'crispEdges');
            

        svg .selectAll('.axis text')
            .attr('style', 'font-family: helvetica; font-size: 11px; font-weight: 100');

		if (this.options.makeGridLine) {
			svg.selectAll('.axis-x line')
				.filter(function(d, i) {return d <= self.options.gridValue})
				.attr('y1',-(self.height -self.options.padding[2] + self.options.outer)-self.yScale(d3.min([self.yScale.domain()[1],self.options.gridValue])));
				
			 svg.selectAll('.axis-y line')
			 	.filter(function(d, i) {return d <= self.options.gridValue})
			 	.attr('x2', self.xScale(self.xScale.domain()[1])-(self.options.padding[3] - self.options.outer));
		}
    
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
        var lg = true;
        
        for (var i in keys) {
            var k = keys[i];
            var x = this.xdata[k];
            var y = this.ydata[k];
            xy.push({ x: x >= 0.0 & x <0.0105 ? 0.01 : x, y: y >= 0.0 & y<0.0105 ? 0.01 : y , k: k});
            //xy.push({ x: x < 0.0105 ? 0.01 : x, y: y < 0.0105 ? 0.01 : y , k: k});
            if  (x < 0.0 ||  y < 0.0) { lg=false;}
            
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

       
        if (this.options.textOnly) {
           svg .append('rect')
                .attr('width', this.width - this.options.padding[1] - this.options.padding[3] + this.options.inner * 2)
                .attr('height', this.height - this.options.padding[0] - this.options.padding[2] + this.options.inner * 2)
                .attr('x', this.options.padding[3] - this.options.inner)
                .attr('y', this.options.padding[0] - this.options.inner)
                .attr('fill', 'white');
                
            svg .append('text')
                .attr('x', this.options.padding[3]+ 20)
                .attr('y', this.options.padding[0] + 28)
                .attr('text-anchor', 'left')
                .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 300')
                .text('r = ' + r.toFixed(2));

              svg .append('text')
                .attr('x', this.options.padding[3] + 20)
                .attr('y', this.options.padding[0] + 44)
                .attr('text-anchor', 'left')
                .attr('style', 'font-family: helvetica; font-size: 12px; font-weight: 300')
                .text('r(log) = ' + r_log.toFixed(2));
        
        }
        
        
        
        
        else {
          
          if (lg) {
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
          }
          else {
          
           this.xScale = d3.scale
            .linear()
            .domain(d3.extent(xy, function(d) { return d.x; }))
            .range([ this.options.padding[3], this.width - this.options.padding[1] ])
            .nice();

          this.yScale = d3.scale
            .linear()
            .domain(d3.extent(xy, function(d) { return d.y; }))
            .range([ this.height - this.options.padding[2], this.options.padding[0] ])
            .nice();         
          }
          
          this.brush = d3.svg.brush()
              .x(this.xScale)
              .y(this.yScale)
              .on("brushstart", this.brushstart)
              .on("brush", this.brushed)
              .on("brushend", this.brushend);
      
     
      
           var color='transparent';
           if (this.options.background) { color='white'; }
       
           svg .append('rect')
                .attr('width', this.width - this.options.padding[1] - this.options.padding[3] + this.options.inner * 2)
                .attr('height', this.height - this.options.padding[0] - this.options.padding[2] + this.options.inner * 2)
                .attr('x', this.options.padding[3] - this.options.inner)
                .attr('y', this.options.padding[0] - this.options.inner)
                .attr('fill', color)
                .attr('stroke', 'rgba(0,0,0,.2)')
                .attr('stroke-width', '1')
                .attr('shape-rendering', 'crispEdges');
                
                
                
          svg.append("g")
              .classed("brush", true)
              .call(this.brush);
             
           
          if (this.options.axes) {  this.makeAxes();  }
        
    
          node = svg .selectAll(".node")
              .data(xy)
              .enter().append("g")
              .attr("class", "node");
            
          node.append('circle')
            .attr('cx', function(d) { return self.xScale(d.x); })
            .attr('cy', function(d) { return self.yScale(d.y); })
            .attr('r',  this.options.pt_size)
           	//.attr('opacity', 0.65)
           	.on('click', this.highlightCircle);
     
          node.append('title')
            .text(function(d) {return 'ID='+d.k+'  ('+d.x.toFixed(2)+', '+d.y.toFixed(2)+')';});
           
          var pt_size = this.options.pt_size;
          var font_size = pt_size + 8; 
     
     	    node.append("text")
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

       }
    
        
    };
})();
