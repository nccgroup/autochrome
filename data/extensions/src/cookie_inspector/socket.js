window.socket = {
  tabId: chrome.devtools.inspectedWindow.tabId,

  port: chrome.runtime.connect(),

  init: function() {
    this.port.onMessage.addListener(this._onPortMessage.bind(this));
  },

  _onPortMessage: function(msg) {
    this.trigger(msg.command, msg.data);
  },

  /**
   * Sends a message to the backend, doesn't need a callback.
   */
  postMessage: function(obj) {
    obj = obj || {};
    obj.tabId = this.tabId;
    this.port.postMessage(obj);
  }
};
_.extend(socket, Backbone.Events);
socket.init();
socket.postMessage({ command: 'saveListener' });
