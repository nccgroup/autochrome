ci.Views.Footer = Backbone.View.extend({

  id: 'footer',

  initialize: function() {
    this.cookies = this.options.cookies;
    this.listenTo(this.cookies, 'reset', this._onCookiesChange.bind(this));
    this.listenTo(this.cookies, 'add',   this._onCookiesChange.bind(this));
    this.listenTo(this.cookies, 'remove', this._onCookiesChange.bind(this));
  },

  template: function() {
    return Hogan.compile($('#footer-tmpl').text());
  },

  render: function() {
    this.$el.html(this.template().render());
    return this;
  },

  _onCookiesChange: function() {
    this.$('#cookies-count').html(this.cookies.length);
  }

});

