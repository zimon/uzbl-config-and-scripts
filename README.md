UZBL Configuration File and Scripts
===================================

Here are my uzbl scripts and the configuration file.

Most of the scripts are modified versions of existing scripts. Some scripts are unmodified and only here to have everything at one place.

As I use no tabbing or tiling wm I prefer using tabbed browsing with uzbl-tabbed. So, some of the scripts are written/configured to work with uzbl-tabbed but it should be very easy to use them for multiple windows (e.g. change NEW_TAB to NEW_WINDOW or something like that).

I do not describe the keybindings here in the readme. Look at the config file or the appropriate plugins for more informations.

Some plugins have to clean up some things after the last instance of uzbl-core was closed (for example remove temporarily allowed sites from cookie_whitelist). As the INSTANCE_EXIT event does not work for me, I created the script uzbl, that starts the uzbl-tabbed and when it exits calls the cleanup routines from the scripts. Just configure the uzbl executable (uzbl-tabbed or uzbl-browser) in the script and place it in a directory of your path. Then you can start uzbl-tabbed (uzbl-browser) by just calling uzbl.

If you find errors or have problems with the script please create an issue. The scripts only little tested but should work.


Here are some short descriptions of the plugins (look at the comments at the beginning of each script for more informations):

adblock.py
----------

Unmodified adblock script from http://www.uzbl.org/wiki/adblock


cookies.pl
----------

Script for (temporarily) whitelisting domains whose cookies should be accepted.


download.pl
-----------

Downloads files to specified dir with wget and notifies about finished downloads.


eFormFiller.pl
--------------

Modified version of Pawel Tomaks script. See http://github.com/grodzik/uzbl-scripts/


exit.sh and undo.sh
-------------------

Modified undo scripts that only save undo informations if history is enabled (see history.pl)


go_next_page.js and go_prev_page.js
-----------------------------------

These are the scripts from http://www.uzbl.org/wiki/go-next_prev with modified regular expressions to find previous/next links


go_up.js
--------

Unmodified version of http://www.uzbl.org/wiki/go-up


history.pl
----------

Writes every page to a history file. Can be enabled/disabled. The status (enabled or disabled) can be displayed in the status bar.


importFFBookmarks.pl
--------------------

A script to convert Firefox bookmarks into the uzbl bookmark format. With this script you can create your uzbl bookmarks file from your firefox bookmarks.
Tags are created from folder names (whitespaces are replaced by underscores)


scriptblock.pl
--------------

Script to (temporarily) whitelist/blacklist domains that should be able to use scripts/plugins. The status (plugins/scripts enabled/disabled) can be displayed in the status bar.


sessions.pl
-----------

A session saving script to save/load sessions. The session can be choosen with dmenu.


ytvp.sh
-------

Play youtube videos with vlc. When entering a youtube video site the vid is downloaded to a temp file and played with vlc


Hint
====

Some scripts are ported because my bash does not want to execute two if statements nested in an if statement. For example:
    if [ ... ];then
        if [ ... ]; then
            # do something
        fi
        if [ ... ]; then
            # do something
        fi
    fi

