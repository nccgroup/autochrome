ci.Views.Cookie = Backbone.View.extend({

  className: 'cookie-row',

  tagName: 'tr',

  events: {
    'contextmenu' : '_onContextMenu'
  },

  initialize: function() {
    this.listenTo(this.model, 'destroy', this.remove);
    this.listenTo(this.model, 'change', this.render);
  },

  template: function() {
    return Hogan.compile($('#cookie-tmpl').text());
  },

  render: function() {
    var attributes = this.model.toJSON()
    attributes.size = this.model.getSize();
    attributes.expires = this.model.getExpirationDate();
    this.$el.html(this.template().render(attributes));
    return this;
  },

  _onContextMenu: function(event) {
    var view = new ci.Views.ContextMenu({
      model: this.model,
      x: event.clientX,
      y: event.clientY
    });
    $(document.body).append(view.render().el);
    view.$el.focus();
    event.stopPropagation();
    event.preventDefault();
  }

});

