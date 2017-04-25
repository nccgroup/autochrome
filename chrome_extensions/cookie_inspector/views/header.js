function toCamelCase(str) {
  return str[0].toUpperCase() + str.slice(1);
}

ci.Views.Header = Backbone.View.extend({

  id: 'header',

  events: {
    'click th' : '_onHeaderClick'
  },

  initialize: function() {
    this.cookies = this.options.cookies;
  },

  template: function() {
    return Hogan.compile($('#header-tmpl').text());
  },

  render: function() {
    this.$el.html(this.template().render());
    return this;
  },

  _onHeaderClick: function(e) {
    e.preventDefault();
    var $target = $(e.currentTarget);

    if ($target.hasClass('corner')) { return; }

    var $ths = this.$('th');
    $ths.removeClass('desc');
    $ths.removeClass('asc');

    var column = $target.attr('data-col');
    var sort = $target.attr('data-sort-by');
    switch (sort) {
      case 'asc':
          sort = 'desc';
          break;
      case 'desc':
          sort = 'asc';
          break;
      default:
          sort = 'asc';
    }
    $target.addClass(sort);
    $target.attr('data-sort-by', sort);
    this.cookies['sortByAttr' + toCamelCase(sort)](column);
  }

});

