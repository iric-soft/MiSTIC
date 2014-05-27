(function() {
    ModalBase = Backbone.View.extend({
        tagName: 'div',
        className: 'modal hide',
        template: _.template('\
<div class="modal-dialog">\
  <div class="modal-content">\
    <div class="modal-header">\
      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>\
      <h4 class="modal-title" style="padding-right: 3em; white-space: nowrap;"><%- self.title %></h4>\
    </div>\
    <div class="modal-body"><%= self.getBody() %></div>\
    <div class="modal-footer">\
      <%= self.footer(this) %>\
      <button class="btn btn-default" data-dismiss="modal">Cancel</button>\
    </div>\
  </div>\
</div>'),
        err: _.template(''),

        events: {
            'hidden':            'remove',
        },

        footer: function() {
        },

        remove: function() {
            this.$el.remove();
        },

        render: function() {
            this.$el.html(this.template({ self: this }));
            this.$('.modal-body').css('max-height', '200px');
            this.$('.modal-body').css('overflow-y', 'scroll');
            return this;
        },

        dismiss: function() {
            this.$el.modal('hide');
        },

        show: function(pos_elem) {
            var self = this;
            this.$el.appendTo($('body')).modal({ backdrop: false });

            if (pos_elem !== undefined) {
                var pos = _.extend(
                    {},
                    $(pos_elem).offset(),
                    { height: $(pos_elem)[0].offsetHeight }
                );

                this.$el.css({
                    width: 'auto',
                    top: pos.top + pos.height + 5,
                    left: pos.left,
                    margin: 0
                })
            } else {
                this.$el.css({
                    width: 'auto',
                    'margin-left': function () { return -self.$el.width() / 2; }
                });
            }
        },

        initialize: function() {
            this.render();
        }
    });
})();
