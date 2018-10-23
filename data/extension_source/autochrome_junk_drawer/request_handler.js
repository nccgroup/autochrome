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
            chrome.bookmarks.remove(bm.id);
        } else {
            getProfileNameFromStorage();
        }
    });
}

getProfileNameFromBookmark();

document.addEventListener('DOMContentLoaded', function() {
    chrome.webRequest.onBeforeSendHeaders.addListener(
        function(details) {
            if (typeof profile == "string") {
                var headers = details.requestHeaders;

                for (var i = 0; i < headers.length; i++) {
                    if (headers[i].name == 'User-Agent') {
                        if (profile == "android") {
                            headers[i].value = "Mozilla/5.0 (Linux; Android 9; Pixel 2 XL Build/PPP3.180510.008; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/67.0.3396.87 Mobile Safari/537.36"
                        }
                        else if (profile == "ios") {
                            headers[i].value = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/604.1.21 (KHTML, like Gecko) Version/12.0 Mobile/17A6278a Safari/602.1.26"
                        }
                        headers[i].value += " autochrome/" + profile;
                    }
                }

                return {requestHeaders: headers};
            }
        },
        {urls: ["*://*/*"]},
        ['blocking', 'requestHeaders']);
});
