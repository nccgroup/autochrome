# Autochrome Burp Extension

This extension provides Autochrome integration for Burp Suite. It automatically populates the "comment" field in the proxy history based on the Autochrome profile in user.

It does so by looking for the string "autochrome/\[XXXX\]" in the User-Agent header. If this string is present, it takes the XXXX and sets it as the request comment in the proxy history.

# Installation

1. `mkdir /tmp/burp-api`
1. Run Burp.  Under Extender => APIs, click "Save interface files", and choose the `/tmp/burp-api` directory.
1. `cp /tmp/burp-api/burp/*.java src/burp`
1. `cd src`
1. `javac burp/BurpExtender.java`
1. `jar cf autochrome-useragenttag.jar burp/BurpExtender.class com/nccgroup/autochrome/useragenttag/*.class`
1. In Burp, go to Extender => Extensions.
1. Select "Add". Select the JAR file and finish the wizard.
