ci.Models.Cookie = Backbone.Model.extend({

  url: 'cookies',

  getSize: function() {
    return this.get('name').length + this.get('value').length;
  },

  getExpirationDate: function() {
    var expirationDate = this.get('expirationDate');
    if (expirationDate) {
      return new Date(expirationDate * 1000);
    } else {
      return null;
    }
  }

});
