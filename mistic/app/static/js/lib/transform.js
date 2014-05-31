define([], function() {
    "use strict"; // jshint ;_;

    var m3 = function() {
        this.m = [
            [1.0, 0.0, 0.0],
            [0.0, 1.0, 0.0],
            [0.0, 0.0, 1.0]
        ];
    };

    m3.scale = function(sx, sy) {
        var m = new m3();
        m.m[0][0] = sx;
        m.m[1][1] = sy;
        return m;
    };

    m3.trans = function(dx, dy) {
        var m = new m3();
        m.m[0][2] = dx;
        m.m[1][2] = dy;
        return m;
    };

    m3.rot = function(rad) {
        var m = new m3();
        m.m[0][0] = +Math.cos(rad);
        m.m[0][1] = -Math.sin(rad);
        m.m[1][0] = +Math.sin(rad);
        m.m[1][1] = +Math.cos(rad);
        return m;
    };

    m3.mul = function(a, b) {
        a = a.m;
        b = b.m;
        var r = new m3();
        for (var i = 0; i < 3; ++i) {
            for (var j = 0; j < 3; ++j) {
                r.m[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j] + a[i][2] * b[2][j];
            }
        }
        return r;
    };

    m3.prototype.xform = function(p) {
        var x = p.x * this.m[0][0] + p.y * this.m[0][1] + this.m[0][2];
        var y = p.y * this.m[1][0] + p.y * this.m[1][1] + this.m[1][2];
        var z = p.x * this.m[2][0] + p.y * this.m[2][1] + this.m[2][2];

        return { x: x/z, y: y/z };
    };

    m3.prototype.scale = function(sx, sy) {
        var t = m3.mul(this, m3.scale(sx, sy));
        this.m = t.m;
        return this;
    };

    m3.prototype.trans = function(dx, dy) {
        var t = m3.mul(this, m3.trans(dx, dy));
        this.m = t.m;
        return this;
    };

    m3.prototype.rot = function(rad) {
        var t = m3.mul(this, m3.rot(rad));
        this.m = t.m;
        return this;
    };

    m3.prototype.concat = function(m) {
        var t = m3.mul(this, m);
        this.m = t.m;
        return this;
    };

    m3.prototype.set = function(m) {
        for (var i = 0; i < 3; ++i) {
            for (var j = 0; j < 3; ++j) {
                this.m[i][j] = m.m[i][j];
            }
        }
        return this;
    };

    m3.prototype.copy = function() {
        return new m3().set(this);
    };

    return {
        m3: m3
    };
});
