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

_ = require("underscore-contrib")
# _ = require("underscore")
ndarray = require("ndarray")
morphology = require("ball-morphology")
pool = require("ndarray-scratch")
ops = require("ndarray-ops")
show = require("ndarray-show")
fill = require("ndarray-fill")
warp = require("ndarray-warp")
THREE = require("three")


###*
 * @class vox
 * @singleton
 * @static
###
vox = {}

signum = (x) ->
	if x > 0 then 1 else if x < 0 then -1 else 0

###*
 * @method  vox.index
 * Accepts an object and a path, in dot-notation; returns the value at that `path`
 * within the `object`:
 *
 *     x = { foo: { bar: { baz: 'y' } } }
 *     index(x, 'foo.bar.baz') // 'y'
 *
 * @param  {Object} obj Object from which to pull data
 * @param  {String} s Path to the value
 * @return {Mixed} value
###
vox.index = (obj, s) -> 
	s.split('.').reduce ((o, i) -> return o[i]), obj


###*
 * @class vox.lit
 * @singleton
 * @static
 *
 * Various utilities for elementwise operations on arrays; allows more
 * concise expression of elementwise equality, comparison, and arithmetic.
 * These functions are available in the local scope in the Add/Remove Voxels
 * and PowerEdit tools.
 *
 * Examples:
 *
 *     a = [1, 2, 3, 4]
 *     b = [1, 2, 3, 4]
 *     equal a, b # true
 *
 *     c = [4, 5, 6, 7]
 *     d = [2, 3, 4, 5]
 *     sub c, d # [2, 2, 2, 2]
 * 
###
vox.lit = do () ->
	###*
	 * Performs deep comparison for equality on a and b; returns true if 
	 * `a` and `b` are elementwise equal. 
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Boolean} 
	###
	equal = (a, b) -> _.isEqual(a, b)

	###*
	 * Performs lexicographic, elementwise comparison on a and b; if `a` is 
	 * the "larger" array, returns `1`; if `b` is larger, returns `-1`; else
	 * returns `0`.
	 *
	 * Arrays are first compared based on length (longer is larger), then 
	 * each element is compared in sequence (`a[0]` vs `b[0]`, then 
	 * `a[1]` vs. `b[1]`, and so on).
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {-1/0/1} `1` if `a` is greater, `-1` if `b` is greater, `0` if equal
	###
	cmp = (a, b) -> 
		if a.length isnt b.length then return a.length - b.length
		else
			for i in [0...a.length]
				if a[i] isnt b[i] then return signum(a[i] - b[i])
		return 0 

	###*
	 * Returns `true` if `a` is elementwise less than `b`, else `false`
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Boolean} 
	###
	less = (a, b) -> cmp(a,b) < 0
	###*
	 * Returns `true` if `a` is elementwise greater than `b`, else `false`
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Boolean} 
	###
	greater = (a, b) -> cmp(a,b) > 0
	###*
	 * Returns `true` if `a` is elementwise less than or equal to `b`, else `false`
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Boolean} 
	###
	lessEq = (a, b) -> cmp(a,b) <= 0

	###*
	 * Returns `true` if `a` is elementwise greater than or equal to `b`, else `false`
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Boolean} 
	###
	greaterEq = (a, b) -> cmp(a,b) >= 0

	###*
	 * Elementwise subtracts `a` and `b`. If the arrays are different lengths,
	 * an array of the shorter length is returned.
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Array} 
	###
	sub = (a, b) ->
		l = Math.min a.length, b.length
		((a[i] - b[i]) for i in [0...l])

	###*
	 * Elementwise adds `a` and `b`. If the arrays are different lengths,
	 * an array of the shorter length is returned.
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Array} 
	###
	add = (a, b) ->
		l = Math.min a.length, b.length
		((a[i] + b[i]) for i in [0...l])

	###*
	 * Elementwise multiplies `a` and `b`. If the arrays are different lengths,
	 * an array of the shorter length is returned.
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Array} 
	###
	mul = (a, b) ->
		l = Math.min a.length, b.length
		((a[i] * b[i]) for i in [0...l])

	###*
	 * Elementwise divides `a` and `b`. If the arrays are different lengths,
	 * an array of the shorter length is returned.
	 * @param  {Array} a 
	 * @param  {Array} b 
	 * @return {Array} 
	###
	div = (a, b) ->
		l = Math.min a.length, b.length
		((a[i] / b[i]) for i in [0...l])

	###*
	 * Returns the sum of the elements in `a`
	 * @param  {Array} a 
	 * @return {Number} Sum of elements in `a`
	###
	sum = (a) -> _.reduce a, ((x,y) -> x+y), 0

	###*
	 * Returns `true` if any elements of `a` evaluate to `true` 
	 * @param  {Array} a 
	 * @return {Boolean} 
	###
	any = (a) -> _.any a
	
	###*
	 * Returns `true` if all elements of `a` evaluate to `true` 
	 * @param  {Array} a 
	 * @return {Boolean} 
	###
	all = (a) -> _.all a

	equal: equal
	eq: equal
	cmp: cmp
	less: less
	lt: less
	greater: greater
	gt: greater
	lessEq: lessEq
	leq: lessEq
	greaterEq: greaterEq
	geq: greaterEq

	add: add
	sub: sub
	mul: mul
	div: div

	sum: sum
	all: all
	every: all
	any: any
	some: any

###*
 * @class vox.utils
 * @singleton
 * @static
###
vox.utils = do () ->
	
	###*
	 * Applies a function to each cell of a 3D matrix
	 * @param	{Array[][]} matrix A 3D matrix
	 * 
	 * @param	{Function} fun Function to apply to each cell of the matrix
	 * 
	 * @param {Mixed} fun.cell Each cell of the matrix
	 * @param {Number} fun.i i-index of the current cell in the matrix
	 * @param {Number} fun.j j-index of the current cell in the matrix
	 * @param {Number} fun.k k-index of the current cell in the matrix
	 * 
	 * @param	{Mixed} scope Scope in which to execute `fun`
	 * 
	 * @return {Array[][]} New matrix resulting from applying `fun` to each cell
	###
	map3d: (matrix, fun, scope) ->
		_.map matrix, (row, i) ->
			_.map row, (col, j) ->
				_.map col, (cell, k) ->
					fun.call scope, cell, i, j, k
					return

	###*
	 * Applies a function to each index of a 3D ndarray, collecting the results
	 * @param  {Function} body 
	 * @param {Number} body.i 
	 * @param {Number} body.j 
	 * @param {Number} body.k 
	 * @param  {ndarray} array Array to iterate over
	 * @return {Mixed[][][]} Results
	###
	iter3d: (body, array) ->
		# cwise
		# 	args: ["array"]
		# 	body: body
		i = 0;
		while i < array.shape[0]
			j = 0;
			while j < array.shape[1]
				k = 0;
				while k < array.shape[2]
					body(i,j,k)
					k++
				j++
			i++

	###*
	 * Applies a function to each element of a 3D ndarray, collecting the results
	 * @param  {Function} body 
	 * @param {Mixed} body.value The value at position `i,j,k` within the array
	 * @param {Number} body.i 
	 * @param {Number} body.j 
	 * @param {Number} body.k 
	 * @param  {ndarray} array Array to iterate over
	 * @return {Mixed[][][]} Results
	###
	each3d: (body, array) ->
		# cwise
		# 	args: ["array"]
		# 	body: body
		i = 0;
		while i < array.shape[0]
			j = 0;
			while j < array.shape[1]
				k = 0;
				while k < array.shape[2]
					body(array.get(i,j,k), i,j,k)
					k++
				j++
			i++

	matrix3d: (w, h, d, x) ->
		arr = Array(w)
		i = 0

		while i < w
			arr[i] = Array(h)
			j = 0

			while j < h
				arr[i][j] = Array(d)
				k = 0

				while k < d
					arr[i][j][k] = x
					k++
				j++
			i++
		arr.width = w
		arr.height = h
		arr.depth = d
		arr

	###*
	 * Attempts to get the value at position `pos` from `arr` if each element 
	 * of `pos` is within `arr.shape`.
	 * @param  {Array} pos 3-element array containing a position
	 * @param  {ndarray} arr ndarray to access
	###
	boundGet: (pos, arr) ->
		if (0 <= pos[0] < arr.shape[0]) and	(0 <= pos[1] < arr.shape[1]) and (0 <= pos[2] < arr.shape[2])
			arr.get(pos...)
		else null

	hasNeighbors: (pos, dist, arr) ->
		# res = true
		for i in [pos[0]-dist..pos[0]+dist]
			for j in [pos[1]-dist..pos[1]+dist]
				for k in [pos[2]-dist..pos[2]+dist]
					if vox.utils.boundGet([i,j,k], arr)? then continue
					else return false
					# if i isnt pos[0] and j isnt pos[1] and k isnt pos[2]
					# 	res = res and vox.utils.boundGet([i,j,k], arr)?
					# if not res then return false
		# return res
		return true

	hasNeighborsObj: (pos, dist, obj) ->
		# res = true
		for i in [pos[0]-dist..pos[0]+dist]
			for j in [pos[1]-dist..pos[1]+dist]
				for k in [pos[2]-dist..pos[2]+dist]
					if !!obj[[i,j,k]] then continue
					else return false
					# if i isnt pos[0] and j isnt pos[1] and k isnt pos[2]
					# 	res = res and ([i,j,k] of obj)
					# if not res then return false
		# return res
		return true


	clear3d: (arr) ->
		vox.utils.iter3d ((i,j,k) -> arr.set(i,j,k, undefined)), arr

	###*
	 * converts a "strip" of points (e.g. a, b, c) to be linked together, representing
	 * a polygon, into a list of pieces (e.g. a, b, b, c, c, a)
	###
	strip2pieces: (vertices, circular=true) ->
		list = [vertices[0]]
		for v in vertices[1...]
			list.push v, v.clone()
		if circular then list.push vertices[0].clone()
		else list.pop()
		list

	periodicWrap: (crystal) ->
		switch
			when typeof crystal is ndarray then (i,j,k) ->
				[crystal.get(i,j,k,0), 
				crystal.get(i,j,k,1), 
				crystal.get(i,j,k,2)]
			when _.isFunction crystal then crystal
			when _.isArray crystal then (i,j,k) ->
				pos = [i,j,k]
				for r, l in pos 
					pos[l] = if crystal[l]?[0] > r then r-crystal[l][0]+1+crystal[l][1]
					else if crystal[l]?[1] < r then r-crystal[l][1]-1+crystal[l][0]
					else r
				pos

			else (i,j,k) -> [i,j,k]

	periodicEdge: (crystal) ->
		switch
			when _.isArray crystal then (i,j,k) ->
				pos = [i,j,k]
				for r, l in pos 
					if crystal[l]?[0] is r then -1
					else if crystal[l]?[1] is r then +1
					else 0
			else (i,j,k) -> [0,0,0]

	binaryArray: (arr) ->
		copy = pool.zeros arr.shape, 'int8'
		vox.utils.each3d ((val, i,j,k) -> copy.set(i,j,k, +(val?))), arr 
		copy

	testArray: (arr) ->
		(i,j,k) -> !!arr.get(i,j,k)

	show: show
	fill: fill
	ops: ops
	ndarray: ndarray

###*
 * @class vox.morphology
 * @static
 * @singleton
 *
 * Performs various image manipulations on binary images based on 
 * techniques from [Mathematical morphology](http://en.wikipedia.org/wiki/Mathematical_morphology).
 * To use within scripting, first retrieve a binary image of the current 
 * voxels:
 *
 *     im = voxels.image()
 *
 * Then pass the resulting image to any of these functions. The resulting
 * binary image can be consumed by the Add/Remove Voxels tool or by the 
 * PowerEdit tool:
 *
 *     # erodes the image (removes voxels starting from the boundary)
 *     morph.erode im
 *
 *     # fills a hole starting at 4, 5, 8
 *     morph.fillHole im, [4, 5, 8]
 * 
###
vox.morphology = 
	image: vox.utils.binaryArray

	###*
	 * Rotates the image. By default, overwrites the input.
	 * @param  {ndarray} arr 
	 * @param  {Number} theta Amount to rotate (in radians)
	 * @param  {Number[]} [axis] Axis about which to rotate (defaults to `[0,1,0]`)
	 * @param  {Number[]} [iC] Point of input about which to rotate (defaults to the center of the input)
	 * @return {ndarray} Rotated image.
	###
	# rotate: (arr, theta, iX, iY, oX, oY) ->
	rotate: (arr, theta, axis, iC) ->
		# inp = pool.clone arr
		# out = arr
		# c = Math.cos(theta)
		# s = Math.sin(-theta)
		# iX = iX || inp.shape[0]/2.0
		# iY = iY || inp.shape[1]/2.0
		# oX = oX || out.shape[0]/2.0
		# oY = oY || out.shape[1]/2.0
		# a = iX - c * oX + s * oY
		# b = iY - s * oX - c * oY
		# warp out, inp, (y,x) ->
		# 	y[0] = c * x[0] - s * x[1] + a
		# 	y[1] = s * x[0] + c * x[1] + b
		# 	y[2] = x[2]
		# pool.free inp
		# return out
		axis ?= [0,1,0]
		iC ?= [-arr.shape[0]/2, -arr.shape[1]/2, -arr.shape[2]/2]
		matrices = [
			new THREE.Matrix4().makeTranslation iC[0], iC[1], iC[2]
			new THREE.Matrix4().makeRotationAxis(new THREE.Vector3(axis...), theta)
			new THREE.Matrix4().makeTranslation -iC[0], -iC[1], -iC[2]
		]
		vox.morphology.applyMatrix4 arr, matrices
	
	###*
	 * Apply a matrix (or series of matrices) to the image
	 * @param  {ndarray} arr Input array
	 * @param  {THREE.Matrix4/THREE.Matrix4[]} matrices 
	 * @return {ndarray} Output array (overwrites the input)
	###
	applyMatrix4: (arr, matrices) ->
		if matrices instanceof THREE.Matrix4 then matrices = [matrices]
		inp = pool.clone arr
		out = arr
		v = new THREE.Vector3()
		warp out, inp, (o,i) ->
			v.set i[0], i[1], i[2]
			for matrix in matrices
				v.applyMatrix4 matrix
			o[0] = v.x
			o[1] = v.y
			o[2] = v.z
			return

		pool.free inp
		return out
		
	###*
	 * Performs an [inverse image warp](https://github.com/mikolalysenko/ndarray-warp)
	 * on the input image. Output will overwrite the input.
	 * @param  {ndarray} arr 
	 * @param  {Function} f Warping function; should overwrite ouput with the output coordinates
	 * @param {Number[]} f.output Output coordinates
	 * @param {Number[]} f.input Input coordinates
	 * @return {ndarray} arr
	###
	warp: (arr, f) ->
		input = pool.clone arr
		output = arr
		warp(output, input, f)
		pool.free input
		output

	###*
	 * Performs a morphological [erosion](http://en.wikipedia.org/wiki/Erosion_%28morphology%29) 
	 * on the input array with a ball of the given radius
	 * @param  {ndarray} arr Binary image (updated in place)
	 * @param  {Number} [radius=1] Size of the structuring element
	 * @param  {Number} [p=2] Exponent of the metric
	 * @return {ndarray} Resulting image
	###
	erode: (arr, radius=1, p=2) ->
		morphology.erode arr, radius, p

	###*
	 * Performs a morphological [dilation](http://en.wikipedia.org/wiki/Dilation_%28morphology%29) 
	 * on the input array with a ball of the given radius.
	 * @param  {ndarray} arr Binary image (updated in place)
	 * @param  {Number} [radius=1] Size of the structuring element
	 * @param  {Number} [p=2] Exponent of the metric
	 * @return {ndarray} Resulting image
	###
	dilate: (arr, radius=1, p=2) ->
		morphology.dilate arr, radius, p

	###*
	 * Performs a morphological [opening](http://en.wikipedia.org/wiki/Opening_%28morphology%29) 
	 * on the input array with a ball of the given radius.
	 * 
	 * Opening removes small objects; use a larger radius to remove bigger objects.
	 * 
	 * @param  {ndarray} arr Binary image (updated in place)
	 * @param  {Number} [radius=1] Size of the structuring element
	 * @param  {Number} [p=2] Exponent of the metric
	 * @return {ndarray} Resulting image
	###
	open: (arr, radius=1, p=2) ->
		morphology.open arr, radius, p

	###*
	 * Performs a morphological [closing](http://en.wikipedia.org/wiki/Closing_%28morphology%29) 
	 * on the input array with a ball of the given radius.
	 * Closing removes holes the size of the structuring element; use a larger radius
	 * to close bigger holes.
	 * 
	 * @param  {ndarray} arr Binary image (updated in place)
	 * @param  {Number} [radius=1] Size of the structuring element
	 * @param  {Number} [p=2] Exponent of the metric
	 * @return {ndarray} Resulting image
	###
	close: (arr, radius=1, p=2) ->
		morphology.close arr, radius, p

	###*
	 * Gets the 3D boundary of the input array
	 * @param  {ndarray} arr Binary image (updated in place)
	 * @return {ndarray} Resulting image
	###
	getBoundary: (arr) ->
		# erode the input array
		err = pool.clone arr
		morphology.erode err, 1

		# subtract the erosion from the input array to get the boundary
		ops.subeq arr, err
		pool.free(err)
		arr

	###*
	 * Fills a 3D hole within the input array, starting at the given position. 
	 * This acts like a smarter "flood fill"---like the paint bucket tool in
	 * Photoshop.
	 *  
	 * @param  {ndarray} arr Binary image (updated in place)
	 * @param  {Number[]} hint Position in the array to start filling
	 * @param  {Number} [radius=1] Size of the structuring element
	 * @param  {Number} [p=2] Exponent of the metric
	 * @return {ndarray} Resulting image
	###
	fillHole: (arr, hint, radius=1, p=2) ->
		# take the complement of the image
		comp = pool.clone arr
		ops.noteq comp

		# create two zero arrays
		out1 = pool.zeros arr.shape, 'int8'
		out2 = pool.zeros arr.shape, 'int8'
		
		# start growth at hint
		out2.set hint..., 1

		# loop until convergence
		loop
			# dilate
			morphology.dilate out2, radius, p
			ops.andeq out2, comp

			if ops.equals out1, out2 then break
			ops.assign out1, out2

		ops.oreq arr, out2
		pool.free(comp)
		pool.free(out1)
		pool.free(out2)
		arr

	show: show
	ops: ops
	fill: fill


###*
 * @class vox.shapes
 * @singleton
 * @static
 * Collection of functions for generating various shapes. Each of these 
 * methods creates a _shape generator function_; that is, a function 
 * which takes `x`, `y`, and `z` coordinates and returns `true` or `false`.
 *
 * To use these functions in the Add/Remove voxel tool, you need to simply
 * enter a function call, like this:
 *
 *     cuboid 7, 4, 3,  10, 10, 10
 *
 * The call to `cuboid` will return a function that will be called on each
 * voxel position (each `x`,`y`, and `z` in the lattice), returning `true`
 * if the position is on the shape, or `false` otherwise.
###
vox.shapes = do () ->

	###*
	 * @method cuboid
	 * Builds a generator function to make cuboids (rectangular prisms)
	 * @param  {Number} w Width (in voxels)
	 * @param  {Number} h Height (in voxels)
	 * @param  {Number} d Depth (in voxels)
	 * @param  {Number} cx=0 Center X lattice position
	 * @param  {Number} cy=0 Center Y lattice position
	 * @param  {Number} cz=0 Center Z lattice position
	 * @param  {Boolean} [hollow=false] True to create a hollow cuboid
	 * @return {Function} generator Generator function to make the cuboid
	 * @return {Number} generator.x
	 * @return {Number} generator.z
	 * @return {Number} generator.y
	 * @return {Boolean} generator.return
	###
	cuboid = (w, h, d, cx=0, cy=0, cz=0, hollow=false) ->
		if hollow 
			intersect(
				cuboid(w,h,d, cx,cy,cz),
				negate(cuboid(w-2,h-2,d-2, cx,cy,cz))
			)

		else (x,y,z) -> 
			((cx-w/2-0.5) <= x < (cx+w/2+0.5)) and
			((cy-h/2-0.5) <= y < (cy+h/2+0.5)) and
			((cz-d/2-0.5) <= z < (cz+d/2+0.5)) 

	###*
	 * Builds a generator function to make cubes
	 * @param  {Number} r Radius (in voxels) = width = height = depth
	 * @param  {Number} cx=0 Center X lattice position
	 * @param  {Number} cy=0 Center Y lattice position
	 * @param  {Number} cz=0 Center Z lattice position
	 * @return {Function} generator Generator function to make the cube
	 * @return {Number} generator.x
	 * @return {Number} generator.z
	 * @return {Number} generator.y
	 * @return {Boolean} generator.return
	###	
	cube =  (r, cx=0, cy=0, cz=0) ->
		vox.shapes.cuboid r,r,r,cx,cy,cz

	###*
	 * Builds a generator function to make sphereoids/ellipsoids
	 * @param  {Number} w Width (in voxels) = X diameter
	 * @param  {Number} h Height (in voxels) = Y diameter
	 * @param  {Number} d Depth (in voxels) = Z diameter
	 * @param  {Number} cx=0 Center X lattice position
	 * @param  {Number} cy=0 Center Y lattice position
	 * @param  {Number} cz=0 Center Z lattice position
	 * @param  {Boolean} [hollow=false] True to create a hollow sphereoid
	 * @return {Function} generator Generator function to make the sphereoid
	 * @return {Number} generator.x
	 * @return {Number} generator.z
	 * @return {Number} generator.y
	 * @return {Boolean} generator.return
	###
	sphereoid = (rx, ry, rz, cx=0, cy=0, cz=0) ->
		(x, y, z) -> 
			((x-cx)**2/(rx**2) +
			(y-cy)**2/(ry**2) +
			(z-cz)**2/(rz**2)) < 1

	###*
	 * Builds a generator function to make spheres
	 * @param  {Number} r Radius (in voxels) = width = height = depth
	 * @param  {Number} cx=0 Center X lattice position
	 * @param  {Number} cy=0 Center Y lattice position
	 * @param  {Number} cz=0 Center Z lattice position
	 * @return {Function} generator Generator function to make the sphere
	 * @return {Number} generator.x
	 * @return {Number} generator.z
	 * @return {Number} generator.y
	 * @return {Boolean} generator.return
	###
	sphere =  (r, cx=0, cy=0, cz=0) ->
		vox.shapes.sphereoid r,r,r,cx,cy,cz


	###*
	 * Returns a new shape generator function that is the union of several
	 * other shape generator functions.
	 *
	 * Example: union of a sphere and a cuboid:
	 *
	 *     union(
	 *         cuboid(4,5,7, 10,10,10),
	 *         sphere(5, 10,10,15)
	 *     )
	 *
	 * Note that generator functions need not be builtin:
	 *
	 *     union(
	 *         cuboid(4,5,7, 10,10,10),
	 *         (x, y, z) -> x % 2 is 0
	 *     )
	 * 
	 * @param  {Function[]} funcs... Pass any number of shape generator functions as arguments
	 * @return {Function} generator New union shape generator function
	 * @return {Number} generator.x
	 * @return {Number} generator.z
	 * @return {Number} generator.y
	 * @return {Boolean} generator.return
	###
	union =  (funcs...) ->
		(x, y, z) -> _.any(f(x,y,z) for f in funcs)

	###*
	 * Returns a new shape generator function that is the intersection (overlapping part) of several
	 * other shape generator functions.
	 *
	 * Example: overlap between a sphere and a cuboid:
	 *
	 *     intersect(
	 *         cuboid(4,5,7, 10,10,10),
	 *         sphere(5, 10,10,15)
	 *     )
	 * 
	 * Note that generator functions need not be builtin:
	 *
	 *     intersect(
	 *         cuboid(4,5,7, 10,10,10),
	 *         (x, y, z) -> x % 2 is 0
	 *     )
	 * 
	 * @param  {Function[]} funcs... Pass any number of shape generator functions as arguments
	 * @return {Function} generator New union shape generator function
	 * @return {Number} generator.x
	 * @return {Number} generator.z
	 * @return {Number} generator.y
	 * @return {Boolean} generator.return
	###
	intersect =  (funcs...) ->
		(x, y, z) -> _.all(f(x,y,z) for f in funcs)


	###*
	 * Returns a new shape generator function that is the negation of another 
	 * shape generator function
	 *
	 * Example: Hollow a sphere out of the lattice
	 *
	 *     negate sphereoid(4,5,7, 10,10,10)
	 * 
	 * @param  {Function[]} funcs... Pass any number of shape generator functions as arguments
	 * @return {Function} generator New union shape generator function
	 * @return {Number} generator.x
	 * @return {Number} generator.z
	 * @return {Number} generator.y
	 * @return {Boolean} generator.return
	###
	negate =  (func) ->
		(x, y, z) -> not func(x,y,z)

	translate = (dx, dy, dz, func) ->
		(x, y, z) -> func x+dx, y+dy, z+dz

	cuboid : cuboid
	cube : cube
	sphereoid : sphereoid
	sphere : sphere
	union : union
	intersect : intersect
	negate : negate

class vox.Slice
	constructor: (@axes) -> 
		undefined

	set: (axis, low, high) ->
		@axes[axis] = [low, high]

	get: (axis) ->
		[ @axes[axis][0], @axes[axis][1] ]

	getAxes: () -> @axes.length

	within: (position) ->
		within = true
		for r, i in position
			within = within and (if parseInt(@axes[i][0]) <= parseInt(@axes[i][1]) 
				@axes[i][0] <= r <= @axes[i][1] 
			else @axes[i][1] > r or @axes[i][0] <= r)
		return within

###*
 * @class vox.lattice
 * @static
 * @singleton
###
vox.lattice = do () ->
	
	class Lattice 
		@_name = 'Lattice'
		@_class: 'vox.lattice.Lattice'
		
		###*
		 * @class  vox.lattice.Lattice
		 * Represents a 3D lattice. This is an abstract class documenting the 
		 * interface which all lattices must implement.
		 *
		 * The main responsibility of the lattice is to translate between 3D 
		 * coordinates and "lattice" coordinates (or "lattice positions"). A 
		 * lattice position is an array of 3 or 4 numbers: 
		 *
		 *     [helix X position (a), helix Y position (b), helix Z position (voxel number) (c), base index (d)]
		 *
		 * The base index `d` is optional, and should be a position between `0`
		 * and {@link #length `#length(a,b,c)`}.
		 * 
		 * @abstract
		 * @constructor
		 * @param  {Number} [w] Width of the lattice
		 * @param  {Number} [h] Height of the lattice
		 * @param  {Number} [d] Depth of the lattice
		 * @param  {Object} options Options to be copied to the lattice
		###
		constructor: (w, h, d, options) ->
			@_class = @constructor._class
			@_name = @constructor._name 

			if arguments.length > 1
				@width = w
				@height = h
				@depth = d
			else
				options = arguments[0]
			_.extend this, options
			
			@dlen = @dlen ? 13
			@up = @up ? [0,1,0]
			@up = new THREE.Vector3(@up...).normalize()

		###*
		 * @property {String} description 
		 * Textual description of the lattice's configuration
		###

		###*
		 * @property {Number} width
		 * Size of the lattice in the x-direction
		###
		width: 10

		###*
		 * @property {Number} height
		 * Size of the lattice in the y-direction
		###
		height: 10

		###*
		 * @property {Number} depth
		 * Size of the lattice in the z-direction
		###
		depth: 10

		###*
		 * @property {Boolean} isLattice
		 * @internal
		###
		isLattice: true


		toJSON: () ->
			_.pick @, 'width', 'height', 'depth', '_class'

		###*
		 * Returns the shape of the lattice: `[width, height, depth]`
		 * @return {Array} Shape of the lattice
		###
		shape: () -> [@width, @height, @depth]

		###*
		 * Returns the bottom/left/back position of the lattice---the lowest-
		 * numbered valid position on the lattice. 
		 * @return {Array} [X position, Y position, Z position]
		###
		min: () -> [0,0,0]

		###*
		 * Returns the top/right/front position of the lattice---the highest-
		 * numbered valid position on the lattice. 
		 * @return {Array} [X position, Y position, Z position]
		###
		max: () -> @shape()

		###*
		 * Returns the position o
		 * @return {[type]} [description]
		###
		centroid: () ->
			[@width // 2, @height // 2, @depth // 2]

		###*
		 * Snaps a point in 3D space to the center of the corresponding lattice
		 * cell.
		 * @param  {Number} x 
		 * @param  {Number} y 
		 * @param  {Number} z 
		 * @return {Array} Center point in 3D space
		###
		pointToCenter: (x, y, z) -> @latticeToPoint(@pointToLattice(x,y,z, false)...)
		snap: (x, y, z) -> @pointToCenter arguments...

		###*
		 * Converts a point in 3D space to a position vector on the lattice
		 * @param	{Number} x
		 * @param	{Number} y
		 * @param	{Number} z
		 * @param {Boolean} base `true` to give the base index as the fourth position value
		 * @return {Array} Position on the lattice
		 * @abstract
		###
		pointToLattice: (x, y, z, base=false) ->
			# body...
		
		###*
		 * Accepts a position on the lattice and gives the center point of that cell in 3D space
		 * @param	{Number} a
		 * @param	{Number} b
		 * @param	{Number} c
		 * @return {Array} Point in 3D space
		 * @abstract
		###
		latticeToPoint: (a, b, c, d=null) ->
			# body...
		
		###*
		 * Determines if a vector (`a`,`b`,`c`) is on the lattice
		 * @param	{Number} a
		 * @param	{Number} b
		 * @param	{Number} c
		 * @param	{Number} [d=0]
		 * @return {Boolean} `true` if the vector is on the lattice, else `false`
		###
		isOnLattice: (a, b, c, d) ->
			(a >= 0 and a < @width) and (b >= 0 and b < @height) and (c >= 0 and c < @depth) and (if d? then d >= 0 and d < @length(a,b,c) else true)
		
		###*
		 * Apply method to each vector on the lattice
		 * @param  {Function} iterator Iterator to recieve point argument
		 * @param {Number} iterator.a 
		 * @param {Number} iterator.b 
		 * @param {Number} iterator.c 
		###
		each: (iter) ->
			for a in [0...@width]
				for b in [0...@height]
					for c in [0...@depth]
						iter a,b,c
		###*
		 * Returns a geometry for the cell at position a,b,c in the lattice, 
		 * centered at the origin in world coordinates. 
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @return {THREE.Geometry} Geometry of the cell
		 * @abstract
		###
		cellGeometry: (a, b, c) ->

		###*
		 * Returns a geometry associated with the 2d "footprint" of the cell, 
		 * centered at the origin in world coordinates.
		 * These geometries for each cell are concatenated together to form 
		 * the grid.
		 * Geometries should be in the THREE.LinePieces format (e.g. elements
		 * of the {@link THREE.Geometry#vertices} should be in pairs, where 
		 * elements `i` and `i+1` each represent a line segment. 
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @return {THREE.Geometry} Geometry of the footprint
		 * @abstract
		###
		cellFootprint: (a, b, c) ->

		###*
		 * Returns a Catmull-Rom spline pointing from position 
		 * `a, b, c-1` to position `a, b, c+1`, through the center of cell 
		 * `a, b, c`. The center of the spline (t=0.5) should correspond to 
		 * the middle of the cell and should be at the origin in world 
		 * coordinates.
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @return {THREE.SplineCurve3} 
		 * @abstract
		###
		cellSpline: (a, b, c) ->

		###*
		 * Get the geometry associated with a particular base; relies on #cellSpline
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @param  {Number} d 
		 * @param  {Number} dir=1 Direction of the base: +1 for 5' to 3' along the helical axis, -1 for 3' to 5'
		 * @return {Object} 
		 * @return {THREE.Vector3} return.point Vector giving the position of the base
		 * @return {THREE.Vector3} return.tangent Vector pointing in the direction of the next base along the helical spline
		 * @return {THREE.Vector3} return.normal Vector pointing "up" relative to the helical spline
		 * @return {THREE.Vector3} return.binormal Vector pointing in the +x direction relative to the helical spline
		###
		base: (a, b, c, d, dir=1) ->
			if not @isOnLattice(a, b, c, d) then return null
			len = @length(a,b,c)
			spline = @cellSpline(a, b, c, len)
			t = (d+0.5)/len
			r = spline.getPoint(t)
			T = spline.getTangent(t).normalize().multiplyScalar(dir)
			N = @up.clone()
			B = T.clone().cross(N).normalize()
			return { point: r, tangent: T, normal: N, binormal: B }

		###*
		 * Returns the length of the given voxel, in bases
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @return {Number} Length
		###
		length: (a, b, c) ->
			@dlen

		###*
		 * Gives the largest #length of any voxel on the lattice; this is 
		 * useful for constructing fixed-size arrays, even when the lattice 
		 * may have variable-length voxels.
		 * @return {Number} Max length
		###
		maxLength: () ->
			if not @_maxLength 
				me = @
				@_maxLength = _.max _.flatten @each((i, j, k) -> me.length(i,j,k))
			@_maxLength

		###*
		 * Gets the 5' neighbor of a base at [a, b, c, d] running in the given direction
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @param  {Number} d 
		 * @param  {Number} dir Direction of the strand; +1 is 5' -> 3', -1 is 3' -> 5'
		 * @return {Number[]} Position of the neighboring base [a', b', c', d']
		###
		neighbor5p: (a, b, c, d, dir) ->
			# if dir is -1 
			# 	if d+1 > @length a, b, c then [a, b, c+1, 0]
			# 	else [a, b, c, d+1]

			# else if dir is 1
			# 	if d-1 < 0 then [a, b, c-1, @length(a, b, c)]
			# 	else [a, b, c, d-1]
			@neighbor a, b, c, d, dir, -1

		###*
		 * Gets the 3' neighbor of a base at [a, b, c, d] running in the given direction
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @param  {Number} d 
		 * @param  {Number} dir Direction of the strand; +1 is 5' -> 3', -1 is 3' -> 5'
		 * @return {Number[]} Position of the neighboring base [a', b', c', d']
		###
		neighbor3p: (a, b, c, d, dir) ->
			# if dir is 1 
			# 	if d+1 > @length a, b, c then [a, b, c+1, 0]
			# 	else [a, b, c, d+1]

			# else if dir is -1
			# 	if d-1 < 0 then [a, b, c-1, @length(a, b, c)]
			# 	else [a, b, c, d-1]
			@neighbor a, b, c, d, dir, 1

		###*
		 * Gets the 5' or 3' neighbor of a base at [a, b, c, d] running in the given direction
		 * @param  {Number} a 
		 * @param  {Number} b 
		 * @param  {Number} c 
		 * @param  {Number} d 
		 * @param  {Number} dir Direction of the strand; +1 is 5' -> 3', -1 is 3' -> 5'f
		 * @param  {Number} neighbor Which neighbor; +1 is 3', -1 is 5'
		 * @return {Number[]} Position of the neighboring base [a', b', c', d']
		###
		neighbor: (a, b, c, d, dir, neighbor) ->
			if dir*neighbor is 1
				if d+1 > @length a, b, c then [a, b, c+1, 0]
				else [a, b, c, d+1]
			else if dir*neighbor is -1
				if d-1 < 0 then [a, b, c-1, @length(a, b, c)]
				else [a, b, c, d-1]
				
	###*
	 * @class  vox.lattice.Cubic
	 * Represents a cubic or rectangular lattice
	 * @extends {vox.lattice.Lattice}
	###
	class Cubic extends Lattice
		@_name = 'Cubic'
		@_class: 'vox.lattice.Cubic'
		description: """
		Cubic lattice for 3D single-stranded tile (SST) structures. 8 nt voxels/domains.
		"""
		constructor: () ->
			###*
			 * @cfg {Array} cell
			 * Array containing the dimensions of the rectangular cell
			###
			@cell = @cell ? [50,50,50]

			###*
			 * @cfg {Number} dlen
			 * Length of each cell
			###
			@dlen = @dlen ? 8

			super arguments...

			###*
			 * @property {Array} offsets
			 * Offsets of the center of the cell
			###
			@offsets = @offsets ? (r/2 for r in @cell)

		toJSON: () ->
			_.pick @, 'width', 'height', 'depth', 'offsets', 'cell', 'dlen', '_class'

		pointToLattice: (x, y, z, base=false) -> 
			v = (Math.floor((r + @offsets[i])/@cell[i]) for r,i in [x,y,z])
			d = Math.round(((z+@offsets[2])/@cell[2] % 1) * (@length(v...)-1))
			if base then return v.concat [d]
			else return v

		latticeToPoint: (a, b, c, d) ->
			v = ((r * @cell[i]) - @offsets[i] + @cell[i]/2 for r,i in [a,b,c])
			if d? then v[2] += (@cell[2]/(@length(a,b,c))*d - @cell[2]/2)
			v

		cellFootprint: (a, b, c) ->
			geo = new THREE.Geometry()
			height = -@cell[1]/2

			# build top left, bottom left, top right, bottom right points
			tl = new THREE.Vector3(-@cell[0]/2,height,-@cell[2]/2)
			bl = new THREE.Vector3(-@cell[0]/2,height,+@cell[2]/2)
			tr = new THREE.Vector3(+@cell[0]/2,height,-@cell[2]/2)
			br = new THREE.Vector3(+@cell[0]/2,height,+@cell[2]/2)
			vertices = [ tl, tr, 
						 tr, br,
						 br, bl,
						 bl, tl ]
			geo.vertices.push vertices...

			# build triangular faces
			geo.faces = [ new THREE.Face3(3,1,0), new THREE.Face3(7,5,4)]
			return geo

		cellGeometry: (a, b, c) ->
			if not @geometry?
				@geometry = new THREE.BufferGeometry().fromGeometry new THREE.BoxGeometry( @cell... )
			return @geometry
			
		cellSpline: (a, b, c) ->
			# center = @latticeToPoint(a, b, c)
			# return new THREE.SplineCurve3([ 
			# 	new THREE.Vector3(center[0], center[1], center[2]-@cell[2]), 
			# 	new THREE.Vector3(center[0], center[1], center[2]+@cell[2]) ])
			return new THREE.SplineCurve3([ 
				new THREE.Vector3(0, 0, -@cell[2]/2), 
				new THREE.Vector3(0, 0, +@cell[2]/2) ])


	###*
	 * @class  vox.lattice.Rectangular
	 * Represents a rectangular lattice
	 * @extends {vox.lattice.Lattice}
	###
	class Rectangular extends Cubic
		@_name = 'Rectangular (13nt)'
		@_class = 'vox.lattice.Rectangular'
		description: """
		Rectangular lattice for 3D single-stranded tile (SST) structures. 13 nt voxels/domains.
		"""
		constructor: () ->
			@dlen = @dlen ? 13
			@cell = @cell ? [50, 50, 100]
			super arguments...

	class Hexagonal extends Cubic
		@_name = 'Hexagonal'
		@_class: 'vox.lattice.Hexagonal'
		description: """
		Hexagonal lattice for 3D single-stranded tile (SST) structures. 9 nt voxels/domains.
		"""
		isHexagonal: true
		constructor: () ->
			###*
			 * @cfg {Array} cell
			 * Array containing the dimensions of the rectangular cell
			###
			@cell = @cell ? [50,50,50]

			###*
			 * @cfg {Number} dlen
			 * Length of each cell
			###
			@dlen = @dlen ? 9

			super arguments...

			###*
			 * @property {Array} offsets
			 * Offsets of the center of the cell
			###
			@offsets = @offsets ? (r/2 for r in @cell)

		pointToLattice: (x, y, z, base=false) -> 
			a = Math.floor((x + @offsets[0])/@cell[0])
			b = Math.floor((y + @offsets[1])/@cell[1] - (a % 2)/2 + 1/2)
			c = Math.floor((z + @offsets[2])/@cell[2])
			d = Math.round(((z+@offsets[2])/@cell[2] % 1) * (@length(a,b,c)-1))
			if base then [a,b,c,d] else [a,b,c]

		latticeToPoint: (a, b, c) ->
			x = (a + 1/2) * @cell[0] - @offsets[0]
			y = (b + (a % 2)/2) * @cell[1] - @offsets[1]
			z = (c + 1/2) * @cell[2] - @offsets[2]
			[x,y,z]


	class Honeycomb extends Cubic
		@_name = 'Honeycomb'
		@_class: 'vox.lattice.Honeycomb'
		description: """
		Honeycomb lattice for 3D single-stranded tile (SST) structures. 8 nt voxels/domains.
		"""
		isHoneycomb: true
		constructor: () ->
			###*
			 * @cfg {Array} cell
			 * Array containing the dimensions of the rectangular cell
			###
			@cell = @cell ? [50,50,50]

			###*
			 * @cfg {Number} dlen
			 * Length of each cell
			###
			@dlen = @dlen ? 9

			super arguments...

			###*
			 * @property {Array} offsets
			 * Offsets of the center of the cell
			###
			@offsets = @offsets ? (r/2 for r in @cell)

		pointToLattice: (x, y, z, base=false) -> 
			a = Math.floor((x + @offsets[0])/@cell[0])
			b = Math.round(((y + @offsets[1])/@cell[1] + 1/2) * 2/3)
			c = Math.floor((z + @offsets[2])/@cell[2])
			d = Math.round(((z+@offsets[2])/@cell[2] % 1) * (@length(a,b,c)-1))
			if base then [a,b,c,d] else [a,b,c]

		latticeToPoint: (a, b, c) ->
			x = (a + 1/2) * @cell[0] - @offsets[0]
			y = (Math.floor(b/2*3) - (a % 2)*(1/2 - (b % 2)) ) * @cell[1] - @offsets[1]
			z = (c + 1/2) * @cell[2] - @offsets[2]
			[x,y,z]

		length: (a,b,c) ->
			if c % 4 < 2 then 12 else 9

	###*
	 * @class  vox.lattice.CentralSpline
	 * Represents a lattice defined by a 
	 * [Catmull-Rom](http://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline) 
	 * {@link #spline} on the +x side of the lattice.
	 * @extends {vox.lattice.Lattice}
	###
	class CentralSpline extends Lattice
		@_name = 'Curved Spline'
		@_class: 'vox.lattice.CentralSpline'
		description: """
		Experimental. Curved lattice for 3D single-stranded tile (SST) structures. Base voxel size: 13 nt.
		"""
		experimental: true
		constructor: () ->
			super arguments...
			
			###*
			 * @cfg {Number} 
			 * Length of each domain in the lattice
			###
			@dlen = 13

			###*
			 * @cfg {Array} cell
			 * Array containing the dimensions of the rectangular cell
			###
			@cell = @cell ? [20,20,20]
			###*
			 * @cfg {Array} spline
			 * Array of control points for 3D spline that lattice will follow
			###
			# @theta = @theta ? Math.PI*4
			@theta = @theta ? Math.PI/2
			@steps = @steps ? 20
			scale = 1
			if not @spline? then @spline =
				# curve (x,y) 
				# (new THREE.Vector3(2*@width*@cell[0]*Math.cos(theta), 2*@depth*@cell[2]*Math.sin(theta), 0) for theta in [0...@theta] by (@theta)/@steps)
				
				# curve (x/z)
				(new THREE.Vector3(2*@width*@cell[0]*Math.cos(theta), 0, 2*@depth*@cell[2]*Math.sin(theta)) for theta in [0...@theta] by (@theta)/@steps)
				
				# snake
				# (new THREE.Vector3(scale*@width*@cell[0]*Math.cos(theta), 0, (15*scale*@depth*@cell[2] * theta / (2*Math.PI)) ) for theta in [0...@theta] by (@theta)/@steps)
			
			if _.isArray @spline
				@spline = new THREE.SplineCurve3 @spline

			###*
			 * @cfg {Array}	 up
			 * Vector defining the "up" direction
			###
			# @up = @up ? [0,1,0]
			# @up = new THREE.Vector3(@up...).normalize()

			###*
			 * @property {Array} offsets
			 * Offsets of the center of the cell
			###
			@offsets = @offsets ? (r/2 for r in @cell)

		toJSON: () ->
			_.pick @, 'width', 'height', 'depth', 'offsets', 'cell', 'dlen', '_class'

		###*
		 * Returns the closest "point" t, where 0 < t < 1, along the spline
		 * Adapted from http://bl.ocks.org/mbostock/8027637
		 * @param  {Number} x 
		 * @param  {Number} y 
		 * @param  {Number} z 
		 * @return {Number} t
		###
		closest: (x, y, z) ->
			point = [x, y, z]			
			distance3 = (p) ->
				dx = p.x - point[0]
				dy = p.y - point[1]
				dz = p.z - point[2]
				dx * dx + dy * dy + dz * dz

			pathLength = @spline.getLength()
			segs = 10
			precision = pathLength / segs * .125
			best = undefined
			bestLength = undefined
			bestDistance = Infinity
			scan = undefined
			scanLength = 0
			scanDistance = undefined

			# linear scan for coarse approximation
			while scanLength <= pathLength
				if (scanDistance = distance3(scan = @spline.getPoint(scanLength/pathLength))) < bestDistance
					best = scan
					bestLength = scanLength
					bestDistance = scanDistance
				scanLength += precision

			# binary search for precise estimate
			precision *= .5
			while precision > .5
				before = undefined
				after = undefined
				beforeLength = undefined
				afterLength = undefined
				beforeDistance = undefined
				afterDistance = undefined
				if (beforeLength = bestLength - precision) >= 0 and (beforeDistance = distance3(before = @spline.getPoint(beforeLength/pathLength))) < bestDistance
					best = before
					bestLength = beforeLength
					bestDistance = beforeDistance
				else if (afterLength = bestLength + precision) <= pathLength and (afterDistance = distance3(after = @spline.getPoint(afterLength/pathLength))) < bestDistance
					best = after
					bestLength = afterLength
					bestDistance = afterDistance
				else
					precision *= .5
			
			return bestLength/pathLength

		###*
		 * Gives a spline traversing a particular voxel, as an array with the specified number (`points`) of vectors
		 * @param  {Number} c Lattice number along helical axis
		 * @param  {Number} points Number of points to sample along #spline
		 * @return {THREE.Vector3[]} Array of points
		###
		subspline: (c, points) -> 
			@spline.getPoint(t) for t in @voxelSplinePositions(c, points)

		###*
		 * Gives the position `t` of the voxel at lattice number `c` along the spline, where 0 <= t <= 1.
		 * @param  {Number} c Lattice number along helical axis
		 * @param  {Number} i -1 to give the start position of the voxel, 1 to give the end position, 0 to give the center
		 * @return {Number} t 
		###
		voxelSplinePosition: (c, i) ->
			return t = (c + i) / @depth
			# return t = (c + (i+1) / 2) / @depth
		
		###*
		 * Gives the {@link #voxelSplinePosition position} at several evenly-
		 * spaced `points` along the #spline at lattice number `c`
		 * @param  {Number} c 
		 * @param  {Number} points Number of points to use
		 * @param  {Number} inclusive=true 
		 * `true` to give a list of points that includes the very beginning 
		 * and very end of the cell, `false` to omit the end of the cell 
		 * (gives the same number of points regardless, but changes the spacing)
		 * 
		 * @return {Number[]} 
		 * List of `t`'s for the #spline; call `spline.getPoint(t)` on any 
		 * element of this array to get a vector representing the point 
		###
		voxelSplinePositions: (c, points, inclusive=true) ->
			if inclusive
				return ts = (@voxelSplinePosition(c, (i/(points-1))) for i in [0...points])
			else 
				return ts = (@voxelSplinePosition(c, (i/points)) for i in [0...points])

		pointToLattice: (x,y,z, base=false) -> 
			p = new THREE.Vector3(x,y,z)

			# find closest position along central spline
			t = @closest(x,y,z)
			r = @spline.getPoint(t)
			p.sub(r)

			# decide which z position this falls on
			c = Math.floor(@depth * t)

			# get unit vectors pointing in +x and +y direction
			axis = @spline.getTangent(t).cross(@up).normalize()
			up = @up.clone().normalize()

			# find x-distance by projecting onto axis
			a = +Math.floor(p.clone().dot(axis) / @cell[0])

			# find y-distance by projecting onto up
			b = +Math.floor(p.clone().dot(up) / @cell[1])

			# get base position
			dt = 1/@depth
			d = Math.round((t - (c * dt))/dt * @length(a,b,c))

			if base then return [a,b,c,d]
			else return [a, b, c]

		latticeToPoint: (a, b, c) ->
			# find closest position along central spline
			t = (c+0.5) / @depth
			p = @spline.getPoint(t)

			# get unit vectors pointing in +x and +y direction
			axis = @spline.getTangent(t).cross(@up).normalize()
			up = @up.clone().normalize()

			r = p.add( axis.multiplyScalar((a) * @cell[0]) ).add( up.multiplyScalar((b+0.5) * @cell[1]) )
			return [r.x,r.y,r.z]

		cellFootprint: (a, b, c) ->
			points = 10
			ts = @voxelSplinePositions(c, points)
			v1 = [] # forward points
			v2 = [] # reverse points

			# traverse spline, calculating footprint position on either side (+x and -x) of spline
			for t,i in ts
				p = @spline.getPoint(t)
				axis = @spline.getTangent(t).cross(@up).normalize()
				
				v1.push    p.clone().add(axis.clone().multiplyScalar((a-0.5)*@cell[0]))
				v2.unshift p.clone().add(axis.clone().multiplyScalar((a+0.5)*@cell[0]))

			strip2pieces = vox.utils.strip2pieces

			# build new geometry from vertices
			geo = new THREE.Geometry()
			geo.vertices = strip2pieces(v1.concat(v2))

			# build triangular faces
			vs = geo.vertices.length
			for i in [0...ts.length-1]
				geo.faces.push new THREE.Face3(vs-2-(2*i+1),2*i+1,2*i), new THREE.Face3(vs-2-(2*i+1),vs-2-(2*i+2),2*i+1)

			# center geometry on world origin
			# geo.center()
			geo.applyMatrix new THREE.Matrix4().makeTranslation((-x for x in @latticeToPoint(a,b,c))...)
			return geo

		cellGeometry: (a, b, c) ->
			# get spline through cell
			points = 20
			curve = @cellSpline(a,b,c, points)

			# make rectangular shape to extrude
			shape = new THREE.Shape([
				new THREE.Vector2(-@cell[0]/2,-@cell[1]/2),
				new THREE.Vector2(+@cell[0]/2,-@cell[1]/2),
				new THREE.Vector2(+@cell[0]/2,+@cell[1]/2),
				new THREE.Vector2(-@cell[0]/2,+@cell[1]/2)
			])

			# build geometry that extrudes the shape through the spline
			geo = new THREE.ExtrudeGeometry shape, {extrudePath: curve, steps: points, amount: 100, bevelEnabled: false}
			
			# center geometry on world origin
			point = @latticeToPoint(a,b,c)
			geo.center()
			# geo.computeBoundingBox()
			# geo.applyMatrix new THREE.Matrix4().setPosition(geo.boundingBox.center().multiplyScalar(-1))
			# # geo.applyMatrix new THREE.Matrix4().makeTranslation(-point[0], -point[1], -point[2])
			# geo.computeBoundingBox()
			new THREE.BufferGeometry().fromGeometry(geo)

		cellSpline: (a, b, c, points=10) ->	
			ts = @voxelSplinePositions(c, points)
			point = @latticeToPoint(a,b,c)
			tl = new THREE.Matrix4().makeTranslation(-point[0], -point[1], -point[2])
			spline = for t in ts
				@spline.getPoint(t)
					.add( @spline.getTangent(t).cross(@up).normalize().multiplyScalar((a)*@cell[0]) )
					.add( @up.clone().multiplyScalar((b+0.5)*@cell[1]) )
					.applyMatrix4 tl
			new THREE.SplineCurve3 spline

		length: (a, b, c) ->
			if @isOnLattice a,b,c
				baseLength = @cellSpline(0, 0, c)?.getLength()
				cellLength = @cellSpline(a, b, c)?.getLength()

				Math.floor(@dlen * cellLength/baseLength)

	class WheelSpline extends CentralSpline
		@_class: 'vox.lattice.WheelSpline'
		@_name: 'Circular Spline' 
		constructor: () ->
			super arguments...
			@spline = (new THREE.Vector3(2*@width*@cell[0]*Math.cos(theta), 0, 2*@depth*@cell[2]*Math.sin(theta)) for theta in [0...@theta] by (@theta)/@steps)
			@spline = new THREE.SplineCurve3 @spline

	class SnakeSpline extends CentralSpline
		@_class: 'vox.lattice.SnakeSpline'
		@_name: 'Snake Spline'
		constructor: () ->
			super arguments...
			scale = 1
			@spline = (new THREE.Vector3(scale*@width*@cell[0]*Math.cos(theta), 0, (5*scale*@depth*@cell[2] * theta / (2*Math.PI)) ) for theta in [0...@theta] by (@theta)/@steps)
			@spline = new THREE.SplineCurve3 @spline

	lattices =  
		Cubic: Cubic
		Hexagonal: Hexagonal
		Honeycomb: Honeycomb
		Rectangular: Rectangular
		CentralSpline: CentralSpline
		WheelSpline: WheelSpline
		SnakeSpline: SnakeSpline

	for name, lattice of lattices
		lattice._latticeType = name

	lattices

###*
 * @class vox.dna
 * @singleton
 * @static
###
vox.dna = 
	###*
	 * @class vox.dna.dimensions
	 * @singleton
	 * @static
	###
	dimensions:
		###*
		 * @class vox.dna.dimensions.bDNA
		 * @singleton
		 * @static
		 * All values in nanometers
		###
		bDNA:
			###*
			 * @property {Number} diameter
			 * Diameter of the helix (nm)
			###
			diameter: 2e-9
			###*
			 * @property {Number} rise
			 * Rise per bp of the helix (nm)
			###
			rise: 0.332e-9
			###*
			 * @property {Number} bpPerTurn
			 * Base pairs per turn
			###
			bpPerTurn: 10.5

	###*
	 * @class vox.dna.Base
	 * @abstract
	 * This interface defines how individual bases are represented throughout 
	 * the NanoBricks software.
	###
	###*
	 * @property {Array} pos 
	 * 4-component array giving the position of this base. The 4 components 
	 * should be: `[x, y, z1, z2]`, where `x` and `y` give the helix position, 
	 * `z1` gives the position of the domain/voxel along the helix, and `z2` 
	 * gives the position of the base within the domain. `z2` may be given as 
	 * `-1` as well, in order to specify that the base is off the lattice.
	###
	###*
	 * @property {1/-1} dir
	 * Gives the direction of the base with respect to the helical axis (the 
	 * +z direction of the lattice). If `dir` is +1, then the base is on the
	 * strand which is aligned with the +z direction (the 3' end is towards
	 * the positive side). If `dir` is -1, the base is on the strand which is 
	 * anti-aligned (the 5' end is towards the positive side):
	 *
	 *     ------------------> +z
	 *     5'-b-3'    3'-b-5'
	 *       +1         -1
	###
	###*
	 * @property {String} seq 
	 * Gives the sequence of this base, if known. When sequences are 
	 * generated, this base will be treated as locked if a base is given here.
	 * If this property is falsy, then the sequence will be assigned by the 
	 * {@link C3D.models.SequenceSet sequence set}.
	###

	# ------------------------------------------------------------------------

	###*
	 * @class  vox.dna.Strand
	 * @abstract
	 * This interface describes how strands are represented throughout the 
	 * NanoBricks software.
	###
	###*
	 * @property {vox.dna.Base[]} routing
	 * List of bases describing the routing of the strand throughout the 
	 * lattice. Note that the bases need _not_ be adjacent; non-adjacent bases
	 * will imply a crossover.
	###
	###*
	 * @property {'X'/'Y'} plane 
	 * Indicates whether this strand is in the XZ or YZ plane.
	 * Note that this property is set optionally by translation schemes, so 
	 * for manually created strands it may be undefined.
	###
	###*
	 * @property {1/-1} dir 
	 * Indicates whether this strand is aligned (5' -> 3') with respect to the
	 * {@link #plane}, or anti-aligned (3' -> 5'). Of course, most of the strand will
	 * probably travel along the Z axis (perpendicular to the X or Y axis), so 
	 * generally, this property  refers to the direction of the crossover; for 
	 * instance, for an X strand:
	 *
	 *     +x ^ 
	 *        | /------>  3'  vs /------- 5'
	 *        | \-------  5'     \------> 3'
	 *     dir:    +1                -1
	 *
	 * Note that this property is set optionally by translation schemes, so 
	 * for manually created strands it may be undefined.
	###

	###*
	 * @class vox.dna.utils
	 * @singleton
	 * @static
	 * 
	 * Utilities associated with DNA strands 
	###
	utils: do () ->

		###*
		 * @method  insert
		 * 
		 * Modifies a `routing` to insert a sequence of bases at the given `index`
		 * `generator` can be used to modify the sequence of bases appropriately.
		 * 
		 * @param  {vox.dna.Base[]} routing List of base objects
		 * @param  {Number} index Index at which to insert bases
		 * @param  {String/Number/Array} sequence String to insert a given sequence, number to insert a number of bases
		 * @param  {Object} options=null Options to be applied to all bases
		 * 
		 * @param  {Function} generator=null 
		 * Function to be called for each generated base; this function is passed the 
		 * options object for that base, as well as the value of `sequence` for the 
		 * particular base. This depends on the type of `sequence`; if `sequence` is a 
		 * String or Array, one character or element will be passed for each base. If `sequence` 
		 * is a Number, then the generator will count up from zero to `sequence`, exclusive. 
		 * 
		 * @param  {Object} generator.options Options object for a particular base
		 * @param  {String/Number/Mixed} generator.value Value of `sequence` for the given base 
		 * @param  {Object} generator.return Modified options object for the base
		 * 
		 * @return {vox.dna.Base[]} Modified routing
 		###
		insert = (routing, index, sequence, options=null, generator=null) ->
			generator ?= _.identity

			dir = routing[index].dir
			pos = routing[index].pos[0...2]

			bases = vox.dna.utils.domains.makeBases sequence, options, (opt, i) ->
				generator base(pos.concat([-1]), dir, opt),

			routing.splice index, 0, bases...
			routing

		###*
		 * Modifies a `routing` to extend the given `end` of the strand
		 * `generator` can be used to modify the sequence of bases appropriately.
		 * 
		 * @param  {vox.dna.Base[]} routing List of base objects
		 * @param  {String/Number/Array} sequence String to insert a given sequence, number to insert a number of bases
		 * @param {Number} end Which end of the strand to insert the sequence; +1 for 3', -1 for 5'
		 * @param  {Object} options=null Options to be applied to all bases
		 * 
		 * @param  {Function} generator=null 
		 * Function to be called for each generated base; this function is passed the 
		 * options object for that base, as well as the value of `sequence` for the 
		 * particular base. This depends on the type of `sequence`; if `sequence` is a 
		 * String or Array, one character or element will be passed for each base. If `sequence` 
		 * is a Number, then the generator will count up from zero to `sequence`, exclusive. 
		 * 
		 * @param  {Object} generator.options Options object for a particular base
		 * @param  {String/Number/Mixed} generator.value Value of `sequence` for the given base 
		 * @param  {Object} generator.return Modified options object for the base
		 * 
		 * @return {vox.dna.Base[]} Modified routing
		###
		extend = (routing, sequence, end=1, options=null, generator=null) ->
			generator ?= _.identity
			if routing.length is 0 then return routing

			index = if end is +1 then (routing.length-1) else if end is -1 then 0

			dir = routing[index].dir
			pos = routing[index].pos[0...2]

			bases = vox.dna.utils.domains.makeBases sequence, options, (opt, i) ->
				generator base(pos.concat([-1]), dir, opt),

			if      end is +1 then routing.splice index+1, 0, bases...
			else if end is -1 then routing.splice index,   0, (bases.reverse())...
			routing

		###*
		 * Removes bases from a given `routing`
		 * @param  {vox.dna.Base[]} routing List of base objects
		 * @param  {Number} index Index at which to remove bases
		 * @param  {Number} length Number of bases to remove
		 * @return {vox.dna.Base[]} Modified routing
		###
		remove = (routing, index, length) ->
			if index < 0 then index = routing.length+index
			if length < 0 then [index, length] = [index+length, Math.abs(length)]
			routing.splice index, length
			routing

		###*
		 * Truncates the given `routing` by the requested amount
		 * @param  {vox.dna.Base[]} routing
		 * @param  {Number} length Number of bases to delete
		 * @param  {1/-1} [end=1] Which end to remove from: 1 for 5', -1 for 3'
		 * @return {vox.dna.Base[]} Modified routing
		###
		truncate = (routing, length, end=null) ->
			if not end? 
				end = Math.sign(length)

			if end is +1 then remove routing, routing.length-1, length
			else if end is -1 then remove routing, 0, length

		###*
		 * Displaces the bases in a given routing
		 * @param  {vox.dna.Base[]} routing List of base objects
		 * @param  {Number} dx
		 * @param  {Number} dy
		 * @param  {Number} dz1=0
		 * @param  {Number} dz2=0
		 * @return {vox.dna.Base[]} Modified routing
		###
		move = (routing, dx, dy, dz1=0, dz2=0) ->
			for r in routing
				[x, y, z1, z2] = r.pos
				r.pos = [x + dx,y + dy,z1 + dz1,z2 + dz2]
			routing

		# ---------------------------------------------------------------------

		###*
		 * Generates a series of bases according to the passed sequence
		 * `generator` can be used to modify the sequence of bases appropriately.
		 * 
		 * @param  {String/Number/Array} sequence 
		 * `String` to generate a given sequence, `Number` to insert a number of bases,
		 * `Array` to build a custom set of bases
		 * 
		 * @param  {Object} options=null Options to be applied to all bases
		 * 
		 * @param  {Function} generator=null 
		 * Function to be called for each generated base; this function is passed the 
		 * options object for that base, as well as the value of `sequence` for the 
		 * particular base. This depends on the type of `sequence`; if `sequence` is a 
		 * String or Array, one character or element will be passed for each base. If `sequence` 
		 * is a Number, then the generator will count up from zero to `sequence`, exclusive. 
		 * 
		 * @param  {Object} generator.options Options object for a particular base
		 * @param  {String/Number/Mixed} generator.value Value of `sequence` for the given base 
		 * @param  {Object} generator.return Modified options object for the base
		 * 
		 * @return {Object[]} Sequence of bases
		###
		makeBases = (sequence, options=null, generator=null) ->
			options ?= {}
			generator ?= _.identity

			if _.isString sequence
				bases = sequence.split ''
				for base in bases
					generator _.extend({ seq: base }, options), base

			else if _.isNumber sequence
				for i in [0..sequence]
					generator _.clone(options), i

			else if _.isArray sequence
				for i in sequence 
					generator _.clone(options), i

		###*
		 * Builds a base at position pos, in direction dir, with options
		 * @param  {Number[]} pos Position [a, b, c]
		 * @param  {Number} dir Direction: +1 is 5' -> 3', -1 is 3' to 5'
		 * @param  {Object} options Hash of properties to apply to the base
		 * @return {Object} base
		###
		base = (pos, dir, options) -> _.extend {pos: pos, dir: dir}, options

		###*
		 * Returns a list of bases within the same voxel
		 * @param  {Number[]} pos Position [a, b, c]
		 * @param  {Number} dir Direction: +1 is 5' -> 3', -1 is 3' to 5'
		 * @param  {Number} dlen=domain_length Number of bases to create
		 * @param  {Object} options Hash of properties to apply to each base
		 * @return {Object[]} bases
		###
		seq = (pos, dir, dlen, options) ->
			options = options ? {}
			# if dir is 1 
			# 	for i in [0...dlen]
			# 		base pos.concat([i]), dir, options
			# else
			# 	for i in [dlen-1..0] by -1
			# 		base pos.concat([i]), dir, options
			range = if dir is 1 then _.range(0, dlen) else _.range(dlen-1, -1, -1)
			makeBases range, options, (opt, i) ->
				base pos.concat([i]), dir, opt

		###*
		 * Returns a list of poly-T bases within the same voxel
		 * @param  {Number[]} pos Position [a, b, c]
		 * @param  {Number} dir Direction: +1 is 5' -> 3', -1 is 3' to 5'
		 * @param  {Number} dlen=domain_length Number of bases to create
		 * @return {Object[]} bases
		###
		polyT = (pos, dir, dlen) -> seq(pos, dir, dlen, {seq: 'T'})

		###*
		 * Returns a list of domain bases within the same voxel
		 * @param  {Number[]} pos Position [a, b, c]
		 * @param  {Number} dir Direction: +1 is 5' -> 3', -1 is 3' to 5'
		 * @param  {Number} dlen=domain_length Number of bases to create
		 * @return {Object[]} bases
		###		
		dom = (pos, dir, dlen=domain_length) -> seq(pos, dir, dlen, {})

		###*
		 * Builds an off-lattice spacer
		 * @param  {Number} len Length of the spacer
		 * @param  {Object} options Hash of options to apply to each base in the spacer
		 * @return {Object[]} bases
		###
		spacer = (pos, dir, len, options) -> 
			options = options ? {} 
			makeBases len, options, (opt) -> 
				base pos.concat([-1]), dir, opt


		ns = {
			###*
			 * @property {Object} strands
			 * Convenience namespace for the following methods:
			 * 
			 * - {@link #insert}
			 * - {@link #extend}
			 * - {@link #truncate}
			 * - {@link #move}
			###
			strands: 
				insert : insert
				extend : extend
				remove : remove
				truncate: truncate
				move : move

			###*
			 * @property {Object} domains
			 * Convenience namespace for the following methods:
			 *
			 * - {@link #makeBases}
			 * - {@link #base}
			 * - {@link #seq}
			 * - {@link #polyT}
			 * - {@link #dom}
			 * - {@link #spacer}
			###
			domains: 
				makeBases : makeBases
				base : base
				seq : seq
				polyT : polyT
				dom : dom
				spacer : spacer
		}
		return _.extend ns, ns.domains, ns.strands


###*
 * @class vox.compilers
 * @static
 * @singleton
 * Provides translation schemes for converting voxels to strands
###
vox.compilers = 

	keScience2012hex: (voxels, lattice, options) ->
		{ tiles } = vox.compilers.utils(voxels, lattice, { dlen: 8 })

		(i,j,k,strands) -> 
			new_strands = switch (Math.abs(i % 2) + Math.abs(j % 2))

				# 4  2
				#  \ / 
				#   O 
				#  /|\
				# 5 0 1
				when 1 then switch k % 6
					when 0 then [tiles.half(i,j,k, i,j-1,k), tiles.straight i,j,k, 6, +1]
					when 1 then [tiles.half i,j,k, i+1,j-1,k]
					when 2 then [tiles.half i,j,k, i+1,j,k]
					when 3 then [tiles.straight i,j,k, 1, -1]
					when 4 then [tiles.half i,j,k, i-1,j-1,k]
					when 5 then [tiles.half i,j,k, i-1,j,k]

				when 0,2 then switch k % 6
					when 0 then [tiles.straight i,j,k, 6, -1]
			
			if (new_strands?.length > 0) then strands.push _.compact(new_strands)...

	keScience2012honey: (voxels, lattice, options) ->
		{ tiles } = vox.compilers.utils(voxels, lattice, { dlen: 8 })

		(i,j,k,strands) -> 
			strand = switch (Math.abs(i % 2) + Math.abs(j % 2))
				when 1 then switch k % 4
					# green
					when 0 then tiles.oneway i,j,k, 'X', -1
					# black
					when 2 then tiles.oneway i,j,k, 'X', +1

				when 0, 2 then switch k % 4
					# purple
					when 1 then tiles.oneway i,j,k, 'Y', -1
					# blue
					when 3 then tiles.oneway i,j,k, 'Y', -1
			if strand? then strands.push strand

	###*
	 * Voxel compiler for the translation scheme in Ke et al., Science 2012; 8nt 3D SST
	 * @param  {ndarray} voxels
	 * @param {vox.lattice.Lattice} lattice   
	 * @return {vox.compilers.Compiler}
	###
	keScience2012: (voxels, lattice, options) ->
		
		# Utility functions
		{ tiles } = vox.compilers.utils(voxels, lattice, options, { dlen: 8 })

		# ---------------------------------------------------------------------

		compiler = 
			before: (strands) ->

			# Main iterator
			iterator: (i,j,k,strands) ->
				strand = switch (Math.abs(i % 2) == Math.abs(j % 2))

						# if i and j are both even or both odd (A)
						when true then switch k % 4
							# Y- /
							#  */ /
							#   |/
							when 0 then tiles.oneway i,j,k, 'Y', -1, -1
								
							# Y+ /
							#   / /
							#   |/*
							when 2 then tiles.oneway i,j,k, 'Y', +1, -1

						# if i xor j is odd  (B)
						when false then switch k % 4
							# X-
							#   / /
							#  /_/*
							when 1 then tiles.oneway i,j,k, 'X', -1, -1

							# X+
							#   / /
							# */_/
							when 3 then tiles.oneway i,j,k, 'X', +1, -1

				if strand? then strands.push strand

			after: (strands) ->

	###*
	 * Voxel compiler for the translation scheme developed by Luvena in 2014; 13nt 3D SST
	 * The only difference from #keScience2012 is the periodicity of the Y-strands
	 * @param  {ndarray} voxels
	 * @param {vox.lattice.Lattice} lattice   
	 * @return {vox.compilers.Compiler}
	###
	ong13nt2014: (voxels, lattice, options) ->
		
		# Utility functions
		{ tiles } = vox.compilers.utils(voxels, lattice, options, { dlen: 13 })

		# ---------------------------------------------------------------------

		compiler = 

			before: (strands) ->
			# Main iterator
			iterator: (i,j,k,strands) ->
				strand = switch (Math.abs(i % 2) == Math.abs(j % 2))

						# if i and j are both even or both odd (A)
						when true then switch k % 4
							# Y- /
							#  */ /
							#   |/
							when 0 then tiles.oneway i,j,k, 'Y', -1, -1
								
							# Y+ /
							#   / /
							#   |/*
							when 2 then tiles.oneway i,j,k, 'Y', +1, -1

						# if i xor j is odd  (B)
						when false then switch k % 4
							# X-
							#   / /
							#  /_/*
							when 1 then tiles.oneway i,j,k, 'X', -1, -1

							# X+
							#   / /
							# */_/
							when 3 then tiles.oneway i,j,k, 'X', +1, -1

				if strand? then strands.push strand

			after: (strands) ->

	###*
	 * Voxel compiler for the "alternating"/"symmetric crossover" translation scheme 
	 * in Ke et al., Science 2012 (Fig. S7.4); 8nt 3D SST
	 * @param  {ndarray} voxels
	 * @param {vox.lattice.Lattice} lattice   
	 * @return {vox.compilers.Compiler}
	###
	keScience2012alt: (voxels, lattice, options) ->
		
		# Utility functions
		{ tiles } = vox.compilers.utils(voxels, lattice, { dlen: 8 })

		# ---------------------------------------------------------------------

		compiler = 
			before: (strands) ->

			# Main iterator
			iterator: (i,j,k,strands) ->

				new_strands = switch Math.abs(j % 2)
					# even rows (A, B)
					when 0, 2 then switch i % 2
						# (A)
						when 0 then switch k % 4
							when 1 then [tiles.symmetric i,j,k, 'X', +1, +1]
							when 3 then [tiles.symmetric i,j,k, 'X', +1, -1]

						# (B); no strands have 5' ends here
						when 1 then null

					# odd rows (C, D)
					when 1 then switch i % 2
						# (C); instead, there are twice as many domains 
						# on these helices
						when 0 then switch k % 4
							when 0 then [tiles.symmetric(i,j,k, 'X', +1, -1), tiles.symmetric(i,j,k, 'Y', -1, +1)]
							when 2 then [tiles.symmetric(i,j,k, 'X', -1, -1), tiles.symmetric(i,j,k, 'Y', +1, +1)]

						# (D) 
						when 1 then switch k % 4
							when 1 then [tiles.symmetric i,j,k, 'Y', -1, -1]
							when 3 then [tiles.symmetric i,j,k, 'Y', +1, -1]

				if (new_strands?.length > 0) then strands.push _.compact(new_strands)...

			after: (strands) ->

	###*
	 * Voxel compiler for the translation scheme developed by Luvena in 2014; 13nt 3D SST
	 * with alternating crossovers.
	 * The only difference from #keScience2012alt is the periodicity of the Y-strands
	 * @param  {ndarray} voxels
	 * @param {vox.lattice.Lattice} lattice   
	 * @return {vox.compilers.Compiler}
	###
	ong13nt2014alt: (voxels, lattice, options) ->
		
		# Utility functions
		{ tiles } = vox.compilers.utils(voxels, lattice, options, { dlen: 13 })

		# ---------------------------------------------------------------------

		# ---------------------------------------------------------------------

		compiler = 
			before: (strands) ->

			# Main iterator
			iterator: (i,j,k,strands) ->

				new_strands = switch Math.abs(j % 2)
					# even rows (A, B)
					when 0, 2 then switch i % 2
						# (A)
						when 0 then switch k % 4
							when 1 then [tiles.symmetric i,j,k, 'X', +1, +1]
							when 3 then [tiles.symmetric i,j,k, 'X', +1, -1]

						# (B); no strands have 5' ends here
						when 1 then null

					# odd rows (C, D)
					when 1 then switch i % 2
						# (C); instead, there are twice as many domains 
						# on these helices
						when 0 then switch k % 4
							when 0 then [tiles.symmetric(i,j,k, 'X', +1, -1), tiles.symmetric(i,j,k, 'Y', +1, +1)]
							when 2 then [tiles.symmetric(i,j,k, 'X', -1, -1), tiles.symmetric(i,j,k, 'Y', -1, +1)]

						# (D) 
						when 1 then switch k % 4
							when 1 then [tiles.symmetric i,j,k, 'Y', +1, -1]
							when 3 then [tiles.symmetric i,j,k, 'Y', -1, -1]

				if (new_strands?.length > 0) then strands.push _.compact(new_strands)...

			after: (strands) ->



	###*
	 * Factory function that returns a hash of utility functions for use in 
	 * translation schemes. The utility functions are described in vox.compilers.Utils
	 * @param  {ndarray} voxels Array of voxels
	 * @param  {vox.lattice.Lattice} lattice Lattice to be used by the translation scheme
	 * @param  {Object} opt Hash of options to be available to the utility functions
	 * @param {Object} opt.dlen Default length of a single domain
	 * @return {vox.compilers.Utils} Utility functions
	###
	utils: (voxels, lattice, opts...) ->

		###*
		 * @class  vox.compilers.Utils
		 * @abstract
		 * This interface describes the utility functions returned by the 
		 * vox.compilers#utils factory function. To access these utility 
		 * functions within a {@link vox.compiler translation scheme}, it's
		 * recommended that you call vox.compiler#utils with
		 * the {@link ndarray} of `voxels`, 
		 * the {@link vox.lattice.Lattice lattice}, and any options. You'll
		 * then get an instance of this class which you can use:
		 *
		 *     utils = vox.compiler.utils voxels, lattice, { dlen: 8 }
		 *     { has, tiles } = utils
		 *     
		 *     iterator = (i,j,k, strands) ->
		 *         if has i, j, k then tiles.oneway i, j, k, 'X', +1
		 *         # etc.
		 *
		 * 
		###

		# Constants
		
		opt = _.defaults({},opts...)

		# length of a domain
		domain_length = opt?.dlen ? 13
		crystal = opt?.crystal ? null

		# ---------------------------------------------------------------------
		# Utility functions

		###*
		 * Resolves a position according to the crystal map
		 * @param  {Number} i 
		 * @param  {Number} j 
		 * @param  {Number} k 
		 * @return {Array[]} `[i', j', k']`
		###
		res = vox.utils.periodicWrap crystal


		###*
		 * Returns true if `pos` is on the lattice and a voxel exists there
		 * @param  {Number[]} pos Postion [a, b, c]
		 * @return {Boolean} 
		###
		has = (x,y,z) ->
			if x.length? then [x,y,z] = x
			[x,y,z] = res x,y,z
			return (0 <= x < voxels.shape[0]) and 
				(0 <= y < voxels.shape[1]) and 
				(0 <= z < voxels.shape[2]) and 
				voxels.get(x,y,z)?

		enclosed = (x,y,z) ->
			has(x+1,y,z) and has(x-1,y,z) and
			has(x,y+1,z) and has(x,y-1,z) and
			has(x,y,z+1) and has(x,y,z-1)

		# sums elements of `list`
		sum = (list) -> 
			_.reduce list, ((x,y) -> x+y), 0

		# ---------------------------------------------------------------------
		# Bases and domains

		###*
		 * @property {Object} domains
		 * Convenience reference to vox.dna.utils#domains
		###
		domains = vox.dna.utils.domains

		###*
		 * @property {Object} domains
		 * Convenience reference to vox.dna.utils#strands
		###
		strands = vox.dna.utils.strands

		###*
		 * @inheritdoc vox.dna.utils#polyT
		###
		polyT = (pos, dir, dlen=null) -> 
			if not dlen? then dlen = lattice.length pos...
			domains.polyT res(pos...),dir, dlen

		###*
		 * @inheritdoc vox.dna.utils#dom
		###
		dom = (pos, dir, dlen=null) -> 
			if not dlen? then dlen = lattice.length pos...
			domains.dom res(pos...),dir, dlen

		# ---------------------------------------------------------------------
		# Strands and tiles

		###*
		 * makes a strand from a list of domains
		 * @param  {Array[]} domains List of lists of bases
		 * @param  {Object} options Hash of options to apply to the strand
		 * @return {vox.dna.Strand} strand
		###
		makeStrand = (domains, options) -> _.extend options, {routing: _.cat(domains...) }

		###*
		 * This function examines the pattern of four adjacent voxels and  
		 * generates a U-shaped strand with some combination of domains and 
		 * poly-T protectors, according to the logic of Fig. S32.
		 *
		 * This function can be used for one-way or symmetric (alternating)
		 * crossover tiles; the `dir` parameter controls where the crossover
		 * goes: (^ = 3' end)
		 *  
		 *             ^          __
		 *      v2 /  / v4   v1 /  / v3
		 *     v1 /__/ v3   v2 /  / v4
		 *         +1          -1 v
		 * 
		 * The domains will always be ordered, 5' -> 3': v2, v1, v3, v4
		 * 
		 * @param  {Array} v1 Position of voxel v1
		 * @param  {Array} v2 Position of voxel v2
		 * @param  {Array} v3 Position of voxel v3
		 * @param  {Array} v4 Position of voxel v4
		 * @param {1/-1} dir Whether the crossover should be on the +z or -z side
		 * @return {Array} Strand object
		###
		buildU = (v1, v2, v3, v4, dir=1) ->

			# voxel/domain layout:
			#  v1  v2
			# /======   5'
			# \======>  3'
			#  v3  v4
			
			# directionality:
			# +1 = forward on the helical axis
			# -1 = backward on the helical axis
			# 
			#    >  /  -
			#   >  /  <
			#  +  /  <
			#  
			# a normal, full tile has the following directionality
			# 
			#  - /  / +
			# - /__/ +
			# 
			# directionality is necessary because domains in a strand are always 
			# stored 5' to 3'; this lets us determine crossovers, complementarity
			# for partial tiles 

			# branch on how many voxels are present, then follow 15 conditions
			# in Fig. S32. 
			# === : voxel present
			# --- : voxel absent; replace with poly-T
			# 
			# 5' -> 3' ordering: v2, v1, v3, v4
			doms = switch has(v1) + has(v2) + has(v3) + has(v4)
				# /====== 
				# \======>
				when 4 then [dom(v2,+dir), dom(v1,+dir), dom(v3,-dir), dom(v4,-dir)]
				when 3 then switch
					# /===---
					# \======>
					when ! has(v2) then [polyT(v2,+dir), dom(v1,+dir), dom(v3,-dir), dom(v4,-dir)]

					# /---===
					# \======>
					when ! has(v1) then [dom(v2,+dir), polyT(v1,+dir), dom(v3,-dir), dom(v4,-dir)]
					
					# /======
					# \---===>
					when ! has(v3) then [dom(v2,+dir), dom(v1,+dir), polyT(v3,-dir), dom(v4,-dir)]

					# /======
					# \===--->
					when ! has(v4) then [dom(v2,+dir), dom(v1,+dir), dom(v3,-dir), polyT(v4,-dir)]
					
				when 2 then switch
					# /===---
					# \===--->
					when has(v1) and has(v3) then [polyT(v2,+dir), dom(v1,+dir), dom(v3,-dir), polyT(v4,-dir)]

					# /---===
					# \---===>
					when has(v2) and has(v4) then [dom(v2,+dir), polyT(v1,+dir), polyT(v3,-dir), dom(v4,-dir)]
					
					# /======
					when has(v1) and has(v2) then [dom(v2,+dir), dom(v1,+dir),]
					
					# \======>
					when has(v3) and has(v4) then [dom(v3,-dir), dom(v4,-dir)]
					
					# /===---
					# \---===>
					when has(v1) and has(v4) then [polyT(v2,+dir), dom(v1,+dir), polyT(v3,-dir), dom(v4,-dir)]
					
					# /---===
					# \===--->
					when has(v2) and has(v3) then [dom(v2,+dir), polyT(v1,+dir), dom(v3,-dir), polyT(v4,-dir)]
				when 1 then switch
					# /===---
					when has(v1) then [polyT(v2,+dir), dom(v1,+dir)]

					# /---===
					when has(v2) then [dom(v2,+dir), polyT(v1,+dir)]

					# \===--->
					when has(v3) then [dom(v3,-dir), polyT(v4,-dir)]

					# \---===>
					when has(v4) then [polyT(v3,-dir), dom(v4,-dir)]
				else null
			
			# return if doms then _.cat(doms.reverse()...) else null
			return if doms then _.cat(doms...) else null

		###*
		 * This function examines the pattern of two adjacent voxels and  
		 * generates a U-shaped strand with some combination of domains and 
		 * poly-T protectors, according to the logic of Fig. S32.
		 *
		 * This function can be used for one-way or symmetric (alternating)
		 * crossover tiles; the `dir` parameter controls where the crossover
		 * goes: (^ = 3' end)
		 *  
		 *            ^         __
		 *     v1 /__/ v2   v1 /  / v2
		 *         +1          -1 v
		 * 
		 * The domains will always be ordered, 5' -> 3': v1, v2
		 * 
		 * @param  {Array} v1 Position of voxel v1
		 * @param  {Array} v2 Position of voxel v2
		 * @param {1/-1} dir Whether the crossover should be on the +z or -z side
		 * @return {Array} Strand object
		###
		buildUHalf = (v1, v2, dir=1) ->

			# voxel/domain layout:
			#  v1 
			# /===   5'
			# \===>  3'
			#  v2 
			
			# directionality:
			# +1 = forward on the helical axis
			# -1 = backward on the helical axis
			# 
			#    >  /  -
			#   >  /  <
			#  +  /  <
			#  
			# a normal, full tile has the following directionality
			# 
			#  - /  / +
			# - /__/ +
			# 
			# directionality is necessary because domains in a strand are always 
			# stored 5' to 3'; this lets us determine crossovers, complementarity
			# for partial tiles 

			# branch on how many voxels are present, then follow 15 conditions
			# in Fig. S32. 
			# === : voxel present
			# --- : voxel absent; replace with poly-T
			# 
			# 5' -> 3' ordering: v2, v1, v3, v4
			doms = switch has(v1) + has(v2)
				# /=== 
				# \===>
				when 2 then [dom(v1,-dir), dom(v2,+dir)]
				when 1 then switch
					when has v1 then [dom(v1, -dir)]
					when has v2 then [dom(v2, +dir)]
			
			return if doms then _.cat(doms...) else null

		###*
		 * This function examines the pattern of four adjacent voxels and  
		 * generates a Z-shaped strand with some combination of domains and 
		 * poly-T protectors, following similar logic to Fig. S32.
		 *
		 * The `dir` parameter controls overall orientation of the strand with
		 * respect to the Z-axis: 
		 *
		 *     -------------------------> +z
		 *     
		 *          v3 v4    v4 v3
		 *          /====>   <====\
		 *     ====/               \====
		 *     v2 v1                v1 v2
		 *
		 * You must still pass v1, v2, v3, and v4 in the correct order.
		 * The domains will always be ordered, 5' -> 3': v2, v1, v3, v4
		 * 
		 * @param  {Array} v1 Position of voxel v1
		 * @param  {Array} v2 Position of voxel v2
		 * @param  {Array} v3 Position of voxel v3
		 * @param  {Array} v4 Position of voxel v4
		 * @param {1/-1} dir Whether the crossover should be on the +z or -z side
		 * @return {Array} Strand object
		###
		buildZ = (v1, v2, v3, v4, dir=1) ->

			# voxel/domain layout:
			#            v3 v4
			#           /=====> 3'
			# 5' ======/
			#    v2 v1

			# branch on how many voxels are present, then follow 15 conditions
			# in Fig. S32. 
			# === : voxel present
			# --- : voxel absent; replace with poly-T
			# 
			# 5' -> 3' ordering: v2, v1, v3, v4
			doms = switch has(v1) + has(v2) + has(v3) + has(v4)
				#      /====>
				# ====/
				when 4 then [dom(v2,+dir), dom(v1,+dir), dom(v3,+dir), dom(v4,+dir)]
				when 3 then switch
					#      /====>
					# --==/
					when ! has(v2) then [polyT(v2,+dir), dom(v1,+dir), dom(v3,+dir), dom(v4,+dir)]

					#      /====>
					# ==--/
					when ! has(v1) then [dom(v2,+dir), polyT(v1,+dir), dom(v3,+dir), dom(v4,+dir)]
					
					#      /--==>
					# ====/
					when ! has(v3) then [dom(v2,+dir), dom(v1,+dir), polyT(v3,+dir), dom(v4,+dir)]

					#      /==-->
					# ====/
					when ! has(v4) then [dom(v2,+dir), dom(v1,+dir), dom(v3,+dir), polyT(v4,+dir)]
					
				when 2 then switch
					#      /==-->
					# --==/
					when has(v1) and has(v3) then [polyT(v2,+dir), dom(v1,+dir), dom(v3,+dir), polyT(v4,+dir)]

					#      /--==>
					# ==--/
					when has(v2) and has(v4) then [dom(v2,+dir), polyT(v1,+dir), polyT(v3,+dir), dom(v4,+dir)]
					
					# ====/
					when has(v1) and has(v2) then [dom(v2,+dir), dom(v1,+dir),]
					
					#      /====>
					when has(v3) and has(v4) then [dom(v3,+dir), dom(v4,+dir)]
					
					#      /--==>
					# --==/
					when has(v1) and has(v4) then [polyT(v2,+dir), dom(v1,+dir), polyT(v3,+dir), dom(v4,+dir)]
					
					#      /==-->
					# ==--/
					when has(v2) and has(v3) then [dom(v2,+dir), polyT(v1,+dir), dom(v3,+dir), polyT(v4,+dir)]
				when 1 then switch
					# --==/
					when has(v1) then [polyT(v2,+dir), dom(v1,+dir)]

					# ==--/
					when has(v2) then [dom(v2,+dir), polyT(v1,+dir)]

					#      /==-->
					when has(v3) then [polyT(v3,+dir), dom(v4,+dir)]

					#      /--==>
					when has(v4) then [dom(v3,+dir), polyT(v4,+dir)]
				else null
			
			return if doms then _.cat(doms...) else null


		half = (i0,j0,k0, i1, j1, k1, dir=1) ->
			block = buildUHalf [i0, j0, k0], [i1, j1, k1], dir
			if block? then { routing: block, align: dir, plane: 'X' }
			else null

		###*
		 * Generates a U-shaped tile at the position `i,j,k` in the lattice. Note that 
		 * `i,j,k` refers to the  the `v1` position, as in:
		 *
		 *       v1  v2
		 *     /========  5'
		 *     \========> 3'
		 *       v3  v4
		 *
		 *
		 * Here are examples that demonstrate the meaning of the `plane`, 
		 * `align`, and `zAlign` arguments:
		 *
		 *                                   ^            
		 *                     ^            /             
		 *         y        / /            / /            
		 *         |_x   * /_/             |/ *           
		 *       z/    'X', +1, +1      'Y', +1, +1       
		 *                                                
		 *                                                
		 *                   ^              / ^           
		 *         y        / /          * / /            
		 *         |_x     /_/ *           |/             
		 *       z/    'X', -1, +1      'Y', -1, +1       
		 *                                                
		 *                   __            * /|           
		 *         y      * / /             / /           
		 *         |_x     / /               /            
		 *       z/          v              v             
		 *             'X', +1, -1      'Y', +1, -1       
		 *                                                
		 *                   __              /|           
		 *         y        / / *           / / *         
		 *         |_x     / /             v /            
		 *       z/        v                                
		 *             'X', - 1, -1     'Y', -1, -1       
		 *                                                
		 *     * = [i, j, k]   ^ / v = 3' end             
		 * 
		 * @param  {Number} i 
		 * @param  {Number} j 
		 * @param  {Number} k 
		 * @param  {"X"/"Y"} plane Plane of the strand (`"X"` for XZ or `"Y"` for YZ)
		 * @param  {1/-1} align Direction of the crossover with respect to the plane axis
		 * @param  {1/-1} zAlign=1 Position of the crossover with respect to the Z axis
		 * @return {vox.dna.Strand} 
		###
		ushape = (i,j,k, plane, align, zAlign=1) ->
			dz = -zAlign
			block = switch plane
				when 'X'
					dx = align
					buildU [i,j,k],[i,j,k+dz], [i+dx,j,k],[i+dx,j,k+dz], zAlign
				when 'Y'
					dy = align
					buildU [i,j,k],[i,j,k+dz], [i,j+dy,k],[i,j+dy,k+dz], zAlign

			if block? then { routing: block, plane: plane, align: align }
			else null

		###*
		 * Generates a Z-shaped tile tile at the position `i,j,k` in the lattice. Note that 
		 * `i,j,k` refers to the  the `v1` position, as in:
		 *
		 *                v3  v4
		 *              /=======>
		 *     ========/
		 *      v2  v1
		 *       
		 * @param  {Number} i 
		 * @param  {Number} j 
		 * @param  {Number} k 
		 * @param  {"X"/"Y"} plane Plane of the strand (`"X"` for XZ or `"Y"` for YZ)
		 * @param  {1/-1} align Direction of the crossover with respect to the plane axis
		 * @param  {1/-1} zAlign=1 Position of the crossover with respect to the Z axis
		 * @return {vox.dna.Strand} 
		###
		zshape = (i,j,k, plane, align, zAlign) ->
			dz = zAlign
			block = switch plane
				when 'X'
					switch align 
						when -1 then buildZ [i,j,k],[i,j,k-dz], [i+1,j,k+dz],[i+1,j,k+2*dz], zAlign
						when +1 then buildZ [i,j,k],[i,j,k-dz], [i-1,j,k+dz],[i-1,j,k+2*dz], zAlign
				when 'Y'
					switch align
						when -1 then buildZ [i,j,k],[i,j,k-dz], [i,j-1,k+dz],[i,j-1,k+2*dz], zAlign
						when +1 then buildZ [i,j,k],[i,j,k-dz], [i,j+1,k+dz],[i,j+1,k+2*dz], zAlign

			if block? then { routing: block, plane: plane, align: align }
			else null

		straight = (i,j,k, len, dir=1) ->
			first = null
			last = null
			start = [i,j,k]
			k0 = k
			for k in [k0...k0 + dir*len] by dir
				pos = [i,j,k]
				if has pos...
					if not first? then first = pos
					last = pos
			if first? and last? 
				doms = for k in [first[2]...last[2]]
					pos = [i,j,k]
					if has pos... then dom(pos, dir)
					else polyT(pos, dir)
				if doms.length > 0 then { routing: _.cat(doms...), align: dir, plane: 'Y' }
				else null
			else null

		###*
		 * @property {Object} tiles 
		 * Convenience namespace for the following properties:
		 * 
		 * - {@link #ushape symmetric}
		 * - {@link #ushape oneway}
		 * - {@link #ushape}
		 * - {@link #zshape}
		###
		tiles = 
			ushape: ushape
			oneway : ushape
			horseshoe : ushape
			symmetric : ushape
			straight : straight
			half : half
			zshape: zshape

		# ---------------------------------------------------------------------
		###*
		 * @property {Object} post
		 * Convenience namespace for the following methods:
		 * 
		 * - {@link #find}:
		 *     - {@link #neighbor5p}
		 *     - {@link #neighbor3p}
		 * - {@link #grid}
		 * - {@link #update_grid}
		 * - {@link #ligate}
		 * - {@link #boundaryStrands}
		###
		post = 
			find: 
				###*
				 * Determines if there is a strand whose 3' end is adjacent to 
				 * `strand`'s 5' end, and if so, returns it.
				 * @param  {vox.dna.Strand} strand Strand to search for neighbor
				 * @param  {ndarray} [grid=null] Grid of strands generated by post#grid
				 * @return {vox.dna.Strand/null} 5' neighbor strand
				###
				neighbor5p: (strand, grid=null) ->
					grid = grid ? post.grid strands
					
					# get 5' base
					base = _.first strand.routing
					
					# get position of 5' neighbor to base
					nPos = lattice.neighbor5p base.pos..., base.dir

					# get strands at position of 5' neighbor
					strds = grid.get nPos

					# get the neighbor
					neighbor = strds?[base.dir]
					[neighbor_strand, neighbor_index]

					if neighbor_index is neighbor_strand.routing.length-1 then neighbor_strand
					else null
				
				###*
				 * Determines if there is a strand whose 5' end is adjacent to 
				 * `strand`'s 3' end, and if so, returns it.
				 * @param  {vox.dna.Strand} strand Strand to search for neighbor
				 * @param  {ndarray} [grid=null] Grid of strands generated by post#grid
				 * @return {vox.dna.Strand/null} 5' neighbor strand
				###
				neighbor3p: (strand, grid=null) ->
					grid = grid ? post.grid strands
					
					# get 3' base
					base = _.last strand.routing
					
					# get position of 5' neighbor to base
					nPos = lattice.neighbor3p base.pos..., base.dir

					# get strands at position of 5' neighbor
					strds = grid.get nPos

					# get the neighbor
					neighbor = strds?[base.dir]
					[neighbor_strand, neighbor_index]

					if neighbor_index is neighbor_strand.routing.length-1 then neighbor_strand
					else null

			###*
			 * Generates a 4D `ndarray` that caches the strand(s) at each 
			 * position within the lattice. Used for speeding up various post-
			 * processing functions.
			 * @param  {vox.dna.Strand[]} strands
			 * @return {ndarray}
			###
			grid: (strands) ->
				dlen = lattice.maxLength()
				grid = ndarray [], [lattice.width, lattice.height, lattice.depth, dlen]

				for strand in strands
					for r, i in strand.routing
						strds = grid.get(r.pos...) ? {}
						strds[r.dir] = [strand, i]
						grid.set(r.pos...) strds

				grid

			###*
			 * Updates a #grid with a given strand and base index
			 * @param  {ndarray} grid 
			 * @param  {vox.dna.Strand} strand 
			 * @param  {Number} base_index 
			 * Index of the base within the strand 
			 * {@link vox.dna.Strand#routing routing} 
			###
			update_grid: (grid, strand, base_index) ->
				i = base_index
				r = strand.routing[i]
				strds = grid.get(r.pos...) ? {}
				strds[r.dir] = [strand, i]
				grid.set(r.pos...) strds

			###*
			 * Ligates `strand1` to `strand2`, updating the `strands` array 
			 * and `grid` cache
			 * @param  {vox.dna.Strand} strand1 
			 * @param  {vox.dna.Strand} strand2 
			 * @param  {Array} strands 
			 * @param  {ndarray} [grid=null] 
			 * @return {vox.dna.Strand} Merged strand
			###
			ligate: (strand1, strand2, strands, grid=null) ->
				merged = _.clone strand1
				merged.routing = _.cat strand1.routing, strand2.routing
				strands.splice strands.indexOf(strand1), 1
				strands.splice strands.indexOf(strand2), 1
				strands.push merged

				if grid? then for r, i in merged_strand.routing
					post.update_grid(grid, merged_strand i)

				merged

			###*
			 * Merges boundary strands together
			 * @param  {vox.dna.Strand[]} strands 
			 * @param  {ndarray} [grid=null] 
			###
			boundaryStrands: (strands, grid=null) ->
				grid = grid ? post.grid strands

				# build list of strand pairs to ligate
				ligations = []
				for strand in strands
					if strand.boundary
						neighbor5p = post.find.neighbor5p strand

						# don't ligate in this loop because ligation modifies 
						# `strands` and `grid`
						if neighbor5p then ligations.push [strand, neighbor5p]

				# ligate all strands, updating the grid
				for lig in ligations
					post.ligate lig[0], lig[1], strands, grid

		return _.extend {
			has : has
			res : res
			enclosed: enclosed
			base : domains.base
			tiles : tiles
			domains: domains
			strands: strands
			post: post
		}, tiles,  domains, strands, post


###*
 * @class  vox.compilers.Compiler
 * @alias vox.compiler
 * @abstract
 * This interface describes the translation scheme/compiler that should be
 * returned from the factory function passed to vox#compile . Note that
 * the `before` and `after` methods are both optional, and will be replaced
 * with no-ops if omitted.
###
###*
 * @method iterator
 * Iterator function which is called on each voxel.
 * @param {Number} a 
 * @param {Number} b 
 * @param {Number} c
 * @param {vox.dna.Strand[]} strands 
 * If the iterator generates any strand(s) for this voxel, they should be 
 * pushed into/spliced into this array.
###
###*
 * @method before 
 * Function to execute before the iterator looks at each voxel
 * @param {vox.dna.Strand[]} strands 
 * If the compiler generates any strand(s) before examining the voxels, 
 * they should be pushed into/spliced into this array.
###
###*
 * @method after 
 * Function to execute after the iterator looks at each voxel
 * @param {vox.dna.Strand[]} strands 
 * If the compiler modifies any strands, it should modify this array.
###


###*
 * Compiles a set of voxels into a set of strands. Accepts a "compiler 
 * `factory`" function which, when called, generates a vox.compilers.Compiler .
 * The factory will be passed the `voxels` and `lattice` arguments.
 * 
 * @param {Function} factory Function which generates compiler
 * @param {ndarray} factory.voxels 
 * @param {vox.lattice.Lattice} factory.lattice
 * @param {vox.compilers.Compiler/Function} factory.return
 * The factory function should either generate a 
 * {@link vox.compilers.Compiler compiler object}, or should just return an 
 * {@link vox.compilers.Compiler#iterator iterator function}. 
 * 
 * @param {ndarray} voxels Array of voxels to be used
 * @param {vox.lattice.Lattice} lattice Lattice object to be used for translation
 * @param {Object} options Options for compilation
 * @param {Array} [options.extents] 
 * 3-element array containing `[low, high]` for each of the 3 dimensions of the
 * lattice, defining the minimum and maximum value for which the iterator should
 * be evaluated. Effectively defaults to:
 *
 *     [ [-1, lattice.width], [-1, lattice.height], [-1, lattice.depth] ]
 * 
 * @return {vox.dna.Strand[]} Array of configuration objects for {@link C3D.models.SST}.
 * @member vox
###
vox.compile = (factory, voxels, lattice, options) ->

	# initialize the compiler
	compiler = factory(voxels, lattice, options)
	compiler = compiler ? {}

	# if compiler just returns an iterator function
	if _.isFunction(compiler)
		# just use that 
		compiler = { iterator: compiler }

	# ensure compiler has before, after, and iterator function
	_.defaults compiler, { before: (->), after: (->), iterator: (->) }

	# run pre-processing function
	strands = []
	compiler.before(strands)

	# iterate across all voxels, building strands
	# 
	#    z/k
	#   /
	#  /______ x/i
	#  |
	#  |
	#  y/j 
	# 
	# z/k is the helical direction
	
	extents = options.extents ? [ [-1, voxels.shape[0]], [-1, voxels.shape[1]], [-1, voxels.shape[2]] ]

	# For each voxel, only strands with the 5' end originating in the same 
	# helix as the voxel are generated
	for i in [extents[0][0]..extents[0][1]]
		for j in [extents[1][0]..extents[1][1]]
			for k in [extents[2][0]..extents[2][1]]
				compiler.iterator(i,j,k,strands)
	
	# run post-processing function
	compiler.after(strands)

	# return
	strands

###*
 * @class vox.dna.CaDNAno
 * @abstract
 * This class attempts to document the caDNAno file format. 
 *
 * caDNAno files describe sets of "helices" (also known as "vstrands"). 
 * Each of helix object describes how the scaffold and staple strands
 * are routed through that helix.
###
###*
 * @property {vox.dna.CaDNAno.Helix[]} vstrands
 * Array of helix objects
###
###*
 * @property {String} name 
 * Name of the file
###

###*
 * @class vox.dna.CaDNAno.Helix
 * @abstract
 * This class documents the helix objects found in the {@link vox.dna.CaDNAno#vstrands vstrands}
 * array of a caDNAno file. It's important to note that each of these objects 
 * represents a distinct _helix_, but not necessarily a distinct _strand_; 
 * strands may span multiple helices, and each helix may contain multiple strands.
 *
 * The most important members are two linked list-like data structures,
 * one for the scaffold (#scaf) and one for the staples (#stap), 
 * demonstrating how scaffold and staple strands are routed through the 
 * structure. This makes it very easy to (for instance) make/break 
 * crossovers and add/remove bases, but very awkward to (for instance)
 * trace a strand throughout the structure, or enumerate all strands in the 
 * structure.
###
###*
 * @property {String/Number} num 
 * Number assigned to the helix. This number is used to refer to the helix
 * within the #scaf and #stap array.
 *
 * Note 1: This number also implies the directionality of the scaffold on this
 * helix: 
 * 
 * - On even-numbered helices, the scaffold runs 5' to 3' (+1) along the helix
 * - On odd-numbered helices, the scaffold runs 3' to 5' (-1) along the helix
 *
 * Note 2: This number _must_ obey the following rule with respect 
 * to #row and #col:
 *
 *     (num % 2) = (row + col) % 2
 *
 * That is, if `row` and `col` are either both even or both odd, then #num
 * must be even; else it must be odd. This is due to the way that caDNAno 
 * figures scaffold directionality, as described above.
###
###*
 * @property {Number} col Column (X-position) of the helix
###
###*
 * @property {Number} row Row (Y-position) of the helix
###
###*
 * @property {Array[]} stap
 * Array of 4-element arrays, each representing a (possible) individual base
 * on one of the staple strands that runs through this helix.
 *  
 * The elements of this array form a linked list, with each inner array 
 * encoding the position of the 5' neighbor and 3' neighbor of this base, 
 * in the following order:
 *
 *     [ 5' helix #, 5' base #, 3' helix #, 3' base # ]
 *
 * For instance, this is helix `5`, and if base `[5,6]` (e.g. the 6th base of
 * this helix) were connected to * base `[5, 5]` and `[6,4]`, then `stap[6]`
 * would be
 *
 *     [5,5, 6,4]
 *
 * When there is no 5' neighbor (or no 3' neighbor), the respective
 * helix and base numbers are both listed as `-1`. This means that the 5'
 * end of the strand is written as:
 *
 *     [-1,-1, 5'-most helix #, 5'-most base #]
 *
 * and the 3' end is written as:
 * 
 *     [3'-most helix #, 3'-most base #, -1, -1]
 *
 * Positions where there is no base should be written as 
 *
 *     [-1, -1, -1, -1]
 * 
 * Note 1: Helix numbers correspond to values of the #num property; that is, 
 * helix 5 refers to the helix where #num = 5, not the helix at index 5 
 * within {@link vox.dna.CaDNAno#vstrands vstrands}. Base numbers refer to
 * indices within the #stap and #scaf arrays.
 *
 * Note 2: Arrays are zero-indexed, so base 0 is the first base, base 1 is the
 * second, and so on.
###
###*
 * @property {Array[]} scaf
 * Same as #stap, but for the scaffold strands
###
###*
 * @property {Number[]} loop
 * Used to add off-lattice bases to the _scaffold_. Each element of #scaf
 * must have a corresponding element of #loop (at the same position), 
 * indicating how many off-lattice bases should be added after this base. 
###
###*
 * @property {Number[]} skip
 * Used to skip on-lattice bases in the _scaffold_. Each element of #scaf
 * must have a corresponding element of #loop (at the same position), 
 * indicating whether the base of the scaffold should be skipped.
###
###*
 * @property {Number[]} stapLoop
 * Currently unknown
###
###*
 * @property {Number[]} scafLoop
 * Currently unknown
###
###*
 * @property {Mixed} stap_colors
 * Currently unknown
###

###*
 * Converts an array of strands into the caDNAno format
 * @param  {C3D.models.SST[]} strands 
 * @param  {vox.lattice.Lattice} lattice 
 * @return {vox.dna.CaDNAno} JSON object representing the caDNAno file to write
 * @member vox
###
vox.toCaDNAno = (strands, lattice) ->

	# constants
	planeMap = { 'X': 'scaf', 'Y': 'stap' }

	# build a map from x,y,z1,z2 coordinates to col,row,base coordinates
	maxLength = lattice.maxLength()
	shape = [lattice.width, lattice.height, lattice.depth*maxLength]
	rel2abs = new ndarray [], [lattice.width, lattice.height, lattice.depth, maxLength]
	for i in [0...shape[0]]
		for j in [0...shape[1]]
			base = 0
			for k in [0...shape[2]]
				for l in [0...lattice.length(i,j,k)]
					rel2abs.set i,j,k,l, base
					base++

	# build an ndarray that contains a reference to the strands that occupy
	# each position in caDNAno coordinate space
	cnmesh = new ndarray [], shape
	relGrid = undefined
	relHelixDir = (x,y,type) -> (if (x % 2 == y % 2) then 1 else -1) * (if type is 'scaf' then 1 else -1)

	# for each strand
	for strand in strands
		routing = strand.get('routing')

		# guess whether scaf or stap from plane
		type = planeMap[strand.get('plane')]
		
		# for each domain in strand
		for r,i in routing
			
			# convert from 4-coordinate to 3-coordinate position
			# pos = [r.pos[0], r.pos[1], r.pos[2]*dlen + r.pos[3]]
			pos = [r.pos[0], r.pos[1], rel2abs.get(r.pos...)]

			if not relGrid? 
				relGrid = relHelixDir(r.pos[0], r.pos[1], type) * r.dir
			else if relHelixDir(r.pos[0], r.pos[1], type) * relGrid isnt r.dir
				throw "This structure can't be exported to caDNAno; doesn't obey caDNAno requirement that scaffold strands have alternating polarities"

			# each position in cnmesh will contain an array with an X-strand 
			# and a Y-strand
			strds = cnmesh.get(pos...) ? {}

			# add this strand to the appropriate position
			strds[type] = [strand, i]

			cnmesh.set(pos..., strds)



	# gets a helix number for a voxel X/Y position
	oddHelices = 0
	evenHelices = 0
	getHelix = (x,y) ->
		# caDNAno uses the helix number to decide whether the scaffold should 
		# be aligned (5'->3') or anti-aligned (3'->5') with the helical axis;
		# even numbered helices are aligned, odd-numbered helices are anti-
		# aligned. 
		# 
		# In the caDNAno interface, when you click to add helices, the 
		# numbering is chosen such that odd helices alternate with even 
		# helices; we need to maintain this pattern otherwise caDNAno will 
		# helpfull place non-antiparallel scaffolds right next to each other,
		# and will get very confused by the scaffold routing we propose.

		if !helices.get(x,y)? 
			dir = (if (x % 2 == y % 2) then 1 else -1) * relGrid

			# if x and y are both even or both odd
			if dir is 1
				helices.set(x,y,evenHelices*2)
				evenHelices++
			else if dir is -1
				helices.set(x,y,oddHelices*2+1)
				oddHelices++
		return helices.get(x,y)

	# converts voxel positions to caDNAno base positions
	vox2cno = (x, y, z1, z2) ->
		helix = getHelix x,y
		# base = z1 * dlen + z2
		base = rel2abs.get x,y,z1,z2
		return [helix, base]

	cnoBase = (prev, next) ->
		return prev.concat next

	addBase = ([strand, base_index], [row, col, pos], list) ->
		# The caDNAno format is weird. Our goal is to append one item to 
		# `list` for each base in the domain. Each such item should be an array
		# of the form 
		#     [5' helix, 5' base, 3' helix, 3' base]
		# where helix/base are in the caDNAno coordinate system. The order
		# of these items is also according to the position within the caDNAno 
		# coordinate system, which assigns an arbitrary directionality to the 
		# helical axis. We assume that the 0 base position in caDNAno 
		# coordinates corresponds to the z = 0 position in NanoBricks 
		# coordinates.
		# 
		# The system is like a doubly-linked list, in that each
		# base has a reference to the position of the next (5') base and to 
		# the previous (3') base. 
		# 
		# Our system encodes the strand routing as a list of domain positions

		routing = strand.get('routing')
		base = routing[base_index]

		# if the domain is oriented 5' -> 3' along the helical axis, things 
		# look like this:
		# 
		# helix 0:
		#     caDNAno base #    
		#        5' -------0------|-----1-----|-----2-----|---...---|------n-------> 3'
		#             [-1,-1,0,1],  [0,0,0,2],  [0,1,0,3],    ...,    [0,n-1,-1,-1]
		#     stap/scaf array 
		# if base.dir is 1
		# 	# build pair for previous base
		# 	if base_index == 0 then p5 = [-1, -1]
		# 	else 
		# 		prev = routing[base_index-1]
		# 		p5 = vox2cno prev.pos...

		# 	# build pair for next base
		# 	if base_index == routing.length-1 then p3 = [-1, -1]
		# 	else 
		# 		next = routing[base_index+1]
		# 		p3 = vox2cno next.pos...
		# 	list.push cnoBase(p5, p3)
			
		# if the domain is oriented 3' -> 5' along the helical axis,
		# then everything's a little confusing. Here's an example:
		# 
		# helix 0:
		#     caDNAno base #    
		#        3' <------0------|-----1-----|-----2-----|---...---|------n------- 5'
		#             [0,1,-1,-1],  [0,2,0,0],  [0,3,0,1],    ...,    [-1,-1,0,n-1]
		#     stap/scaf array 
		# 
		# else if base.dir is -1
		# 	# build pair for previous base
		# 	if base_index == routing.length-1 then p3 = [-1, -1]
		# 	else 
		# 		prev = routing[base_index+1]
		# 		p3 = vox2cno prev.pos..., prev.dir

		# 	# build pair for next base
		# 	if base_index == 0 then p5 = [-1, -1]
		# 	else 
		# 		next = routing[base_index-1]
		# 		p5 = vox2cno next.pos..., -next.dir
		# 	list.push cnoBase(p5,p3)

		# build pair for previous base
		p5 = if base_index == 0 then [-1, -1]
		else vox2cno routing[base_index-1].pos...

		# build pair for next base
		p3 = if base_index == routing.length-1 then [-1, -1]
		else p3 = vox2cno routing[base_index+1].pos...
		
		list.push cnoBase(p5, p3)


	# now build the helices for the caDNAno JSON file
	helices = new ndarray([], [lattice.width, lattice.height])
	vstrands = []

	[cols, rows, hlen] = cnmesh.shape
	step = 32
	extra = step - (hlen % step)

	# for each row and column
	for row in [0...rows]
		for col in [0...cols]

			helix = { 
				row: row, 
				col: col, 
				# row: rows-row, 
				# col: cols-col, 
				scaf: [], stap: [], num: getHelix(col, row), stapLoop: [], scafLoop: [], stapColors: [] 
			}
			empty = true

			# for each base along the helix
			for pos in [0...hlen]

				# get scaffold and staple strands at this voxel position
				strds = cnmesh.get(col,row,pos)

				# if there are any strands here
				if strds?

					# if there is a scaffold strand here
					if strds.scaf?
						addBase(strds.scaf, [row, col, pos], helix.scaf)
						empty = false

					# otherwise push empty base
					else 
						helix.scaf.push([-1,-1,-1,-1]) 

					# if there is a Y strand here
					if strds.stap?
						addBase(strds.stap, [row, col, pos], helix.stap)
						empty = false
					
					# otherwise push empty base
					else
						helix.stap.push([-1,-1,-1,-1]) 

					if helix.scaf.length != helix.stap.length
						throw new Error "Scaffold and staple lengths are not equal!"

				# otherwise push empty bases
				else 
					helix.scaf.push([-1,-1,-1,-1]) 
					helix.stap.push([-1,-1,-1,-1]) 

			# if any bases have been added to helix
			if not empty

				# pad with extra bases so caDNAno 2.0 is happy
				for pos in [0...extra]
					helix.scaf.push([-1,-1,-1,-1]) 
					helix.stap.push([-1,-1,-1,-1]) 					

				# build empty loop and skip sections
				helix.skip = (0 for x in helix.scaf)
				helix.loop = (0 for x in helix.scaf)

				if helix.scaf.length % step isnt 0 or helix.stap.length % step isnt 0
					throw new Error "Scaffold or staple length isn't a multiple of step size #{step}! (File won't work in caDNAno 2.0)"

				if helix.skip.length != helix.loop.length or helix.skip.length != helix.scaf.length
					throw new Error "Loop, skip, and scaf are not equal lengthed!" 

				# append the helix		  
				vstrands.push helix

	{ "name": "SST", "vstrands": vstrands }


###*
 * Imports data in the caDNAno JSON format
 * @param  {Object} data 
 * Contents of a caDNAno JSON file.
 * @param  {vox.lattice.Lattice} lattice Lattice into which to fit the strands
 * @return {vox.dna.Strand[]} List of strand objects
 * @member vox
###
vox.fromCaDNAno = (data, lattice, options) ->
	options ?= {}

	helixMap = {}
	indexMap = {}
	height = 0
	width = 0
	for helix,index in data.vstrands
		helixMap[helix.num] = [helix.col, helix.row]
		indexMap[helix.num] = index
		if helix.row > height then height = helix.row
		if helix.col > width  then width  = helix.col


	shape = lattice.shape()
	abs2rel = ndarray [], shape[0..1]
	for i in [0...shape[0]]
		for j in [0...shape[1]]
			map = []
			for k in [0...shape[2]]
				for l in [0...lattice.length(i,j,k)]
					map.push [k,l]
			abs2rel.set i,j, map

	offsets = options.offsets ? [0,0,0,0]
	reflect = options.reflect ? [0,0]
	offsetsMap = ndarray [], shape[0..1]
	for i in [0...shape[0]]
		for j in [0...shape[1]]
			len = 0
			for k in [0...offsets[2]]
				len += lattice.length(i,j,k)
			len += offsets[3]

			offsetsMap.set i, j, len
			# o_i = i + offsets[0]
			# o_j = j + offsets[1]

			# if 0 <= o_i < shape[0] and 0 <= o_j < shape[1]
			# 	offsets.set o_i, o_j,  


	cno2nb = (num, base) ->
		p = helixMap[num]
		if p? then [x, y] = p else throw new Error "Unknown helix #{num}"
		if reflect[0] then x = width - x
		if reflect[1] then y = height - y
		x += offsets[0]
		y += offsets[1]

		h = abs2rel.get(x,y)
		if not h? then throw new Error "Helix #{num} is now off the lattice at position #{x}, #{y}"
		base += offsetsMap.get x, y

		z = h[base]
		if z? then [z1, z2] = z else throw new Error "Lattice is too small; encountered base [#{num}, #{base}], but helix #{num} is only #{h.length} bases long in the lattice."
		[x,y,z1,z2]

	getHelixDir = (num, type) ->
		# [x, y] = helixMap[num]
		# # when x and y are both even or both odd
		# # then +z = scaffold 5' -> 3'
		# # else -z = scaffold 5' -> 3'
		# # staple is always opposite scaffold
		# (if type is 'stap' then -1 else 1) * (if (x % 2) == (y % 2) then 1 else -1)
		# # switch (x % 2 + y % 2) % 2 
		# # 	when 0,2 then 1 else -1

		(if num % 2 is 0 then 1 else -1) * (if type is 'scaf' then 1 else -1)

	getAt = (num, base, type='stap') ->
		index = indexMap[num]
		data.vstrands[index][type]?[base]

	traverse = (num, base, type) ->
		routing = []
		curr = [num, base]
		loop
			if curr[0] is -1 then break
			pos = cno2nb curr...
			dir = getHelixDir curr[0], type
			color = getAt(curr[0], curr[1], type+'_colors')
			if not getAt(curr[0], curr[1], 'skip')
				routing.push vox.dna.utils.base pos, dir, { color: color }
			if type is 'scaf'
				loopBases = getAt(curr[0], curr[1], 'loop')
				pos = pos[0..2]
				for i in [0...loopBases]
					routing.push vox.dna.utils.base pos.concat([-1]), dir, { color: color }


			curr = getAt(curr[0], curr[1], type)
			if curr? then curr = curr[2..3] else break

		if routing.length > 0
			{ routing: routing, plane: (if type is 'scaf' then 'X' else 'Y') }
		else null

	strands = []
	for helix in data.vstrands
		for type in ['stap', 'scaf']
			for base, base_index in helix[type]
				if base?
					p5 = base[0..1]
					p3 = base[2..3]

					if p5[0] is -1 and p5[1] is -1 and p3[0] isnt -1 and p3[1] isnt -1
						strand = traverse helix.num, base_index, type
						if strand? 
							strand.cadnano = [helix.num, base_index]
							strands.push strand

	strands

vox.caDNAnoLatticeMap = (lattice, options) ->
	options = options ? {}

	helices = lattice.width * lattice.height
	maxHelixLength = 0
	for i in [0...lattice.width]
		for j in [0...lattice.height]
			helixLength = 0
			for k in [0...lattice.depth]
				helixLength += lattice.length i,j,k
			maxHelixLength = Math.max maxHelixLength, helixLength

	helixMap = new ndarray( [], [helices, maxHelixLength] )

	helix = 0
	mapHelix = (i, j) -> 
		base = 0
		for k in [0...lattice.depth]
			for l in [0...lattice.length(i,j,k)]
				helixMap.set(helix, base, [i,j,k,l])
				base++
		helix++

	options.direction ?= 'ribbon'
	switch options.direction
		when 'vertical'
			for i in [0...lattice.width]
				for j in [0...lattice.height]
			 		mapHelix i,j
		when 'horizontal'
			for j in [0...lattice.height]
				for i in [0...lattice.width]
			 		mapHelix i,j
		when 'ribbon'
			for j in [0...lattice.height]
				switch j % 2
					when 0 then for i in [0...lattice.width]
				 		mapHelix i,j
				 	when 1 then for i in [lattice.width-1..0] by -1
				 		mapHelix i,j

	helixMap

module.exports = vox
