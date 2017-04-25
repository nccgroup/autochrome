ci.Views.Resizer = Backbone.View.extend({

  className: 'resizer',

  initialize: function() {
    this.$column = this.options.$column;
    this.listenTo(ci, 'resize', this._onResize.bind(this));
  },

  render: function() {
    this._setLeftBasedOnColumn();
    this._setDraggable();
    return this;
  },

  moveTo: function() {
    
  },

  _onResize: function() {
    this._setLeftBasedOnColumn();
  },

  _setDraggable: function() {
    this.$el.attr('draggable', 'true');
  },

  _setLeftBasedOnColumn: function() {
    this.$el.css('left', this.$column.offset().left - 3);
  }

});

