### 
--------------------------------------------------------------------------
NanoBricks

Copyright 2017 Molecular Systems Lab
Wyss Institute for Biologically-Inspired Engineering
Harvard University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
------------------------------------------------------------------------- 
### 

###*
 * @class pathutils
 * @singleton
 * @static
 * Provides utilities for working with file paths
###
module.exports = pathutils =
	
	###*
	 * Appends the given extension to a filename, if it is not already included.
	 * @param {String} name
	 * @param {String} ext The extension
	###
	addExt: (name, ext) ->
		unless _.last(name.split(".")) is ext
			name + "." + ext
		else
			name

	###*
	 * Gives a path without any extension
	 * @param  {String} oldPath 
	 * @return {String} New path
	###
	removeExt: (oldPath) ->
		unless pathutils.basename(oldPath).indexOf(".") is -1
			oldPath = oldPath.split(".")
			oldPath.pop()
			return oldPath.join(".")
		oldPath

	
	###*
	 * Determines whether the given filename represents a folder
	###
	isFolder: (name) ->
		name and !!pathutils.extname(name)

	
	###*
	 * Joins several file paths.
	 * 
	 *     pathutils.join(['hello','world','file.txt']); // -> 'hello/world/file.txt'
	 * 
	###
	join: ->
		if arguments_.length > 1
			paths = arguments_
		else
			paths = arguments_[0]
		_.flatten(_.map(paths, (p) ->
			p.split "/"
		)).join "/"

	
	###*
	 * Returns the file extension of the path
	 * @param {String} path
	###
	extname: (path) ->
		_.last pathutils.basename(path).split(".")

	
	###*
	 * @alias #extname
	###
	getExt: (path) ->
		pathutils.extname path

	
	###*
	 * Returns the last portion of the path (the portion following the final <var>/</var>)
	###
	basename: (path) ->
		a = path.split("/")
		(if a.length > 0 then _.last(a) else path)

	
	###*
	 * Returns the last portion of the path, with a minimum length
	 * @param {String} path
	 * @param {Number} minLength
	###
	pop: (path, minLength) ->
		Ext.isDefined(minLength) or (minLength = 1)
		a = path.split("/")
		(if (a.length) > minLength then a.slice(0, a.length - 1).join("/") else path)

	
	###*
	 * Returns <var>newPath</var> such that it is in the same directory as the file <var>oldPath</var>
	 * @param {String} oldPath
	 * @param {String} newPath
	###
	sameDirectory: (oldPath, newPath) ->
		pathutils.join pathutils.pop(oldPath), newPath

	
	###*
	 * Returns a file in the same directory as <var>oldPath</var>, but with <var>ext</var>
	 * @param {String} oldPath
	 * @param {String} ext
	###
	repostfix: (oldPath, ext) ->
		unless pathutils.basename(oldPath).indexOf(".") is -1
			oldPath = oldPath.split(".")
			oldPath.pop()
			oldPath.concat([ext]).join "."
		else
			[
				oldPath
				ext
			].join "."