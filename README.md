# autochrome

This tool downloads, installs, and configures a shiny new copy of Chromium.

It includes nifty things like:

* Turning off all those annoying auto-updaters!
* Sweet colored themes for high visibility!
* No XSS auditor!
* Automatic proxy configuration! (uses 127.0.0.1:8080)
* An annoying infobar because it doesn't check TLS certs!
* Basic integration with Burp if you install the included Burp extension

Currently, the following OSes are supported:

* macOS 10.9 (Mavericks) and higher
* Ubuntu 16.04 (and other XDG-supporting Linuxes)

You will need `ruby` version 2.0 or higher and `unzip`.  These are included in
supported macOS versions.  You may need to `apt install ruby` on Linux.

## Quickstart

1. `ruby autochrome.rb`
2. Launch Chromium.
   * MacOS: `open ~/Applications/Chromium.app`
   * Linux: `~/.local/autochrome/chrome`
3. Open the "Getting Started" bookmark.

## Installing

Execute the following command: `ruby autochrome.rb`

If you've already installed Chromium with this tool before, run `ruby autochrome.rb -c` to delete the old installation and install a new one.

If you just want to recreate the profiles without redownloading Chrome, run `ruby autochrome.rb -P`.

Use the `-h` flag to see all of the options.

The "versions" used with this tool are Chromium revisions. You can get a list of the last known good versions [here](http://chromium-status.appspot.com/revisions) (use the six-digit number after `refs/heads/master`), and you can find out what revision a given build of Chrome uses [here](http://omahaproxy.appspot.com/).

## Running

Once you've installed Chromium, it will be placed in the `~/Applications/` directory on OS X or the `~/.local/autochrome/` directory on Linux.

The command `open ~/Applications/Chromium.app` is one way to launch it on OS X. `~/.local/autochrome/chrome` is a way to launch it on Linux.

Once you've launched Chromium, open the "Getting Started" bookmark.

## Chrome extensions

Autochrome comes with several small utility extensions; you can add more in the
`data/extensions` directory.

The `build_extensions.rb` script will rebuild all extensions under `data/extension_source`, and the standard set of colored themes. This script uses the version of chromium installed by autochrome from the default directory. You **must** have completed the installation first.

### Settings Resetter

Makes it easy to wipe cookies or all browser history from the menu bar.

### Autochrome Integration

Adds a tag to the outgoing user agent to let Burp identify it. Menu bar icon does nothing.

## Copyright and License

Autochrome is copyright 2017, NCC Group, and licensed under the Apache license (see LICENSE.txt).
