let autochrome_profile_name = null;

/*
permissions: ['declarativeNetRequestFeedback'],
chrome.declarativeNetRequest.onRuleMatchedDebug.addListener(
    (info) => {
        const req = info.request;
        const rule = info.rule;
        console.log(`[${rule.rulesetId}:${rule.ruleId}] ${req.method} ${req.url}`);
    }
);
*/


const profiles = [
    'blue',
    'cyan',
    'green',
    'orange',
    'purple',
    'red',
    'white',
    'yellow'
];

async function getProfileNameFromStorage() {
    if (autochrome_profile_name != null) {
        return;
    }

    await chrome.storage.local.get("profile_name", (items) => {
        const name = items["profile_name"];
        // console.log(`[STORAGE] Got profile name: "${name}"`);
        if (typeof name == "string") {
            autochrome_profile_name = name;
        }
    });

    if (autochrome_profile_name == null) {
        await getProfileNameFromManagement();
    }
}

async function getProfileNameFromManagement() {
    await chrome.management.getAll((extensionInfoArray) => {
        extensionInfoArray.forEach((extensionInfo) => {
            if (extensionInfo.type === "theme" && extensionInfo.enabled) {
                const color = extensionInfo.name.replace(/^Caution\s+(\w+)$/, '$1').toLowerCase();
                if (profiles.find((c) => color === c) != undefined) {
                    autochrome_profile_name = color;
                }
            }});
        }
    );
    // console.log(`[MANAGEMENT] Got profile name: "${autochrome_profile_name}"`);
    if (autochrome_profile_name != null) {
        await chrome.storage.local.set({profile_name: autochrome_profile_name});
    }
}

getProfileNameFromStorage();
setTimeout(() => {
    if (autochrome_profile_name != null) {
        console.log(`Got profile name: ${autochrome_profile_name}`);
        chrome.declarativeNetRequest.updateEnabledRulesets({
            enableRulesetIds: [`ruleset_tag_${autochrome_profile_name}`]
        });
    } else {
        console.log(`Cannot get profile name: ${autochrome_profile_name}`);
    }
}, 100);
