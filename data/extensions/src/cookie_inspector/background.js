(function() {

  var Background = {

    listeners: {},

    init: function() {
      this._listenForConnections();
      this._listenForNavigate();
      this._listenForDOMContentLoaded();
    },

    _listenForDOMContentLoaded: function() {
      chrome.webNavigation.onDOMContentLoaded.addListener(this._onDOMContentLoaded.bind(this));
    },

    _onDOMContentLoaded: function(details) {
      if (details.frameId !== 0) { return; }

      var tabId = details.tabId;
      var port = this.listeners[tabId];
      if (port) {
        chrome.tabs.get(tabId, function(tab) {
          chrome.cookies.getAll({ url: tab.url }, function(cookies) {
            port.postMessage({ command: 'cookies:read', data: { cookies: cookies } });
          });
        });
      }
    },

    _listenForConnections: function() {
      chrome.runtime.onConnect.addListener(this._onConnect.bind(this));
    },

    _onConnect: function(port) {
      port.onMessage.addListener(function() {
        // this function wrapper makes sure we pass the port
        // object along the arguments.
        var newArgs = Array.prototype.slice.call(arguments);
        newArgs.push(port);
        this._onPortMessageReceived.apply(this, newArgs);
      }.bind(this));
    },

    _onPortMessageReceived: function(msg, port) {
      console.log('MSG: ', msg);

      var tabId   = msg.tabId;
      var command = msg.command;

      if (command === 'saveListener') {
        this.listeners[tabId] = port;

        port.onDisconnect.addListener(function() {
          delete this.listeners[tabId];
        }.bind(this));
      }

      if (command === 'removeAllCookies') {
        chrome.tabs.get(tabId, function(tab) {
          chrome.cookies.getAll({ url: tab.url }, function(cookies) {
            for (var i = 0; i < cookies.length; i += 1) {
              chrome.cookies.remove({ url: tab.url, name: cookies[i].name });
            }
            port.postMessage({ command: command, data: { cookies: [] } });
          });
        });
      }

      if (command === 'cookies:read') {
        chrome.tabs.get(tabId, function(tab) {
          chrome.cookies.getAll({ url: tab.url }, function(cookies) {
            port.postMessage({ command: command, data: { cookies: cookies } });
          });
        });
      }

      if (command === 'cookies:create') {
        var data = msg.data;

        chrome.tabs.get(tabId, function(tab) {
          var details = {
            url: tab.url,
            name: data.name,
            value: data.value,
            path: data.path,
            secure: data.secure,
            httpOnly: data.httpOnly,
          };

          if (!data.hostOnly) { details.domain = data.domain; }
          if (!data.session) { details.expirationDate = data.expirationDate; }

          chrome.cookies.set(details, function(cookie) {
            port.postMessage({ command: command, data: cookie })
          });
        });
      }

      if (command === 'cookies:delete') {
        var data = msg.data;

        chrome.tabs.get(tabId, function(tab) {
          var details = {
            url: tab.url,
            name: data.name
          };

          chrome.cookies.remove(details, function(cookie) {
            port.postMessage({ command: command, data: cookie })
          });
        });
      }

      if (command === 'cookies:update') {
        var changedAttributes = msg.data.changedAttributes;
        var previousAttributes = msg.data.previousAttributes;

        if (changedAttributes) {
          chrome.tabs.get(tabId, function(tab) {
            chrome.cookies.remove({ url: tab.url, name: previousAttributes.name }, function(cookie) {
              var details = {
                url: tab.url,
                name: changedAttributes.name || previousAttributes.name,
                value: changedAttributes.value || previousAttributes.value,
                path: changedAttributes.path || previousAttributes.path
              };

              // `secure` attribute
              if (changedAttributes.secure === void(0)) {
                details.secure = previousAttributes.secure;
              } else {
                details.secure = changedAttributes.secure;
              }

              // `httpOnly` attribute
              if (changedAttributes.httpOnly === void(0)) {
                details.httpOnly = previousAttributes.httpOnly;
              } else {
                details.httpOnly = changedAttributes.httpOnly;
              }

              // If it's undefined, it means that the `hostOnly` value
              // did not get changed, therefore, get the previous value.
              if (changedAttributes.hostOnly === void(0)) {
                if (previousAttributes.hostOnly === false) {
                  details.domain = changedAttributes.domain || previousAttributes.domain;
                }
              } else {
                if (changedAttributes.hostOnly === false) {
                  details.domain = changedAttributes.domain || previousAttributes.domain;
                }
              }

              // `expirationDate` attribute
              var isSessionChanged = (changedAttributes.session !== void(0));
              if (isSessionChanged) {
                if (changedAttributes.session) {
                  details.expirationDate = null;
                } else {
                  details.expirationDate = changedAttributes.expirationDate;
                }
              } else {
                details.expirationDate = changedAttributes.expirationDate ||
                                         previousAttributes.expirationDate;
              }

              chrome.cookies.set(details, function(cookie) {
                cookie.id = previousAttributes.id;
                port.postMessage({ command: command, data: cookie })
              });
            });
          });
        }
      }
    },

    _listenForNavigate: function() {
      chrome.webNavigation.onBeforeNavigate.addListener(this._onNavigate.bind(this));
    },

    _onNavigate: function(details) {
      if (details.frameId !== 0) { return; }

      var tabId = details.tabId;
      var port = this.listeners[tabId];
      if (port) {
        port.postMessage({ command: 'navigate' });
      }
    }

  };

  Background.init();

})();
