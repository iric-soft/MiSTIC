
(function() {

    var _interp = function(ramp, w, j) {
        w = w * (ramp.length - 1);
        var i = Math.floor(w);
        w = w - Math.floor(w);
        if (w < 0.01)
            return ramp[i].toString();
       if (i==j) {
            console.debug('split palette');
            return d3.hsl(ramp[i].toString()).brighter(0.5).toString(); 
         }   
         
        return d3.interpolateHsl(ramp[i], ramp[i+1])(w);
    };
    
   var _ylgnbl =_.map(
        [
            "#FFFFD9",
            "#EDF8B1",
            "#C7E9B4",
            "#7FCDBB",
            "#41B6C4",
            "#1D91C0",
            "#225EA8",
            "#253494",
            "#081D58",
           
        ],
        function(c) { return d3.rgb(c); });

    var _red =_.map(
        [
            "#cccccc",
            "#600000"
        ],
        function(c) { return d3.rgb(c); });

 
    var _pal= _.map( 
    [ "#a35918", 
      "#9ecae1","#6baed6","#4292c6","#2171b5","#08519c","#08306b"  ]
        ,
        function(c) { return d3.rgb(c); });
    
    

    YlGnBl = function(w) { return _interp(_ylgnbl, w, -1); };
    Pal = function(w) { return _interp(_pal, w, 0); };
    Red4 = function(w) { return _interp(_red, Math.pow(w, 1/4.0),-1); };
})();
