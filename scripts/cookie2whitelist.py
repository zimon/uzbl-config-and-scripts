#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Add cookie to whitelist script for uzbl

This script adds the domain of current site to the cookie whitelist if the domain is not already in there. This script requires the checkcookie.py script to be placed in the same folder.

USAGE:
1)place this script and checkcookie.py in your ~/.local/share/uzbl/scripts folder
2)Add the following to your config file:
@cbind AC = spawn @scripts_dir/cookie2whitelist.py \@uri
"""
import checkcookie
import sys
import os

#@cbind AC = spawn @scripts_dir/cookie2whitelist.py \@uri

filename = os.path.expanduser("~/.config/uzbl/cookie_whitelist")

def main():
    url = sys.argv[6]
    if not checkcookie.search(url):
        write2file(url)


def write2file(url):
    print "writing"
    print (url)
    print (filename)
    file = open(filename,"a")
    file.write(url + "\n")
    file.close()

if __name__ == "__main__":
    main()
