ci.Views.CookieForm = Backbone.View.extend({

  id: 'cookie-form-view',

  initialize: function() {
    socket.on('navigate', this._onNavigate.bind(this));
  },

  events: {
    'click input[name="session"]' : '_onSessionClick',
    'click #cancel'       : '_onCancelClick',
    'submit #cookie-form' : '_onFormSubmit'
  },

  template: function() {
    return Hogan.compile($('#cookie-form-tmpl').text());
  },

  render: function() {
    var attributes = this.model.toJSON();
    var expirationDate = this.model.getExpirationDate();
    if (expirationDate) {
      attributes.day = expirationDate.getDate();
      attributes.month = expirationDate.getMonth() + 1;
      attributes.year = expirationDate.getFullYear();
      attributes.hours = expirationDate.getHours();
      attributes.minutes = expirationDate.getMinutes();
      attributes.seconds = expirationDate.getSeconds();
    }

    this.$el.html(this.template().render(attributes));
    return this;
  },

  _onSessionClick: function() {
    var session = this.$('input[name="session"]').prop('checked');
    $('.expires-input').prop('disabled', session);
  },

  _onCancelClick: function(event) {
    event.preventDefault();
    this.remove();
    return this;
  },

  _onNavigate: function() {
    this.remove();
  },

  _onFormSubmit: function(event) {
    event.preventDefault();
    var attrs = this._getFormValues();
    this.model.set(attrs);
    this.model.save({}, { wait: true });
    this.remove();
  },

  _getFormValues: function() {
    var attrs = {};
    attrs.name = this.$('input[name="name"]').val();
    attrs.value = this.$('textarea').val();
    attrs.domain = this.$('input[name="domain"]').val();
    attrs.path = this.$('input[name="path"]').val();

    var year = this.$('input[name="year"]').val();
    var month = parseInt(this.$('input[name="month"]').val()) - 1;
    var day = this.$('input[name="day"]').val();
    var hours = this.$('input[name="hours"]').val();
    var minutes = this.$('input[name="minutes"]').val();
    var seconds = this.$('input[name="seconds"]').val();
    var expires = new Date(year, month, day, hours, minutes, seconds);
    attrs.expirationDate = parseInt(expires.getTime() / 1000);

    attrs.session = this.$('input[name="session"]').prop('checked');
    attrs.hostOnly = this.$('input[name="hostOnly"]').prop('checked');
    attrs.httpOnly = this.$('input[name="httpOnly"]').prop('checked');
    attrs.secure = this.$('input[name="secure"]').prop('checked');
    return attrs;
  }

});

