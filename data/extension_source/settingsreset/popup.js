function nuke(all) {
    var dataToRemove = {
        "appcache": true,
        //"cacheStorage": true,
        "cookies": true,
        "downloads": false,
        "fileSystems": true,
        "formData": true,
        "indexedDB": true,
        "localStorage": true,
        "passwords": true,
        "serverBoundCertificates": true,
        "serviceWorkers": true,
        "webSQL": true
    }

    if (all) {
        Object.assign(dataToRemove, {
            "cache": true,
            "history": true,
            "pluginData": true
        });
    }

    chrome.browserAction.setBadgeText({"text": "wait"});
    chrome.browsingData.remove({}, dataToRemove, function() {
        chrome.browserAction.setBadgeText({"text": ""});
    })
}

document.addEventListener('DOMContentLoaded', function() {
    document.getElementById("clear-cookies").onclick = function() {
        nuke(false);
    };
    document.getElementById("reset-all").onclick = function() {
        nuke(true);
    };
});
