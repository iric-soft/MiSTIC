(function() {
    Gene = Backbone.Model.extend();

    Genes = Backbone.Collection.extend({ model: Gene });

    var loaded_annotations = {};

    Dataset = Backbone.Model.extend({
        initGenesFromData: function(data) {
            var genes = new Genes();
            for (var i in data) {
                var gene_id = data[i];
                var gene = this.annotation.get(gene_id);
                if (gene !== undefined) {
                    genes.add(gene.clone(), {silent: true});
                } else {
                    genes.add({ id: gene, desc: '', go: [] }, {silent: true});
                }
            }
            this.genes = genes;
        },

        loadGenes: function() {
            var self = this;

            if (this.data !== undefined) {
                this.initGenesFromData(this.data);
            } else {
                this.data = {};
                $.ajax({
                    url: mistic.url + '/datasets/' + this.id + '/genes',
                    dataype: 'json',
                    success: function(data) {
                        self.data = data;
                        self.initGenesFromData(data);
                    }
                });
            }
        },

        initialize: function() {
            var annot_id = this.get('annotation');
            var annot = loaded_annotations[annot_id];
            this.genes = new Genes();

            if (annot === undefined) {
                this.annotation = annot = loaded_annotations[annot_id] = new Genes();
                annot.url = mistic.url + '/annotations/' + annot_id + '/genes';
                annot.fetch();
            } else {
                this.annotation = annot;
                this.loadGenes();
            }

            annot.on('all', this.loadGenes, this);
        }
    });

    Datasets = Backbone.Collection.extend({ model: Dataset });

    datasets = new Datasets();
    datasets.url = mistic.url + '/datasets';

    DatasetDummyOption = Backbone.View.extend({
        render: function() {
            this.el = '<option value="">Select a dataset</option>';
            return this;
        }
    });

    DatasetOption = Backbone.View.extend({
        render: function() {
            this.el = '<option value="' + this.model.id + '">' + this.model.escape('desc') + '</option>';
            return this;
        }
    });

    DatasetSelector = Backbone.View.extend({
        events: {
            'change': 'selectDataset',
        },

        selectDataset: function(event) {
            this.trigger('select:dataset', datasets.get(this.el.value));
        },

        render: function() {
            var self = this;
            var curr = this.el.value;
            $('option', self.el).remove();
            $(self.el).append(new DatasetDummyOption().render().el);
            datasets.each(function(dataset) {
                $(self.el).append(new DatasetOption({ model: dataset }).render().el);
            });
        },

        initialize: function() {
            datasets.bind('add remove reset', this.render, this)
        }
    });



    GeneItem = Backbone.View.extend({
        tagName: 'li',
        className: 'menu-item',

        render: function() {
            this.$el.data({ model: this.model });

            this.$el.html('<b>' + this.model.escape('symbol') + '</b> - ' + this.model.escape('desc'));

            return this;
        }
    });

    GeneEntry = Backbone.View.extend({
        events: {
            'blur':      'blur',
            'focus':     'focus',
            'keydown':   'keydown',
            'keypress':  'keypress',
            'keyup':     'keyup',
        },

        select: function(model) {
            if (model !== undefined) {
                this.$el.val(model.id);
                this.$el.addClass('valid');
            } else {
                this.$el.removeClass('valid');
            }
            if (model !== this.last_selection) {
                this.trigger('select:gene', model);
                this.last_selection = model;
            }
        },

        blur: function(event) {
            this.menu.hide();
        },

        focus: function(event) {
        },

        input: function(event) {
        },

        keydown: function(event) {
        },

        keypress: function(event) {
        },

        keyup: function(event) {
            this.update();
            this.valueChanged();
        },

        valueChanged: function() {
            if (this.genes !== undefined) {
                this.select(this.genes.get(this.$el.val()));
            }
        },

        reposition: function() {
            var margin_left   = parseInt(this.$el.css("marginLeft")) || 0;
	    var margin_top    = parseInt(this.$el.css("marginTop"))  || 0;
            var width         = this.$el.outerWidth();
	    var height        = this.$el.outerHeight();
            var pos           = this.$el.offset();
            var menu_width    = this.menu.outerWidth();
            var menu_height   = this.menu.outerHeight();
            if (menu_width < width) {
                var pl = parseFloat(this.menu.css('paddingLeft')) || 0;
                var pr = parseFloat(this.menu.css('paddingRight')) || 0;
                var bl = parseFloat(this.menu.css('borderLeftWidth')) || 0;
                var br = parseFloat(this.menu.css('borderRightWidth')) || 0;

                this.menu.width(width - pl -pr -bl - br);
            }
            this.menu.css({ left: pos.left, top: pos.top + height });
        },

        renderMatches: function(matches) {
            var self = this;
            var ul = this.menu;
            ul.empty();

            if (matches.length == 0) {
                ul.hide();
            } else {
                _.each(matches, function(match) {
                    var item = new GeneItem({ model: match });
                    item.on('select', function(gene) { self.selectItem(gene); });
                    ul.append(item.render().el);
                });

                var width = Math.max(ul.width("").outerWidth(), this.$el.outerWidth());
                var pos = this.$el.offset();

                this.reposition();
                ul.show();
            }
        },

        update: function() {
            var v = this.$el.val();
            var v_regex_a = new RegExp('^' + v, 'i');
            var v_regex_b = new RegExp(v, 'i');
            if (this.genes !== undefined && v.length != 0) {
                var matches = this.genes.filter(function(gene) {
                    return v_regex_a.test(gene.get('symbol')) || v_regex_b.test(gene.get('desc'));
                });
                if (matches.length < 100) {
                    this.renderMatches(matches);
                } else {
                    this.menu.empty().hide();
                }
            } else {
                this.menu.empty().hide();
            }
        },

        changeGeneList: function(genes) {
            if (this.genes !== undefined) {
                this.genes.off(null, null, this);
            }
            this.genes = genes;
            if (this.genes !== undefined) {
                this.genes.on("add remove reset", this.update, this);
            }
            this.$el.val('');
        },

        click: function(event) {
            event.preventDefault();
            var item = $(event.target).closest('.menu-item');
            if (item.length) {
                var model = $(item[0]).data('model');
                this.select(model);
                this.menu.hide();
            }
        },

        initialize: function() {
            var self = this;

            this.genes = undefined;
            this.last_selection = undefined;

            this.menu = $('<ul></ul>')
                .addClass('menu')
                .hide()
                .appendTo($('body')[0])
                .mousedown(function(event) { self.click(event); });
        }
    });
})();
