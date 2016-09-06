Paperscape Map Client
=====================

This is the source code of the browser-based client of the [Paperscape map](http://paperscape.org) project.
The source code of the [map generation](https://github.com/paperscape/paperscape-mapgen) and [web server](https://github.com/paperscape/paperscape-webserver), as well as the [Paperscape data](https://github.com/paperscape/paperscape-data), are also available on Github. 
For more details and progress on Paperscape please visit the [development blog](http://blog.paperscape.org).

Compiling
---------

The Paperscape map client is written in [CoffeeScript](http://coffeescript.org), which must first be (trans)compiled into JavaScript code for it to run in a browser. 
Similarly, the style sheets are written in [Sass](http://sass-lang.com), which must be compiled into CSS.
With CoffeeScript and Sass installed, the _compile_ script can be used (on unix-like systems) to automatically perform the compilations.
Once started this script will continue to monitor for changes using the `inotifywait` command (from the inotify toolset) unless the runtime command `--single` is specified.

The JavaScript/CoffeeScript code is split into modules, which are managed and loaded using [RequireJS](http://requirejs.org).

Building (deploying)
--------------------

The Paperscape map client can be deployed using the included build script. 
Copy the default build script file _build.def_ to a file named _build_ (i.e. without the extension), and edit the build paths in the new file as appropriate. 
Then give the new build script executable permissions with `chmod +x`, and run it with the command `./build`.
The JavaScript minification is handled by [RequireJS](http://requirejs.org).
The HTML index file is minified by _minhtml/minthml.py_.

About the Paperscape map
------------------------

Paperscape is an interactive map that visualises the [arXiv](http://arxiv.org/), an open, online repository for scientific research papers. 
The map, which can be explored by panning and zooming, currently includes all of the papers from the arXiv and is updated daily.

Each scientific paper is represented in the map by a circle whose size is determined by the number of times that paper has been cited by others.
A paper's position in the map is determined by both its citation links (papers that cite it) and its reference links (papers it refers to).
These links pull related papers together, whereas papers with no or few links in common push each other away.

In the default colour scheme, where papers are coloured according to their scientific category, coloured "continents" emerge, such as theoretical high energy physics (blue) or astrophysics (pink).
At their interface one finds cross-disciplinary fields, such as dark matter and cosmological inflation.
Zooming in on a continent reveals substructures representing more specific fields of research.
The automatically extracted keywords that appear on top of papers help to identify interesting papers and fields.

Clicking on a paper reveals its meta data, such as title, authors, journal and abstract, as well as a link to the full text.
It is also possible to view the references or citations for a paper as a star-like background on the map.

Copyright
---------

The MIT License (MIT)

Copyright (C) 2011-2016 Damien P. George and Robert Knegjens

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
