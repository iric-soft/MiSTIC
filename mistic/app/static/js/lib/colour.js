
(function() {

    var _interp = function(ramp, w) {
        w = w * (ramp.length - 1);
        var i = Math.floor(w);
        w = w - Math.floor(w);
        if (w < 0.001)
            return ramp[i].toString();
        return d3.interpolateHsl(ramp[i], ramp[i+1])(w);
    };

    var _ylgnbl =_.map(
        [
           // "#FFFFD9",
           // "#EDF8B1",
           // "#C7E9B4",
            "#7FCDBB",
            "#41B6C4",
            "#1D91C0",
            "#225EA8",
            "#253494",
            "#081D58",
            "#08306b" // last of the blues
        ],
        function(c) { return d3.rgb(c); });

    var _red =_.map(
        [
            "#cccccc",
            "#600000"
        ],
        function(c) { return d3.rgb(c); });

 

    YlGnBl = function(w) { return _interp(_ylgnbl, w); };
   
    Red4 = function(w) { return _interp(_red, Math.pow(w, 1/4.0)); };
})();
