SCRIPT PARSED DIRECTORY EXAMPLE
===============================

This script assumes this is the DocumentRoot for the domain.

In this example you can apreciate how simple it is
to parse all the html files in the '/www' dir with a magic
script that simply fills all the labels it finds in the files
with the run time values.

You can structure your dinamic site directory as it were simply
static files, easily linked toghether with any wysiwyg editor.
This could be done by anyone able to use an HTML editor...

In the '/www' directory  there are 3 html files linked as they
were just static files. In the '/www/index.html' file you can
see the links that are pointing to the other 2 files: they do not
point to any cgi-script.

In the '/lib/wma.pl' we pass a setup with the new() method
that allows us to change a couple of defaults.

The '.htaccess' adds a very basic dispatcher using mod_rewrite,
calling the '/lib/wma.pl' script, and passing it the base file
name (without '.html') as the run mode. This dispatcher is very
simple and aimed just to make this example work. You should work
on it and eventually mod_perl to make it work in real jobs.

Anyway the trick is simple: using the file name as the run mode so
that you can script-parse a static file structure to make it dynamic.
May be I will write an Apache module in the future to do so 
directly with mod_perl. Do you want to write it yourself?
Please, contact me.

--
Domizio Demichelis <dd@4pro.net>
2004-01-09






