function getProfileNameFromStorage() {
    chrome.storage.local.get("profile_name", function(items) {
        var name = items["profile_name"];
        console.log("Got profile name: \"" + name + "\"");
        if (typeof name == "string") {
            profile = name;
        }
    });
}

function getProfileNameFromBookmark() {
    chrome.bookmarks.search("Autochrome Profile Name", function(nodes) {
        if (nodes.length > 0) {
            var bm = nodes[0];
            var name = new URL(bm.url).host;

            profile = name;

            console.log("Saving profile name \"" + name + "\" to storage");
            chrome.storage.local.set({profile_name: name});
            //chrome.bookmarks.remove(bm.id);
        } else {
            getProfileNameFromStorage();
        }
    });
}



document.addEventListener('DOMContentLoaded', function() {
    getProfileNameFromBookmark();
    chrome.webRequest.onBeforeSendHeaders.addListener(
        function(details) {
            if (typeof profile == "string") {
                var headers = details.requestHeaders;

                for (var i = 0; i < headers.length; i++) {
                    if (headers[i].name == 'User-Agent') {
                        headers[i].value += " autochrome/" + profile;
                    }
                }

                return {requestHeaders: headers};
            }
        },
        {urls: ["*://*/*"]},
        ['blocking', 'requestHeaders']);
});
