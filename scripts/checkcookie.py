#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Check Cookie Script for uzbl

This script checks whether a domain is in the cookie whitelist and colours a status symbol accordingly.

USAGE:
1)place this script in ~/.local/share/uzbl/scripts
2)add the following to your ~/.config/uzbl/config:
set cookie_color	  = #CD2626
set cookie_status	 = <span foreground="\@cookie_color">C</span>
set status_format	 = <span font_family="monospace">[...]@cookie_status</span>

@on_event   LOAD_COMMIT	spawn @scripts_dir/checkcookie.py
"""

import sys
import os

filename = os.path.expanduser("~/.config/uzbl/cookie_whitelist")

def main():
	url = sys.argv[6]
	fifo = sys.argv[4]
	if search(url):
		s = "set cookie_color = #008B00\n" #cookies allowed -> green
	else:
		s = "set cookie_color = #CD2626\n" #cookies not allowed -> red
	f = open(fifo,"w")
	f.write(s)
	f.close

def search(url):
	#cut url from http://www.mydomain.com/bla to mydomain.com
    startpos = url.find("//") + 2
    endpos = url.find("/",startpos)
    url = url[startpos:endpos]
    url = url.replace("www.","")
    #check for url in whitelist
    f = open(filename,"r")
    string = f.read()
    url_in_file = string.find(url) #TODO:regex to avoid finding it in substrings
    f.close()
    if url_in_file == -1:
    	return False
    else:
    	return True


if __name__ == "__main__":
	main()
