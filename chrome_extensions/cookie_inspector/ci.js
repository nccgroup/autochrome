if (window.DEVELOPMENT) {
  function Port() {};
  Port.prototype = {
    onMessage: {
      addListener: function() {
      }
    },

    postMessage: function() {
    },

    addListener: function() {
    }
  };

  chrome = {};
  chrome.devtools = {};
  chrome.devtools.inspectedWindow = {
    tabId: 1,
    eval: function(str, cb) {
      cb(eval(str));
    }
  };

  chrome.extension = {
    sendMessage: function(msg, sendResponse) {
      sendResponse();
    }
  };

  chrome.runtime = { 
    connect: function() {
      return new Port();
    }
  };
}

Backbone.sync = function(method, model, options) {
  var params = {};

  params.command = model.url + ':' + method;

  if (options.data == null && model && (method === 'delete' || method === 'create' || method === 'patch')) {
    params.data = options.attrs || model.toJSON(options);
  }

  if (options.data == null && method === 'update') {
    params.data = options.attrs || {};
    params.data.previousAttributes = model.previousAttributes();
    params.data.changedAttributes = model.changedAttributes();
  }

  socket.postMessage(params);
};

var ci = {

  /**
   * Pointer used by the ContextMenu to keep track
   * if the editor is open or not.
   */
  editor: null,

  resizers: {},

  Models: {},

  Collections: {},

  Views: {},

  run: function() {
    this._listenToWindowResize();
    this._listenToResizerDrag();

    this.cookies = new ci.Collections.Cookies();

    var headerView = new ci.Views.Header({cookies: this.cookies});
    $(document.body).append(headerView.render().el);

    var contentView = new ci.Views.Content({cookies: this.cookies});
    $(document.body).append(contentView.render().el);

    var footerView = new ci.Views.Footer({cookies: this.cookies});
    $(document.body).append(footerView.render().el);

    // Add the resizers
    var $resizers = $('#header table th');
    for (var i = 1; i < $resizers.length; i += 1) {
      // If its the last col
      if ((i + 1) === $resizers.length) {
        continue;
      }

      var view = new ci.Views.Resizer({$column: $resizers.eq(i)});
      view.$el.attr('data-index', i - 1);
      this.resizers[i] = view;
      $(document.body).append(view.render().el);
    }

    this.cookies.fetch();
  },

  _listenToResizerDrag: function() {
    document.body.addEventListener('drag', this._onResizerDrag.bind(this), false);
  },

  _listenToWindowResize: function() {
    // window resize is said to be inefficient but in
    // this use case its alright ;)
    window.onresize = this._onWindowResize.bind(this);
  },

  _onWindowResize: function(val) {
    this.trigger('resize');
  },

  _onResizerDrag: function(e) {
    if (e.x === 0 && e.y === 0) { return; }

    var index = parseInt($(e.target).attr('data-index'));
    var thWidth = $('#header table th').eq(index)[0].offsetLeft + $('#header table th').eq(index)[0].offsetWidth;
    var difference = thWidth - e.x;
    var percentage = (difference / $('#header table').width()) * 100;

    // Resize the column
    var $headerCols = $('#header table col');
    var $contentCols = $('#content table col');

    var prevColWidth = $headerCols.eq(index).width() - percentage;
    var nextColWidth = $headerCols.eq(index + 1).width() + percentage;

    if (prevColWidth > 3 && nextColWidth > 3) {
      $headerCols.eq(index).css('width', prevColWidth + '%');
      $contentCols.eq(index).css('width', prevColWidth + '%');

      $headerCols.eq(index + 1).css('width', nextColWidth + '%');
      $contentCols.eq(index + 1).css('width', nextColWidth + '%');

      this.trigger('resize');
    }
  }
};

// Make sure we get Backbone events on our
// literal object.
_.extend(ci, Backbone.Events);

// Main entry point
$(document).ready(function() {
  ci.run();
});
