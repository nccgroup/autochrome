# autochrome

This tool downloads, installs, and configures a shiny new copy of Chromium.

It includes nifty things like:

* Turning off all those annoying auto-updaters!
* Sweet colored themes for high visibility!
* No XSS auditor!
* Automatic proxy configuration! (uses 127.0.0.1:8080)
* An annoying infobar because it doesn't check TLS certs!
* Basic integration with Burp if you install the included Burp extension
* An extension for super easy cookie editing!

Currently, the following OSes are supported:

* OS X 10.9 (Mavericks) and higher
* Ubuntu 16.04 (and other XDG-supporting Linuxes)

`ruby` version 2.0 or higher is needed and comes with 10.9 and up.
`sqlite` and `unzip` are needed for proper functioning. `apt-get install unzip sqlite3` will install the dependencies on Debianesque Linuxes.

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
`data/extensions` directory.  Source for the bundled extensions is under
`chrome_extensions`.  To rebuild them with [`crxmake`](https://github.com/Constellation/crxmake):

(Note: this generates a key for each extension, which autochome hashes to
generate the extension directory; don't try to reuse a key for more than one
extension.)

~~~bash
for dir in chrome_extensions/*; do
  name="${dir#chrome_extensions/}"
  crxmake "--pack-extension=$dir" "--extension-output=data/extensions/${name}.crx"
done
~~~

### Settings Resetter

Makes it easy to wipe cookies or all browser history from the menu bar.

### Cookie Monster

Provides a Cookies pane in the Inspector to view details about cookies. Menu bar icon does nothing useful.

### Autochrome Integration

Adds a tag to the outgoing user agent to let Burp identify it. Menu bar icon does nothing.
