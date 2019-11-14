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

var requestFilter = {
        urls: [ "<all_urls>" ]
    },
    // The 'extraInfoSpec' parameter modifies how Chrome calls your
    // listener function. 'requestHeaders' ensures that the 'details'
    // object has a key called 'requestHeaders' containing the headers,
    // and 'blocking' ensures that the object your function returns is
    // used to overwrite the headers
    extraInfoSpec = ['requestHeaders','blocking','extraHeaders'],
    // Chrome will call your listener function in response to every
    // HTTP request
    handler = function( details ) {
        if (typeof profile != "string") {
            return;
        }

        var headers = details.requestHeaders,
            blockingResponse = {};

        // Each header parameter is stored in an array. Since Chrome
        // makes no guarantee about the contents/order of this array,
        // you'll have to iterate through it to find for the
        // 'User-Agent' element
        for( var i = 0, l = headers.length; i < l; ++i ) {
            if( headers[i].name == 'User-Agent' ) {
                headers[i].value += " autochrome/" + profile;
                break;
            }
            // If you want to modify other headers, this is the place to
            // do it. Either remove the 'break;' statement and add in more
            // conditionals or use a 'switch' statement on 'headers[i].name'
        }

        blockingResponse.requestHeaders = headers;
        return blockingResponse;
    };

chrome.webRequest.onBeforeSendHeaders.addListener( handler, requestFilter, extraInfoSpec );