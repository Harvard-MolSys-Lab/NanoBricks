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

_ = require('underscore')
$ = require('jquery')
Backbone = require('backbone')
PageableCollection = require("backbone.paginator")
THREE = require('three')
ndarray = require('ndarray')
ndhash = require('ndarray-hash')
cwise = require('cwise')
pool = require('ndarray-scratch')
C3D = require('./c3d.coffee')
vox = require('../vox')

debug = C3D.debug
guid = C3D.guid
signum = C3D.signum
each3d = vox.utils.each3d
visible = C3D.visible
compile = C3D.compile
getShader = C3D.getShader
index = vox.index
mixin = C3D.mixin
initialize = C3D.initialize

###*
 * @class C3D.ctrls
 * @singleton
 * @static
 *
 * Classes in this namespace manage {@link C3D.models.Model}s; they can be
 * notified of added, removed, or changed models like {@link C3D.views.View}s,
 * but also may add or remove models or make other changes to the
 * canvas.
###
module.exports = C3D.ctrls = {}

###*
 * @class  C3D.ctrls.Controller
 * @extends {Backbone.Model}
 * @abstract
 *
 * Base class for a controller which manages some model.
###
class C3D.ctrls.Controller extends Backbone.Model
	mixin @, C3D.Base

	constructor: (@canvas) ->
		###*
		 * @property {C3D.Canvas3D} canvas
		 * Reference to the canvas to which this controller belongs
		###
		@cv = @canvas
		super arguments...

	init: () ->

	###*
	 * @internal
	###
	reset: () ->

	###*
	 * Determines whether this controller applies to a particular model. Every time
	 * a model is added, removed, or changed, the #canvas will call this method,
	 * passing the model, so that the controller may decide whether the model is
	 * applicable. If `true` is returned, then #onModelChange, #onModelAdd, or
	 * {@link #onModelRemove} will be called with the model; if this method returns
	 * `false`, those functions will not be called.
	 *
	 * @param  {Backbone.Model} model Model to test
	 * @return {Boolean} true if this controller applies to the given model, false otherwise
	 * @internal
	###
	match: (model) ->

	###*
	 * Called every time a new model is added to the canvas that
	 * {@link #match matches} this controller.
	 * @param {Backbone.Model} model Model added
	 * @internal
	###
	onModelAdd: (model) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this controller is changed.
	 * @param {Backbone.Model} model Model changed
	 * @internal
	###
	onModelChange: (model, changes) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this controller is removed.
	 * @param {Backbone.Model} model Model removed
	 * @internal
	###
	onModelRemove: (model) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this controller is selected.
	 * @param {Backbone.Model} model Model selected
	 * @internal
	###
	onModelSelect: (model) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this controller is deselected.
	 * @param {Backbone.Model} model Model deselected
	 * @internal
	###
	onModelDeselect: (model) ->


###*
 * Tracks and manages voxels.
 * @extends {C3D.ctrls.Controller}
###
class C3D.ctrls.Voxels extends C3D.ctrls.Controller
	constructor: () ->
		super arguments...

		# Build lattice
		# lattice = @canvas.data.find (x) -> x.isLattice?
		# @canvas.lattice = lattice ? new vox.lattice.WheelSpline(10, 10, 10, {})
		# @canvas.lattice = lattice ? new vox.lattice.CentralSpline(10,10,10,{
		# 	cell: [50, 50, 50],
		# 	# spline: [new THREE.Vector3(0,0,0), new THREE.Vector3(0,0,500)]
		# })
		# @canvas.lattice = lattice ? new vox.lattice.Rectangular(20,20,20,{
		# 	cell: [50,50,100]
		# 	offsets: [+50*20/2,0,+100*20/2]
		# })
		# @canvas.lattice = lattice ? new vox.lattice.Cubic(20,20,20,{
		# 	cell: 50,
		# 	# offsets: [0,0,0]
		# 	offsets: [475,0,475]
		# })
		# if not lattice then @canvas.data.add @canvas.lattice

		###*
		 * @property  {vox.lattice.Lattice} lattice
		 * @member C3D.Canvas3D
		 * The lattice associated with the canvas.
		###
		if not @canvas.lattice?
			@canvas.serializable['lattice'] = true
			@canvas.lattice = new vox.lattice.Cubic(20,20,20,{
				cell: [50,50,50]
				offsets: [475,0,475]
			})

		# @canvas.lattice = @canvas.findOrAdd ((x) -> x.isLattice), () ->
		# 	# new vox.lattice.Rectangular(20,20,20,{
		# 	# 	dlen: 13
		# 	# 	cell: [50,50,100]
		# 	# 	offsets: [+50*20/2,0,+100*20/2]
		# 	# })
		# 	new vox.lattice.Cubic(20,20,20,{
		# 		cell: [50,50,50]
		# 		offsets: [475,0,475]
		# 	})
		# 	# new vox.lattice.CentralSpline(10,10,10,{
		# 	# 	cell: [50, 50, 50],
		# 	# 	# spline: [new THREE.Vector3(0,0,0), new THREE.Vector3(0,0,500)]	
		# 	# })

		@reset()
		@canvas.on 'change:lattice', @reset

		###*
		 * @private
		 * @property {Array}
		 * List of objects whose
		 * {@link C3D.models.Voxel#latticePosition latticePosition} has
		 * changed since the last time #processChangeQueue was called.
		###
		@changeQueue = []
		@processChangeQueue = @canvas.debounceBeforeDraws @processChangeQueue, "C3D.ctrls.Voxels#processChangeQueue"

	match: (model) -> model.type == 'voxel'

	reset: () =>
		# build voxel object cache
		# (TODO: make sparse/hashed array)
		if @voxels
			delete @voxels
		shape = @canvas.lattice.shape() # [@canvas.lattice.width,@canvas.lattice.depth,@canvas.lattice.height]
		@voxels = ndarray([],shape)

	###*
	 * Returns a 3D binary image of the voxels in the lattice
	 * @return {ndarray} Image
	###
	image: () =>
		vox.morphology.image @voxels


	###*
	 * Returns true if canvas contains any voxels, else false
	 * @return {Boolean} hasVoxels
	###
	hasVoxels: () =>
		if @Voxels
			return true
		else
			return false

	###*
	 * Finds a voxel at the passed lattice position
	 * @param  {Number} a
	 * @param  {Number} b
	 * @param  {Number} c
	 * @return {C3D.models.Voxel}
	###
	find: (latticePosition...) ->
		return vox.utils.boundGet(latticePosition, @voxels)
	###*
	 * Adds a voxel at the passed lattice position
	 * @param  {Number} a
	 * @param  {Number} b
	 * @param  {Number} c
	 * @return {C3D.models.Voxel}
	###
	addAt: (latticePosition...) ->
		if !@canvas.lattice.isOnLattice(latticePosition...) then return
		if @find(latticePosition...)? then return

		voxelModel = new C3D.models.Voxel({
			latticePosition: latticePosition
		})
		@canvas.data.add(voxelModel)

	###*
	 * Applies a query to each position in the lattice, saving the result in 
	 * an ndarray.
	 * @param  {Function} fun 
	 * @param {Number} fun.a 
	 * @param {Number} fun.b 
	 * @param {Number} fun.c 
	 * @param  {ndarray} [output=null] Existing array to which to write the output; if omitted, one will be created
	 * @return {ndarray} Result
	###
	query: (fun, output=null) ->
		if not output?
			output = new ndarray([], @canvas.lattice.shape())
		if (not _.isFunction(fun)) and (fun.get?)
			fun = vox.utils.testArray fun

		@canvas.lattice.each (a,b,c) -> output.set a,b,c, fun(a,b,c)
		output

	###*
	 * Adds voxels according to an arbitrary predicate function 
	 * @param {Function} fun Predicate to apply to each position in the {@link C3D.Canvas3D#lattice lattice}.
	 * @param  {Number} fun.a
	 * @param  {Number} fun.b
	 * @param  {Number} fun.c
	 * @param  {Boolean} fun.return `true` to add a voxel at the position, else `false.
	 * @return {C3D.models.Voxel}
	###
	addBy: (fun) ->
		res = pool.malloc @canvas.lattice.shape()
		@query fun, res
		@canvas.lattice.each (a,b,c) => if res.get(a,b,c) then @addAt(a,b,c)
		pool.free res

	###*
	 * Removes voxels according to an arbitrary predicate function (like #addBy)
	###
	removeBy: (fun) ->
		res = pool.malloc @canvas.lattice.shape()
		@query fun, res
		@canvas.lattice.each (a,b,c) => if res.get(a,b,c) then @removeAt(a,b,c)
		pool.free res

	###*
	 * Sets voxels according to an arbitrary predicate function (like #addBy);
	 * if the predicate returns true, then a voxel is added (if there's no
	 * voxel at that position); if it returns false and there's a voxel there,
	 * it's removed.
	###
	setBy: (fun) ->
		res = pool.malloc @canvas.lattice.shape()
		@query fun, res
		@canvas.lattice.each (a,b,c) => if res.get(a,b,c) then @addAt(a, b, c) else @removeAt(a,b,c)
		pool.free res

	###*
	 * Deletes a voxel at the passed lattice position
	 * @param  {Number} a
	 * @param  {Number} b
	 * @param  {Number} c
	 * @return {C3D.models.Voxel}
	###
	removeAt: (latticePosition...) ->
		voxelModel = @find(latticePosition...)
		if voxelModel? then @canvas.data.remove(voxelModel)

	###*
	 * Determines the bounding box (extents) of the current set of voxels,
	 * that is, the minimum and maximum value on each axis
	 * 
	 * @return {Number[][]} extents:
	 *
	 *     [ [xmin, xmax], [ymin, ymax], [zmin, zmax] ]
	###
	getExtents: () ->
		x = [undefined, undefined]
		y = [undefined, undefined]
		z = [undefined, undefined]
		extents = [x,y,z]

		@canvas.lattice.each (i,j,k) =>
			if @find(i,j,k)?
				for r, l in [i,j,k]
					if not extents[l][0]? then extents[l][0] = r
					if not extents[l][1]? then extents[l][1] = r

					if extents[l][0] > r then extents[l][0] = r
					if extents[l][1] < r then extents[l][1] = r
		extents

	getSlice: (slice) ->
		voxels = []
		me = @
		each3d ((model,i,j,k) -> if model? and slice.within(model.get('latticePosition')) then voxels.push model), @voxels
		return voxels

	###*
	 * Applies an iterator to each voxel in the canvas
	 * @param  {Function} iterator Function to be called on each voxel
	 * @param {Number} i 
	 * @param {Number} j 
	 * @param {Number} k 
	 * @param {C3D.models.Voxel} voxel 
	###
	each: (iterator) ->
		each3d ((voxel, i, j, k) -> if voxel? then iterator(i,j,k,voxel)), @voxels

	onModelAdd: (model) ->
		if @canvas.ctrls.Voxels.get (model.get 'latticePosition')
			@canvas.data.remove model
		@voxels.set(model.get('latticePosition')...,model)

	onModelChange: (model) ->
		if model.changed['latticePosition']
			@voxels.set(model.previous('latticePosition')...,undefined)
			@changeQueue.push(model)
		@processChangeQueue()

	###*
	 * @private
	 * Iterates through objects in the #changeQueue, re-adding them to the
	 * #voxels array. This is necessary because if one voxel's latticePosition
	 * changes, it may overwrite an adjacent voxel (and we'd have no way to
	 * tell); this function is automatically debounced and so runs whenever the
	 * current stack frame has cleared, allowing all changes to be enqueued before
	 * and of them are made.
	###
	processChangeQueue: () =>
		for model in @changeQueue
			@onModelAdd model
		@changeQueue = []

	onModelRemove: (model) ->
		@voxels.set(model.get('latticePosition')...,undefined)

	###*
	 * Select voxels according to an arbitrary predicate, then transform them
	 * using an arbitrary transformation function.
	 * @param  {Function} select Selection predicate function
	 * @param {Number} select.x
	 * @param {Number} select.y
	 * @param {Number} select.z
	 * @param {C3D.models.Voxel} select.voxel
	 * @param {Boolean} select.return
	 * true to apply the transform to the voxel
	 *
	 * @param  {Function} transform Transformation function
	 * @param {Number} transform.x
	 * @param {Number} transform.y
	 * @param {Number} transform.z
	 * @param {C3D.models.Voxel} transform.voxel
	###
	selectTransform: (select, transform) ->
		array = @voxels
		res = ndarray([], @canvas.lattice.shape())
		each3d(((vox, x, y, z) ->
			if vox? then res.set(x,y,z, select(x,y,z,vox))
		), @voxels)
		each3d(((vox, x, y, z) ->
			if res.get(x,y,z) then transform(x,y,z,vox)
		), @voxels)

###*
 * Tracks and manages DNA strands (single-stranded tiles).
 * @extends {C3D.ctrls.Controller}
###
class C3D.ctrls.SST extends C3D.ctrls.Controller
	match: (model) -> model.type == 'sst'

	constructor: () ->
		super arguments...
		###*
		 * @property {Backbone.Collection} strands
		 * Cache of strand objects
		###
		# @strands = new Backbone.Collection()
		@pagedStrands = new PageableCollection([], {mode: 'client'})
		@strands = @pagedStrands.fullCollection
		@reset()

		@canvas.on 'change:lattice', @reset

	init: () ->

		# get translation scheme object
		@on 'change:ts', @updateActiveTranslationScheme
		@getTranslationScheme() 


	###*
	 * @private
	 * Removes all strands by resetting the #strands collection; updates 
	 * the #strandMap to adopt new lattice dimensions
	###
	reset: () =>
		@strands.reset()

		###*
		 * @property {ndarray} strandMap
		 * 5D array mapping positions to strands and base indices; the dimensions are:
		 *
		 *     [ @canvas.lattice.width,
		 *       @canvas.lattice.height,
		 *       @canvas.lattice.depth,
		 *       @canvas.lattice.maxLength(),
		 *       2 ]
		 *
		 * where the 4th axis refers to the base-wise position (z2) along the lattice
		 * and the 5th axis refers to the direction of the strand (0 = 3' -> 5',
		 * and 1 = 5' -> 3').
		 *
		 * Each element of this array is itself a 2D array:
		 *
		 *     [ {C3D.models.SST}, {Number} ]
		 *
		 * where the second element is the index of the base at this position.
		###
		@strandMap = new ndarray [], @canvas.lattice.shape().concat([@canvas.lattice.maxLength(),2])

		@changeQueue = []
		@processChangeQueue = @canvas.debounceBeforeDraws @processChangeQueue, "C3D.ctrls.Voxels#processChangeQueue"

	###*
	 * Gets the configured C3D.models.TranslationScheme
	 * @return {C3D.models.TranslationScheme} translation scheme
	 * @internal
	###
	getTranslationScheme: (hard=false) =>
		###*
		 * @property {C3D.models.TranslationScheme[]} tss
		 * Array of active translation scheme instances in the canvas
		###
		@tss = @getTranslationSchemes(hard)

		# find active translation scheme
		ts = _.find(@tss, (x) -> x.get('active')) ? _.first(@tss)
		@set 'ts', ts.cid
		ts

	###*
	 * Gets list of available translation schemes attached to the canvas
	 * @param  {Boolean} [hard=false]
	 * true to clobber existing translation schemes and replace with the
	 * compatible set for this lattice
	 *
	 * @return {C3D.models.TranslationScheme[]} translation schemes
	 * @internal
	###
	getTranslationSchemes: (hard=false) =>
		filter = (x) -> x.isTranslationScheme
		generator = () =>
			new ts() for ts in @getCompatibleTranslationSchemes()

		# get instances of each compatible translation scheme
		if hard then @canvas.replaceOrAdd filter, generator, true
		else @canvas.findOrAdd filter, generator, true

	###*
	 * @private
	 * Updates the {@link C3D.models.TranslationScheme#active active} property
	 * of all loaded {@link #tss translation schemes} according to the #ts
	 * property; called when #ts changes.
	###
	updateActiveTranslationScheme: () =>
		cid = @get 'ts'
		@getTranslationSchemes()
		ts.set('active', ts.cid == cid) for ts in @tss
		@canvas.set('ts', ts)

	###*
	 * Finds a translation scheme with the given `cid` in #tss
	 * @param  {String} cid cid of the translation scheme
	 * @return {C3D.models.TranslationScheme/null}
	 * @internal
	###
	findTranslationScheme: (cid) =>
		_.find @tss, (x) -> x.cid == cid

	###*
	 * Gets a list of translation scheme classes that are compatible with this
	 * lattice
	 * @return {Function[]}
	 * {@link C3D.models.TranslationScheme#getCompatible compatible}
	 * C3D.models.TranslationScheme subclasses
	 * @internal
	###
	getCompatibleTranslationSchemes: () =>
		# get a list of compatible translation scheme classes
		C3D.models.TranslationScheme.getCompatible(@canvas.lattice)

	###*
	 * Returns a list of available {@link vox.lattice.Lattice lattice classes}
	 * @return {Function[]} 
	 * @internal
	###
	getLattices: () =>
		return _.values(vox.lattice)

	###*
	 * Changes the {@link C3D.Canvas3D#lattice lattice} associated with the
	 * current canvas.
	 * @param  {vox.lattice.Lattice} newLattice
	 * @internal
	###
	changeLattice: (newLattice) ->
		@canvas.lattice = newLattice
		@getTranslationScheme true
		@canvas.trigger 'change:lattice', @canvas, newLattice


	###*
	 * Compiles the voxels in the {@link C3D.ctrls.Voxels} controller on this
	 * controller's #canvas to strands, using the
	 * {@link #getTranslationScheme configured translation scheme}.
	###
	compile: (options) =>

		options = options ? {}
		options.merge ?= false

		voxels = @canvas.getCtrl('Voxels').voxels
		if not voxels? then return


		# search for a suitable translation scheme
		ts = @getTranslationScheme()

		if not ts?
			return false

		# # handle crystal
		# options = options ? {} 
		# if @get 'crystal'
		# 	if not options.crystal? 
		# 		options.crystal = @canvas.ctrls.Voxels.getExtents()

		# compile new strands
		strandModels = ts.compile voxels, @canvas.lattice, options
		if options.merge
			hashStrands = (strands) ->
				map = {}
				for strand in strands
					map[strand.routingString()] = strand
				map

			oldStrands = _.clone @strands.models
			oldStrandMap = hashStrands oldStrands

			for newStrand in strandModels
				oldStrand = oldStrandMap[newStrand.routingString()]
				if oldStrand?
					newStrand.merge oldStrand

		# remove existing strands
		@canvas.data.remove(@strands.models)
		@strands.reset()
		@canvas.data.add strandModels
	
		strandModels

	onModelAdd: (model) ->
		@strands.add model
		@addToStrandMap model

	onModelRemove: (model) ->
		@strands.remove model
		@removeFromStrandMap model.get('routing')

	onModelChange: (model) ->
		if model.changed['routing']
			@removeFromStrandMap model.previous('routing')
			@changeQueue.push model
			@processChangeQueue()

	removeFromStrandMap: (routing) ->
		if routing?
			for r,i in routing
				@strandMap.set r.pos..., (r.dir+1)/2, undefined

	addToStrandMap: (model) ->
		routing = model.get 'routing'
		for r,i in routing
			@strandMap.set r.pos..., (r.dir+1)/2, [model,i]

	processChangeQueue: () =>
		for strand in @changeQueue
			@addToStrandMap strand

	hasStrand: (x,y,z1,z2=null) ->
		if not z2?
			for z2 in [0...@canvas.lattice.length(x,y,z1)]
				if @strandMap.get x,y,z1,z2 then return true
			return false
		return @strandMap.get(x,y,z1,z2)?

	###*
	 * Determines whether there is a base at the given 4-component
	 * lattice position
	 * @param  {Number} x
	 * @param  {Number} y
	 * @param  {Number} z1 Voxel position
	 * @param  {Number} z2 Base position (within voxel)
	 * @param  {-1/1} [dir=null]
	 * Strand direction to search for (+1 for 5' -> 3', -1 for 3' -> 5'); by
	 * default searches both directions
	 *
	 * @return {Boolean} `true` if any strand has a base here, else `false`
	###
	hasBaseAt: (x,y,z1,z2,dir=null) ->
		if not dir?
			for dir in [-1, 1]
				if @hasBaseAt(x,y,z1,z2,dir)? then return true
			return false
		else
			return @strandMap.get(x,y,z1,z2, (dir+1)/2)?

	###*
	 * Determines whether there is a base at the given 3-component lattice
	 * position; that is, whether any base in a given voxel has a strand
	 * @param  {Number} x
	 * @param  {Number} y
	 * @param  {Number} z1 Voxel position
	 * @param  {-1/1} [dir=null]
	 * Strand direction to search for (+1 for 5' -> 3', -1 for 3' -> 5'); by
	 * default searches both directions
	 *
	 * @return {Boolean} `true` if any strand has a base here, else `false`
	###
	hasStrandAt: (x,y,z1,dir=null) ->
		if not dir?
			dirs = [-1,1]
		else dirs = [dir]

		for dir in dirs
			for z2 in [0...@canvas.lattice.length(x,y,z1)]
				if @strandMap.get(x,y,z1,z2,(dir+1)/2) then return true
		return false

	###*
	 * Gets the strand and base at a given 4-component lattice position
	 * @param  {Number} x
	 * @param  {Number} y
	 * @param  {Number} z1 Voxel position
	 * @param  {Number} z2 Base position (within voxel)
	 * @param  {-1/1} [dir=1]
	 * Strand direction to search for (+1 for 5' -> 3', -1 for 3' -> 5')
	 * @return {Array/undefined}
	 * 2-element array containing the
	 * - C3D.models.SST : strand object
	 * - Number : index of the base within the strand
	 * or `undefined` if there is no base at this position.
	###
	getStrandAt: (x,y,z1,z2,dir=1) ->
		@strandMap.get x,y,z1,z2, (dir+1)/2

	###*
	 * Gets the strands and bases at a given 3-component lattice position;
	 * this tells you all strands that participate in a given voxel/domain.
	 * @param  {Number} x
	 * @param  {Number} y
	 * @param  {Number} z1 Voxel position
	 * @param  {-1/1} [dir=1]
	 * Strand direction to search for (+1 for 5' -> 3', -1 for 3' -> 5')
	 *
	 * @return {Array}
	 * Array with one element for each base in the domain; that is, the
	 * length of this array will be equal to
	 * {@link vox.lattice.Lattice#length `@canvas.lattice.length(x,y,z1)`}.
	 *
	 * Each element of this array is a 2-element array containing the
	 * - C3D.models.SST : strand object
	 * - Number : index of the base within the strand
	 * or `undefined` if there is no base at this position.
	###
	getStrandsAt: (x,y,z1,dir=1) ->
		for z2 in [0...@canvas.lattice.length(x,y,z1)]
			@strandMap.get x,y,z1,z2, (dir+1)/2


	remove: (strand) ->
		@canvas.data.remove strand

	###*
	 * Cuts the passed strand into two different strands between the 
	 * passed `index` and `index + 1`.	
	 * @param  {C3D.models.SST} strand Strand to cut
	 * @param  {Number} index Index at which to cut; strand will be cut between `index` and `index + 1`.
	 * @return {C3D.models.SST[]} The two new strands
	###
	cutStrand: (strand, index) ->
		routing = strand.get 'routing'

		# check if within bounds
		if index < 0 or index >= routing.length - 1 then return
		@removeFromStrandMap routing

		r1 = routing[0..index]
		r2 = routing[index+1...]
		s1 = strand
		s1.set 'routing', r1
		s2 = new C3D.models.SST { routing: r2 }
		# s2.set 'routing', r2

		@canvas.data.add s2
		[s1, s2]

	###*
	 * Ligates two strands into one new strand; specifically,
	 * ligates the 3' end of `strand1` to the 5' end of `strand2`.
	 * @param  {C3D.models.SST} strand1 
	 * @param  {C3D.models.SST} strand2 
	 * @return {C3D.models.SST} New strand
	###
	ligateStrands: (strand1, strand2) ->
		@canvas.data.remove strand1
		@canvas.data.remove strand2

		r1 = strand1.get 'routing'
		r2 = strand2.get 'routing'
		routing = r1.concat r2

		strand = new C3D.models.SST { routing: routing }
		@canvas.data.add strand
		strand


	getSlice: (slice) ->
		strands = []
		for strand in @strands.models
			if @withinSlice strand, slice then strands.push strand
		return strands

	withinSlice: (strand, slice) ->
		routing = strand.get 'routing'
		for r in routing
			if slice.within r.pos[0..2]
				return true 
		return false

	###*
	 * Removes the passed strand and returns it
	 * @param  {C3D.models.SST} model
	 * @return {C3D.models.SST}
	###
	remove: (model) ->
		@canvas.data.remove model

	###*
	 * Loads data from a caDNAno file-like data structure
	 * @param  {vox.dna.CaDNAno} data
	 * Contents of a deserialized caDNAno JSON file
	###
	fromCaDNAno: (data, options) ->
		strands = vox.fromCaDNAno(data, @canvas.lattice, options)
		strandModels = (new C3D.models.SST(s) for s in strands)
		@canvas.data.add strandModels

	###*
	 * Exports strands to the caDNAno JSON format
	 * @return {vox.dna.CaDNAno}
	 * Object suitable to be serialized to a caDNAno JSON file
	###
	toCaDNAno: () -> vox.toCaDNAno(@strands.models, @canvas.lattice)

	###*
	 * Exports the structure to a CanDo table format
	 * @return {String} CanDo table
	###
	toCanDo: () ->
		lattice = @canvas.lattice
		dlen = _.max _.flatten lattice.each((i, j, k) -> lattice.length(i,j,k))
		grid = new ndarray [], [lattice.width, lattice.height, lattice.depth, dlen]

		index = 0
		for strand in @strands.models
			for r, i in strand.get('routing')
				if r.pos[3] isnt -1
					strds = grid.get(r.pos...) ? {}
					strds[r.dir] = index
					grid.set(r.pos..., strds)
				index++

		# id, 5p, 3p, wc, x, y, z
		rows = []
		index = 0
		for strand in @strands.models
			points = @canvas.views.SST.strand3d strand

			routing = strand.get('routing')
			sequence = strand.get('sequence') ? ''
			l = routing.length
			for r,i in routing
				n5p = if i > 0 then index-1 else -1
				n3p = if i < l-1 then index+1 else -1

				strds = grid.get(r.pos...)
				nwc = strds?[-r.dir] ? -1

				{x,y,z} = points[i]
				b = sequence[i] ? 'N'

				rows.push [index, n5p, n3p, nwc, x, y, z, b]
				index++

		(row.join(",") for row in rows).join("\n")

	###*
	 * Exports strand sequences to comma-separated values (CSV) format
	 * @return {String} CSV text
	###
	toCSV: () ->
		fields = ['name','sequence','well','plate','group']
		rows = for strand in @strands.models
			(('"' + (strand.get(field) ? '') + '"') for field in fields).join(',')
		rows.join("\n")

	###*
	 * Generates sequences using the configured C3D.models.SequenceSet, or a
	 * C3D.models.RandomSequenceSet if none is configured.
	###
	generateSequences: () =>
		@canvas.ctrls.Sequences.generateSequences()

	###*
	 * Select strands according to an arbitrary predicate, then transform them
	 * using an arbitrary transformation function.
	 * @param  {Function} select Selection predicate function
	 * @param {C3D.models.SST} select.strand
	 * @param {Boolean} select.return
	 * true to apply the transform to the strand
	 *
	 * @param  {Function} transform Transformation function
	 * @param {C3D.models.SST} transform.strand
	###
	selectTransform: (select, transform) ->
		@strands.each (strand) ->
			if select(strand) then transform(strand)


###*
 * Manages {@link C3D.models.SequenceSet}s in the canvas.
 * @extends {C3D.ctrls.Controller}
###
class C3D.ctrls.Sequences extends C3D.ctrls.Controller
	constructor: (@canvas) ->
		super arguments...

		###*
		 * @property {C3D.models.SequenceSet[]} ssets
		 * List of active sequence sets in the canvas
		###
		@ssets = []
		@on 'change:sset', @updateActive

	init: () ->
		@getSSets()
		@set 'sset', @getActive().cid
		@updateActive()

	match: (model) -> model.isSequenceSet

	###*
	 * Finds a sequence set by cid
	 * @param  {String} cid
	 * @return {C3D.models.SequenceSet}
	###
	find: (cid) ->
		_.find @ssets, (x) -> x.cid == cid

	onModelAdd: (model) ->
		@ssets.push model

	onModelRemove: (model) ->
		index = @ssets.indexOf model
		if index > -1
			@ssets.splice index, 1

	###*
	 * Gets a list of sequence sets defined on this canvas, adding some if
	 * they don't exist
	 * @return {C3D.models.SequenceSet[]}
	###
	getSSets: () =>
		# ensure canvas has at least one sset defined
		# models will be automatically added to @ssets by @onModelAdd
		@canvas.findOrAdd ((x) -> x.isSequenceSet), (() -> 
			_.sortBy (new cls() for name,cls of C3D.models.ss), (s) -> s.priority
		), true

		@ssets

	getSSet: (type) =>
		_.find @ssets, (ss) -> ss.ssType is type 

	###*
	 * @private
	 * Updates the active sequence set according to #sset
	###
	updateActive: () =>
		cid = @get 'sset'
		(sset.set('active', sset.cid == cid)) for sset in @ssets
		@set 'active', @getActive()

	###*
	 * Gets the active sequence set
	 * @return {C3D.models.SequenceSet} 
	###
	getActive: () => @find(@get('sset')) ? _.first @ssets

	###*
	 * Sets the active sequence set
	 * @param {C3D.models.SequenceSet} sset 
	###
	setActive: (sset) =>
		@set 'sset', sset.cid

	###*
	 * Generates {@link C3D.models.SequenceSet#generate sequences} using the 
	 * active sequence set, but does _not_ thread them onto the strands in the 
	 * canvas.
	###
	generateSequences: () =>
		@getSSets()
		sset = @getActive()

		sset.generate @canvas.lattice, @canvas

	###*
	 * Threads {@link C3D.models.SequenceSet#thread sequences} 
	 * onto the {@link C3D.ctrls.SST#strands strands} in the canvas.
	###
	threadSequences: () =>
		@getSSets()
		sset = @getActive()

		sset.thread @canvas.ctrls.SST.strands.models

	###*
	 * Generates {@link C3D.models.SequenceSet#generate sequences} using the 
	 * active sequence set, and @link C3D.models.SequenceSet#thread threads} 
	 * them onto the {@link C3D.ctrls.SST#strands strands} in the canvas.
	###
	generateThreadSequences: () =>
		@getSSets()
		sset = @getActive()

		sset.generate @canvas.lattice, @canvas
		sset.thread @canvas.ctrls.SST.strands.models
