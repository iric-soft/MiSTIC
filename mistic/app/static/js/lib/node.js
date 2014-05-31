define(["underscore", "djset"], function(_, dj) {
    var PostorderTraversal = function(node) {
        this.stack = [[ node ]];
        this._pushChildren();
    };

    PostorderTraversal.prototype._pushChildren = function() {
        while(true) {
            var tail = _.last(_.last(this.stack));
            if (!tail.children.length) break;
            this.stack.push(tail.children.slice(0).reverse());
        }
    };

    PostorderTraversal.prototype.next = function() {
        if (!this.stack.length) return null;

        var back = _.last(this.stack);
        var result = back.pop();

        if (!back.length) {
            this.stack.pop();
        } else {
            this._pushChildren();
        }
        return result;
    };



    var PreorderTraversal = function(node) {
        this.stack = [[ node ]];
    };

    PreorderTraversal.prototype.next = function() {
        if (!this.stack.length) return null;

        var back = _.last(this.stack);
        var result = back.pop();

        while (this.stack.length && !_.last(this.stack).length) {
            this.stack.pop();
        }

        if (result.children.length) {
            this.stack.push(result.children.slice(0).reverse());
        }
        return result;
    };



    var Node = function(args) {
        _.extend(this, args);
        if (this.children === undefined) {
            this.children = [];
        }
    };

    Node.prototype.postorder = function(out) {
        for (var i = 0; i < this.children.length; ++i) {
            this.children[i].postorder(out);
        }
        out(this);
    };

    Node.prototype.preorder = function(out) {
        out(this);
        for (var i = 0; i < this.children.length; ++i) {
            this.children[i].preorder(out);
        }
    };

    Node.prototype.getContent = function() {
        var p = new PostorderTraversal(this);
        var n;
        var result = {};
        while ((n = p.next()) != null) {
            _.extend(result, n.content);
        }
        return result;
    };

    Node.prototype.collapseUnbranched = function() {
        var p, n;

        for (p = new PostorderTraversal(this); (n = p.next()) !== null; ) {
            if (n.children.length === 1) {
                var c = n.children[0];
                _.extend(c.content, n.content);
                n.content = c.content;
                n.children = c.children;
            }
        }
    };

    Node.prototype.collapse = function(min_size) {
        var n, p;
        for (p = new PostorderTraversal(this); (n = p.next()) !== null; ) {
            if (n.size >= min_size || n === this) {
                var children = [];
                var content = {};
                _.extend(content, n.content);
                _.each(n.children, function(c) {
                    if (c.hasOwnProperty('--node--')) {
                        children.push(c['--node--']);
                        delete c['--node--'];
                    } else {
                        _.extend(content, c.getContent());
                    }
                });

                n['--node--'] = new Node({
                    weight: n.weight,
                    size: n.size,
                    content: content,
                    children: children
                });
            }
        }
        var result = this['--node--'];
        delete this['--node--'];
        return result;
    };

    Node.fromMST = function(nodes, edges) {
        var current_nodes = {};

        var clusters = new dj.djset(nodes.length);

        for (var i = 0; i < nodes.length; ++i) {
            var content = {}
            if (nodes[i] !== null) {
              content[nodes[i]] = true;
            }
            current_nodes[i] = new Node({
                weight: 0.0,
                size: nodes[i] !== null ? 1 : 0,
                content: content
            });
        }

        for (var i = 0; i < edges.length; ++i) {
            var e = edges[i][0];
            var w = edges[i][1];
            var c1 = clusters.find_set_head(e[0]);
            var c2 = clusters.find_set_head(e[1]);

            var n1 = current_nodes[c1];
            var n2 = current_nodes[c2];

            delete current_nodes[c1];
            delete current_nodes[c2];

            if (n1.size < n2.size) {
                var n_tmp = n1;
                n1 = n2;
                n2 = n_tmp;
            }

            clusters.merge_sets(c1, c2);

            if (clusters.find_set_head(c1) !== clusters.find_set_head(c2)) { throw 'failed'; }

            var n = new Node({
                weight: w,
                size: n1.size + n2.size,
                children: [ n1, n2 ],
                content: {}
            });

            current_nodes[clusters.find_set_head(c1)] = n;
        }

        return _.values(current_nodes);
    };

    return {
        Node:               Node,
        PreorderTraversal:  PreorderTraversal,
        PostorderTraversal: PostorderTraversal
    };
});
