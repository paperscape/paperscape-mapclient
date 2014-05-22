Paperscape Map Client
=====================

This is the source code for the browser-based client of the <a href="http://paperscape.org">Paperscape</a> map project.

Details and progress about Paperscape can be found at the <a href="http://blog.paperscape.org">development blog</a>.

Compling
========

The Paperscape map client is written in <a href="coffeescript.org">CoffeeScript</a>, which must first be transcompiled into JavaScript code to run in a browser. 
Similarly, the associated style sheets are written in <a href="sass-lang.com">Sass</a>, which must be transcompiled into CSS.
With CoffeeScript and Sass installed, the `compile` script can be used (on unix-like systems) to automatically perform the compilations.
Once started this script will continue to monitor for changes using the `inotifywait` command (from the inotify toolset) unless the runtime command `--single` is specified.

The JavaScript/CoffeeScript code is split into modules, which are managed and loaded using <a href="http://requirejs.org">RequireJS</a>.

Building (deploying)
====================

The Paperscape map client can be deployed using the included build script. 
Copy shell script `build.def` to `build`, `chmod +x` it, and change the build path as appropriate.
The JavaScript minification is handled by <a href="http://requirejs.org">RequireJS</a>, which results in a single 
The HTML index file is minified by `minhtml/minthml.py`.

About Paperscape
================

Paperscape is an interactive map that visualises the arXiv, an open, online repository for scientific research papers. 
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
=========

Copyright (C) 2011-2014 Damien P. George and Robert Knegjens

Paperscape map client is free software; you can redistribute it and/or 
modify it under the terms of the GNU General Public License as published
by the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

Paperscape map client is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
