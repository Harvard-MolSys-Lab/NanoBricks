# Developing Plugins

This guide describes how to develop plugins for NanoBricks

## Basics

NanoBricks plugins are simple JavaScript files that are injected into the page and loaded once other core scripts have loaded; this means plugins can expect to access the {@link C3D}, {@link UI3D}, and {@link vox} namespaces. Plugins do not need to use AMD or any other module definition pattern---just add things to `C3D`, `UI3D`, and `vox` as if they were global variables. Plugins should *not* necessarily expect `window` to be defined, nor that `C3D`, `UI3D`, and `vox` are available as members of `window`. 

However, the `require` function is available, so other libraries [as described on the architecture page](#!/guide/architecture-key-libraries) may be accessed by `require`. You should not assume that they are available as global variables (for instance, always write `var THREE = require('three')`, rather than just `var THREE = window.THREE`). 

Because plugins may come from arbitrary domains, NanoBricks cannot perform any validation, compilation, or pre-processing of loaded plugins. This means that if you want to write your plugin in [CoffeeScript](http://coffeescript.org/), you'll need to [compile it to JavaScript yourself](http://coffeescript.org/#usage).

## Writing and adding Tools

See the guide ["Developing tools in NanoBricks"](#!/guide/tools) for details on how to write new tools for NanoBricks.

## Writing Lattices

Lattices should extend the class {@link vox.lattice.lattice}. Any methods marked as `abstract` in that class must be implemented. Lattice classes *must* be defined within the {@link vox.lattice} namespace in order to be detected and presented to the user. At the minimum, this generally means:

- {@link vox.lattice.Lattice#latticeToPoint latticeToPoint} -- converts lattice positions to 3D positions
- {@link vox.lattice.Lattice#pointToLattice pointToLattice} -- converts 3D positions to lattice positions
- {@link vox.lattice.Lattice#cellGeometry cellGeometry} -- generates a [`THREE.BufferGeometry`](http://threejs.org/docs/#Reference/Core/BufferGeometry) object for a given lattice position
- {@link vox.lattice.Lattice#cellFootprint cellFootprint} -- generates a [`THREE.Geometry`](http://threejs.org/docs/#Reference/Core/Geometry) with the "footprint" of a cell, for use generating the grid
- {@link vox.lattice.Lattice#cellSpline cellSpline} -- generates a Catmull-Rom spline indicating how a strand would be routed through the cell.

Minimal example of a lattice:

	###*
	 * @class  vox.lattice.Rectangular
	 * Represents a rectangular lattice
	 * @extends {vox.lattice.Lattice}
	###
	class Rectangular extends Lattice
		@_name = 'Rectangular'
		@_class: 'vox.lattice.Rectangular'
		description: """
		Rectangular lattice for 3D single-stranded tile (SST) structures. 8 nt voxels/domains.
		"""
		constructor: () ->
			###*
			 * @cfg {Array} cell
			 * Array containing the dimensions of the rectangular cell
			###
			@cell = @cell ? [50,50,100]

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
			return new THREE.BoxGeometry( @cell... )

		cellSpline: (a, b, c) ->
			# center = @latticeToPoint(a, b, c)
			# return new THREE.SplineCurve3([ 
			# 	new THREE.Vector3(center[0], center[1], center[2]-@cell[2]), 
			# 	new THREE.Vector3(center[0], center[1], center[2]+@cell[2]) ])
			return new THREE.SplineCurve3([ 
				new THREE.Vector3(0, 0, -@cell[2]/2), 
				new THREE.Vector3(0, 0, +@cell[2]/2) ])

## Writing Translation Schemes

Translation schemes are implemented as sublasses of {@link C3D.models.TranslationScheme}. Translation schemes *must* be defined within the {@link C3D.models.ts} namespace in order to be detected and presented to the user. At the minimum, you must override the {@link C3D.models.TranslationScheme#generate} method, which accepts an ndarray of voxels and a {@link vox.lattice.Lattice lattice}, and returns a {@link vox.compilers.Compiler compiler}. The compiler itself must have an `iterator` method that is called for each voxel with coordinates `i`, `j`, and `k`, and a list of `strands` that can be modified (e.g. using `push`, `pop`, `splice`, etc.). Optionally, compilers may also have `before` and/or `after` methods that are just passed the list of `strands` (e.g. to unconditionally add strands, or to post-process strands generated by the `iterator`). 

Minimal example of a translation scheme:
	
	###*
	 * Very simple translation scheme which just places a detached duplex
	 * at each lattice position where there is a voxel.
	###
	class C3D.models.ts.Simple
		generator: (voxels, lattice) ->

			# generate some utility functions that will remember the 
			# lattice, voxel configurations, and other options we pass
			# (e.g. the domain length of 8 nt, in this case)
			utils = vox.compiler.utils voxels, lattice, { dlen: 8 }

			# return a compiler object, which in this case is just an
			# iterator. This iterator will be called for each position
			# [i, j, k] within the lattice.
			iterator: (i, j, k, strands) ->

				# check if there's a voxel at position i, j, k
				if utils.has i,j,k

					# if so, add strands running in both the +1 and -1 directions
					strands.push utils.makeStrand([ utils.domains.dom([i, j, k], 1) ]), 
						utils.makeStrand([ utils.domains.dom([i, j, k], -1) ])
