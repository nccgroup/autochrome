ci.Collections.Cookies = Backbone.Collection.extend({

  ctr: 0,

  initialize: function() {
    socket.on('cookies:read', this._onCookiesRead.bind(this));
    socket.on('cookies:create', this._onCookiesCreate.bind(this));
    socket.on('cookies:update', this._onCookiesUpdate.bind(this));
    socket.on('removeAllCookies', this._onRemoveAllCookies.bind(this));
    socket.on('navigate', this._onNavigate.bind(this));
  },

  url: 'cookies',

  model: ci.Models.Cookie,

  sortByAttrDesc: function(attr) {
    var attrA, attrB, val;
    this.comparator = function(a, b) {
      if (attr === 'size') {
        attrA = a.getSize();
        attrB = b.getSize();
      } else if (attr === 'expires') {
        attrA = a.getExpirationDate();
        attrB = b.getExpirationDate();
      } else {
        attrA = a.get(attr);
        attrB = b.get(attr);
      }

      if (attrA < attrB) {
        val = 1;
      } else if (attrA > attrB) {
        val = -1;
      } else {
        val = 0;
      }
      return val;
    }
    this.sort();
  },

  sortByAttrAsc: function(attr) {
    var attrA, attrB, val;
    this.comparator = function(a, b) {
      if (attr === 'size') {
        attrA = a.getSize();
        attrB = b.getSize();
      } else if (attr === 'expires') {
        attrA = a.getExpirationDate();
        attrB = b.getExpirationDate();
      } else {
        attrA = a.get(attr);
        attrB = b.get(attr);
      }

      if (attrA > attrB) {
        val = 1;
      } else if (attrA < attrB) {
        val = -1;
      } else {
        val = 0;
      }
      return val;
    }
    this.sort();
  },

  _onRemoveAllCookies: function(data) {
    this.reset(data.cookies);
  },

  _onCookiesRead: function(data) {
    var cookies = data.cookies;
    _.each(cookies, function(c) {
      this.ctr = this.ctr + 1;
      c.id = this.ctr;
    }.bind(this));
    this.reset(data.cookies);
  },

  _onCookiesUpdate: function(attrs) {
    var cookie = this.get(attrs.id);
    // We have to add this here because chrome
    // doesn't pass {expirationDate: null} included
    // with the attrs. This causes a bug in the model
    // to not detect that the expirationDate has changed
    // when changed the session to false in the cookie form.
    if (attrs.session) {
      cookie.unset('expirationDate');
    }
    cookie.set(attrs);
  },

  _onCookiesCreate: function(cookie) {
    this.ctr = this.ctr + 1;
    cookie.id = this.ctr;
    this.push(cookie);
  },

  _onNavigate: function() {
    this.reset([]);
  }

});
