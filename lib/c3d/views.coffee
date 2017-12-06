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
THREE = require('three')
ndarray = require('ndarray')
ndhash = require('ndarray-hash')
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
 * @class C3D.views
 * @singleton
 * @static
 * This namespace provides {@link C3D.views.View views} for visualizing
 * {@link C3D.models.Model models} on the {@link C3D.Canvas3D canvas}.
###
module.exports = C3D.views = {}


###*
 * @class C3D.views.View
 * @extends {Backbone.Model}
 * @abstract
 * Base class for views which render some models to the
 * {@link C3D.Canvas3D#scene canvas scene}.
###
class C3D.views.View extends Backbone.Model
	constructor: (@canvas) ->

		###*
		 * @property {C3D.Canvas3D} canvas
		 * Reference to the canvas to which this view belongs
		###
		@cv = @canvas
		super { active: @active ? true, available: true }

		@on 'change:active', @onActiveChange, @

	description: ""

	reset: () ->

	init: () ->

	###*
	 * Called when the `active` property of this view changes
	 * @param  {Boolean} active True to activate view, false to deactivate
	###
	onActiveChange: (model, state) -> if state then @activate() else @deactivate()

	###*
	 * Called when this view is activated
	###
	activate: () ->

	###*
	 * Called when this view is deactivated
	###
	deactivate: () ->

	###*
	 * Determines whether this view applies to a particular model. Every time
	 * a model is added, removed, or changed, the #canvas will call this method,
	 * passing the model, so that the view may decide whether the model is
	 * applicable. If `true` is returned, then #onModelChange, #onModelAdd, or
	 * #onModelRemove will be called with the model; if this method returns
	 * `false`, those functions will not be called.
	 *
	 * @param  {Backbone.Model} model Model to test
	 * @return {Boolean} true if this view applies to the given model, false otherwise
	 * @internal
	###
	match: (model) ->

	###*
	 * Called every time a new model is added to the canvas that
	 * {@link #match matches} this view.
	 * @param {Backbone.Model} model Model added
	 * @internal
	###
	onModelAdd: (model) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this view is changed.
	 * @param {Backbone.Model} model Model changed
	 * @internal
	###
	onModelChange: (model, changes) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this view is removed.
	 * @param {Backbone.Model} model Model removed
	 * @internal
	###
	onModelRemove: (model) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this view is selected.
	 * @param {Backbone.Model} model Model selected
	 * @internal
	###
	onModelSelect: (model) ->

	###*
	 * Called every time a new model in the canvas that
	 * {@link #match matches} this view is deselected.
	 * @param {Backbone.Model} model Model deselected
	 * @internal
	###
	onModelDeselect: (model) ->


###*
 * @class C3D.views.Sequences
 * @extends {C3D.views.View}
 * Visualizes sequence sets in the scene
###
class C3D.views.Sequences extends C3D.views.View
	name: 'Sequences'
	active: false
	
	@colors = {
		'A': new THREE.Color 0x0000ff
		'T': new THREE.Color 0xff0000
		'C': new THREE.Color 0x00ff00
		'G': new THREE.Color 0x000000
		'_': new THREE.Color 0xaaaaaa
	}

	description: "
	<span class='nb-views-sequence-key'><span style='background-color:#{@colors['A'].getStyle()}'>&nbsp;</span>	<span>A</span></span>
	<span class='nb-views-sequence-key'><span style='background-color:#{@colors['T'].getStyle()}'>&nbsp;</span>	<span>T</span></span>
	<span class='nb-views-sequence-key'><span style='background-color:#{@colors['C'].getStyle()}'>&nbsp;</span>	<span>C</span></span>
	<span class='nb-views-sequence-key'><span style='background-color:#{@colors['G'].getStyle()}'>&nbsp;</span>	<span>G</span></span>
	<span class='nb-views-sequence-key'><span style='background-color:#{@colors['_'].getStyle()}'>&nbsp;</span>	<span>?</span></span>
	"

	constructor: () ->
		super arguments...

		@canvas.on 'change:lattice', @reset

	match: (model) -> model.type == 'sequenceset'

	activate: () ->
		if @cloud
			@canvas.scene.add @cloud
		else 
			@init()

	deactivate: () ->
		if @cloud
			@canvas.scene.remove @cloud

	reset: () =>
		@init()

	init: () =>

		lattice = @canvas.lattice
		if @cloud?
			@canvas.scene.remove @cloud
			delete @cloud

		vertices = []
		colors = []

		maxLength = lattice.maxLength()
		if maxLength * lattice.width * lattice.height * lattice.depth > 200000 
			@set 'available', false
			@set 'active', false
			return

		vertexMap = @vertexMap = new ndarray [], lattice.shape().concat [maxLength]

		geometry = new THREE.BufferGeometry()
		vertices = []


		lattice.each (a,b,c) ->
			for d in [0...lattice.length(a,b,c)]
				vertexMap.set a, b, c, d, vertices.length
				vertices.push lattice.latticeToPoint(a,b,c,d)
				
				# vertices.push new THREE.Vector3 @canvas.lattice.latticeToPoint(a,b,c,d)...
				# colors.push new THREE.Color(0xaaaaaa)

		positions = new Float32Array( vertices.length * 3 )
		colors = new Float32Array( vertices.length * 3)

		j = 0
		for i in [0...vertices.length]
			positions[ j     ] = vertices[i][0]
			positions[ j + 1 ] = vertices[i][1]
			positions[ j + 2 ] = vertices[i][2]
			colors[ j     ] = 0xaa/0xff
			colors[ j + 1 ] = 0xaa/0xff
			colors[ j + 2 ] = 0xaa/0xff
			j += 3

		geometry.addAttribute 'position', new THREE.BufferAttribute(positions, 3)
		geometry.addAttribute 'color', new THREE.BufferAttribute(colors, 3)

		# geometry = new THREE.Geometry()
		# geometry.vertices = vertices
		# geometry.colors = colors

		material = new THREE.PointCloudMaterial { size: 5, sizeAttenuation: false, vertexColors: THREE.VertexColors, transparent: true, opacity: 0.7 }
		@cloud = new THREE.PointCloud geometry, material
		if @get('active')
			@canvas.scene.add @cloud

	update: (model) ->
		if not @get('available') then return

		if model.sequences
			# colors = @cloud.geometry.colors
			colors = @cloud.geometry.attributes.color.array
			sequenceColors = C3D.views.Sequences.colors

			@canvas.lattice.each (a, b, c) =>
				seq = model.sequences.get(a,b,c) ? ''
				for d in [0...@canvas.lattice.length(a,b,c)]
					base = seq[d] ? '_'
					index = @vertexMap.get a,b,c,d
					color = sequenceColors[base]
					colors[index * 3 + 0] = color.r
					colors[index * 3 + 1] = color.g
					colors[index * 3 + 2] = color.b

			# @cloud.geometry.colorsNeedUpdate = true
			@cloud.geometry.attributes.color.needsUpdate = true

	onModelChange: (model) ->
		if model.get('active')
			@update model



###*
 * @class C3D.views.Voxels
 * @extends {C3D.views.View}
 * Visualizes voxels in the scene (represented as C3D.models.Voxel objects).
###
class C3D.views.Voxels extends C3D.views.View
	name: 'Voxels'
	defaultOpacity: 1.0
	
	constructor: () ->
		super arguments...

		@reset()
		@canvas.on 'change:lattice', @reset

		@changeQueue = []
		@processChangeQueue = @canvas.debounceBeforeDraws @processChangeQueue, "C3D.views.Voxels#processChangeQueue"

	match: (model) -> model.type == 'voxel'

	reset: () =>
		# build voxel object cache
		# (TODO: make sparse/hashed array)

		shape = [@canvas.lattice.width,@canvas.lattice.depth,@canvas.lattice.height]
		@voxels = ndarray([],shape)
		# @visibility = ndarray(new Int8Array(shape[0]*shape[1]*shape[2]),shape)
		@visibility = {} #ndhash(shape)
		@colors = {} #ndhash(shape)
		@opacities = {} #ndhash(shape)

		if @chunks
			each3d ((chunk) => if chunk? then chunk.destroy()), @chunks
			@figureChunks()

	init: () -> @figureChunks()

	activate: () ->
		if @chunks
			each3d ((chunk) => if chunk? then chunk.activate()), @chunks

	deactivate: () ->
		if @chunks
			each3d ((chunk) => if chunk? then chunk.deactivate()), @chunks


	###*
	 * Casts a picking ray from the camera towards the mouse position and 
	 * gets the intersection with the nearest voxel (or position on the plane). 
	 * @param  {Object} options 
	 * Options for the raycasting. See {@link C3D.Canvas3D#getIntersectionPoints} for details.
	 * @return {Array} 
	 * Array of `[intersect, point]` where `intersect` contains data about the
	 * intersection and `point` is a THREE.Vector3. 
	 * See {@link C3D.Canvas3D#getIntersectionPoints} for details.
	###
	getIntersection: (options) ->
		options ?= {}
		intersections = @canvas.getIntersectionPoints ((o) -> o.isVoxel or o.isPlane), options
		for [intersect, point] in intersections
			if intersect.object.isVoxel and intersect.face?
				if intersect.object.chunk?.getAttribute(intersect.face.a, 'voxelVisible') > 0.5
					if options.real
						latticePosition = @canvas.lattice.pointToLattice intersect.burrowed.x, intersect.burrowed.y, intersect.burrowed.z
						if @canvas.ctrls.Voxels.find latticePosition...
							return [intersect, intersect.extruded]
					else				
						return [intersect, point]
			else if intersect.object.isPlane then return [intersect, point]

		return [null, null]

	###*
	 * Shows or hides a voxel at a given position
	 * @param {Number[]} latticePosition
	 * 3-coordinate position at which to display the voxel
	 *
	 * @param {Boolean} isVisible
	 * `true` to show the voxel, else `false` to hide
	###
	setVoxelVisible: (latticePosition, visible) ->
		# @setAttribute latticePosition, 'voxelVisible', visible
		@visibility[latticePosition] = +visible
		# @visibility.set latticePosition..., +visible
		chunk = @getVoxelChunk latticePosition...
		chunk?.setVoxelVisible latticePosition, visible

	###*
	 * Determines whether the voxel at a given latticePosition is visible
	 * @param  {Number[]} latticePosition 
	 * @return {Boolean} 
	###
	isVoxelVisible: (latticePosition) ->
		# !!(@visibility.get latticePosition...)
		!!@visibility[latticePosition]

	###*
	 * Sets the color of a voxel
	 * @param {Number[]} latticePosition
	 * 3-coordinate position at which to display the voxel
	 * @param {THREE.Color} color
	###
	setVoxelColor: (latticePosition, color) ->
		# @setAttribute latticePosition, 'voxelColor', color
		@colors[latticePosition] = color		
		# @colors.set latticePosition..., color
		chunk = @getVoxelChunk latticePosition...
		chunk?.setVoxelColor latticePosition, color


	###*
	 * Sets the opacity of a voxel
	 * @param {Number[]} latticePosition
	 * 3-coordinate position at which to display the voxel
	 * @param {Number} opacity
	###
	setVoxelOpacity: (latticePosition, opacity) ->
		# @setAttribute latticePosition, 'voxelOpacity', opacity
		@opacities[latticePosition] = opacity
		# @opacities.set latticePosition..., opacity
		chunk = @getVoxelChunk latticePosition...
		chunk?.setVoxelOpacity latticePosition, opacity

	###*
	 * Fades a voxel to a lower opacity
	 * @param {Number[]} latticePosition
	 * @param  {Number} [fadeTo=0.5] What opacity to fade the voxel to
	###
	fadeVoxel: (latticePosition, fadeTo=0.5) ->
		@setVoxelOpacity latticePosition, fadeTo

	###*
	 * Restores the voxel to its previous opacity
	 * @param {Number[]} latticePosition
	###
	unfadeVoxel: (latticePosition) ->
		@setVoxelOpacity latticePosition, @defaultOpacity

	setAttribute: (latticePosition, attr, value) ->
		throw "C3D.views.Voxels#setAttribute has been removed. Use setVoxelVisible, setVoxelOpacity, etc."
		# chunk = @getVoxelChunk latticePosition...
		# chunk?.setAttribute latticePosition, attr, value

	###*
	 * Generates a single merged geometry for all voxels in the canvas
	 * @return {THREE.BufferGeometry}
	###
	getGeometry: () ->
		lattice = @canvas.lattice

		# build a new BufferGeometry to hold the mesh data
		geometry = new THREE.BufferGeometry()
		geometries = []
		matrices = []
		each3d ((vox, i, j, k) -> if vox?
			geo = lattice.cellGeometry(i,j,k)
			geometries.push geo
			matrices.push new THREE.Matrix4().makeTranslation lattice.latticeToPoint(i,j,k)...), @voxels

		geometry.mergeMany geometries, matrices
		geometry

	###*
	 * @private
	 * Generates a material that can be used by {@link C3D.views.Voxels.Chunk chunks}.
	 * We cache the material so we don't have to recompile shaders for each new 
	 * chunk.
	 * @return {THREE.Shadermaterial}
	###
	getMaterial: () ->

		# build material if one doesn't exist
		if not @material? then @material = new THREE.ShaderMaterial( { 
			vertexColors: THREE.NoColors
			transparent: true
			lights: true
			shading: THREE.FlatShading
			side: THREE.DoubleSide
			uniforms: THREE.UniformsUtils.merge([
				THREE.UniformsLib['lights'],
				{ diffuse: { type: 'c', value: new THREE.Color(0xffffff) } }
			])
			attributes: {
				voxelColor: { type: 'c', value: new THREE.Color() }
				voxelVisible: { type: 'f', value: [] }
				voxelOpacity: { type: 'f', value: [] }
			}
			vertexShader: getShader """
			attribute vec3 voxelColor;
			attribute float voxelVisible;
			attribute float voxelOpacity;
			varying vec3 vColor;
			varying float vVisible;
			varying float vOpacity;

			// -----------------------------------
			// LIGHTING

			varying vec3 vLightFront;
			#ifdef DOUBLE_SIDED
				varying vec3 vLightBack;
			#endif
			
			#include lights_lambert_pars_vertex

			// -----------------------------------


			void main() {

				vColor = voxelColor;
				vVisible = voxelVisible;
				vOpacity = voxelOpacity;

				gl_Position = projectionMatrix *
							  modelViewMatrix *
							  vec4(position,1.0);

				// -----------------------------------
				// LIGHTING

				vec3 transformedNormal = normalMatrix * normal;
				transformedNormal = normalize( transformedNormal );

				#include lights_lambert_vertex

				// -----------------------------------

			}
			"""

			fragmentShader: getShader  """
			varying vec3 vColor;
			varying float vVisible;
			varying float vOpacity;

			varying vec3 vLightFront;
			#ifdef DOUBLE_SIDED
				varying vec3 vLightBack;
			#endif

			void main() {
				gl_FragColor = vec4(vec3(1.0), 1.0);
				// gl_FragColor = gl_FragColor * vec4(vColor * vColor, vOpacity);
				gl_FragColor = gl_FragColor * vec4(vColor, vOpacity);

				#ifdef DOUBLE_SIDED
					if ( gl_FrontFacing )
						gl_FragColor.xyz *= vLightFront;
					else
						gl_FragColor.xyz *= vLightBack;
				#else
					gl_FragColor.xyz *= vLightFront;
				#endif

				#include linear_to_gamma_fragment

				if (vVisible < 0.5) {
					discard;
				}
			}
			"""
		} )
		
		# return cached material
		@material

	###*
	 * @private
	 * Determines how voxels in the current 
	 * {@link C3D.Canvas3D#lattice lattice} should be split into chunks;
	 * generates #chunks (all of which start empty)
	###
	figureChunks: () ->
		###*
		 * @private
		 * @property {Number} chunkSize
		 * Maximimum size of chunks in each dimension
		###
		@chunkSize = @chunkSize ? 10

		shape = @canvas.lattice.shape()

		###*
		 * @private
		 * @property {Number[]} chunkCounts
		 * Array giving number of chunks in each dimension:
		 * `[ x chunks, y chunks, z chunks ]`
		###
		@chunkCounts = (Math.ceil(r / @chunkSize) for r in shape)
		
		###*
		 * @private
		 * @property {ndarray} chunks
		 * Array of {@link C3D.views.Voxels.Chunk chunk}s. Has dimension
		 * given in #chunkCounts.
		###
		@chunks = new ndarray([], @chunkCounts)
		for i in [0...shape[0]] by @chunkSize
			for j in [0...shape[1]] by @chunkSize
				for k in [0...shape[2]] by @chunkSize
					tr = [i,j,k]
					bl = [Math.min(i+@chunkSize, shape[0]), 
						Math.min(j+@chunkSize, shape[1]), 
						Math.min(k+@chunkSize, shape[2])]
					chunk = new C3D.views.Voxels.Chunk tr, bl, @
					chunkPos = [i // @chunkSize, j // @chunkSize, k // @chunkSize]
					@chunks.set chunkPos..., chunk

	###*
	 * @private
	 * Gets the {{@link C3D.views.Voxels.Chunk chunk} associated with a 
	 * particular lattice position
	 * @param  {Number} i 
	 * @param  {Number} j 
	 * @param  {Number} k 
	 * @return {C3D.views.Voxels.Chunk} chunk for the voxel
	###
	getVoxelChunk: (i,j,k) ->
		pos = [i // @chunkSize, j // @chunkSize, k // @chunkSize]
		chunk = @chunks.get pos... 

	###*
	 * @private
	 * Renders the given model by setting its visibility and color.
	 * @param  {C3D.models.Voxel} model 
	###
	renderModel: (model) ->
		latticePosition = model.get('latticePosition')
		@setVoxelVisible latticePosition, true
		@setVoxelColor latticePosition, 
			if model.selected then new THREE.Color('yellow') 
			else new THREE.Color(model.get('color') ? 0x2ECC71)

	###*
	 * Updates the view according to a slice of the lattice; hides voxels 
	 * no longer within the slice, and shows voxels within the slice.
	 * @param  {vox.Slice} slice 
	###
	updateSlice: (slice) ->
		# get models within slice from controller
		models = @canvas.ctrls.Voxels.getSlice slice

		# cache visible voxels in hash table
		visibleVoxels = {}
		for model in models 
			# visibleVoxels[model.cid] = true
			visibleVoxels[model.get('latticePosition')] = true

		# pre-emptively update #visibility array so that culling decisions will be 
		# made properly within the chunks.
		@canvas.ctrls.Voxels.each (i,j,k,voxel) =>
			latticePosition = voxel.get 'latticePosition'
			@visibility[latticePosition] = +(latticePosition of visibleVoxels)

		# trigger a remeshing of each chunk as needed.
		@canvas.ctrls.Voxels.each (i,j,k,voxel) =>
			latticePosition = voxel.get 'latticePosition'
			@setVoxelVisible latticePosition, (latticePosition of visibleVoxels)
			# if latticePosition of visibility
			# 	@setVoxelVisible latticePosition, true
			# 	@setVoxelColor latticePosition, new THREE.Color(voxel.get('color') ? 0x2ECC71)
			# else @setVoxelVisible latticePosition, false

	###*
	 * @private
	 * Renders queued models (all models in the #changeQueue)
	###
	processChangeQueue: () =>
		for model in @changeQueue
			@renderModel model
		@changeQueue = []


	onModelAdd: (model) ->
		# remember the voxel model
		latticePosition = model.get('latticePosition')
		@voxels.set latticePosition..., model

		# enqueue the model to be rendered before the next draw call
		@changeQueue.push(model)
		@processChangeQueue()

	onModelChange: (model) ->
		# if the model's latticePosition has changed, we'll do special gymnastics
		# to make sure our internal state doesn't get messed up
		if model.changed['latticePosition']
			# clobber the old lattice position in #voxels, and hide the old voxel
			oldLatticePosition = model.previous('latticePosition')
			@voxels.set oldLatticePosition..., undefined
			@setVoxelVisible oldLatticePosition, false

			# enqueue the model to be re-rendered before the next draw call
			@changeQueue.push(model)
			@processChangeQueue()
		else 
			# otherwise we can just immediately re-render the model
			@renderModel model

	onModelSelect: (model) ->
		latticePosition = model.get('latticePosition')
		@setVoxelColor latticePosition, new THREE.Color('yellow')

	onModelDeselect: (model) ->
		latticePosition = model.get('latticePosition')
		@setVoxelColor latticePosition, new THREE.Color(model.get('color') ? 0x2ECC71)

	onModelRemove: (model) ->
		latticePosition = model.get('latticePosition')
		@voxels.set latticePosition..., undefined
		@setVoxelVisible latticePosition, false

###*
 * @class  C3D.views.Voxels.Chunk
 * This class renders individual "chunks" of several voxels, as directed 
 * by C3D.views.Voxels
###
class C3D.views.Voxels.Chunk
	###*
	 * @property {Number} maxRemeshCount
	 * Maximum number of times this chunk will allow itself to be optimistically remeshed before
	 * it just renders all vertices and starts hiding/showing voxels with attributes.
	 * @type {Number}
	###
	maxRemeshCount: 2
	
	###*
	 * @constructor
	 * @param  {Number[]} tl Top-left coordinates of this chunk
	 * @param  {Number[]} br Bottom-right coordinates of this chunk
	 * @param  {C3D.views.Voxels} view containing view
	###
	constructor: (@tl, @br, @view) ->
		###*
		 * @property {Number[]} tl Top-left coordinates of this chunk
		 * @property {Number[]} br Bottom-right coordinates of this chunk
		 * @property {C3D.views.Voxels} view containing view
		###
		@canvas = @view.canvas
		@lattice = @canvas.lattice
		@voxels = @view.voxels
		@visibility = @view.visibility
		@colors = @view.colors
		@opacities = @view.opacities
		@uuid = guid()

		###*
		 * @method scheduleRemesh
		 * Schedules a #remesh to occur {@link C3D.Canvas3D#debounceBeforeDraws before the next rendering}
		###
		@scheduleRemesh = @canvas.debounceBeforeDraws @remesh, "C3D.views.Voxels.Chunk(#{@uuid})#remesh"
		@defaultOpacity = @view.defaultOpacity

	###*
	 * Re-meshes voxels in this chunk
	###
	remesh: () =>
		@meshVoxels()

	###*
	 * Shows this chunk's #mesh on view activation
	###
	activate: () ->
		if @mesh then @canvas.scene.add @mesh

	###*
	 * Hides this chunk's #mesh on view deactivation
	###
	deactivate: () ->
		if @mesh then @canvas.scene.remove @mesh

	###*
	 * Sets the visibility of a voxel, if the voxel has been meshed
	 * @param {Number[]} latticePosition 
	 * @param {Boolean} visible 
	###
	setVoxelVisible: (latticePosition, visible) ->
		if @meshMode isnt 'full' and not @cullCondition(latticePosition)
 			@scheduleRemesh()
		else
			@setAttribute latticePosition, 'voxelVisible', visible

	###*
	 * Sets the color of the voxel, if the voxel has been meshed
	 * @param {Number[]} latticePosition 
	 * @param {THREE.Color} color 
	###
	setVoxelColor: (latticePosition, color) ->
		@setAttribute latticePosition, 'voxelColor', color

	###*
	 * Sets the opacity of a voxel, if the voxel has been meshed
	 * @param {Number[]} latticePosition 
	 * @param {Number} opacity 
	###
	setVoxelOpacity: (latticePosition, opacity) ->
		@setAttribute latticePosition, 'voxelOpacity', opacity

	###*
	 * Fades a voxel to 50% opacity
	 * @param  {Number[]} latticePosition 
	###
	fadeVoxel: (latticePosition) ->
		@setVoxelOpacity latticePosition, 0.5

	###*
	 * Restores a voxel to the #defaultOpacity
	 * @param  {Number[]} latticePosition 
	###
	unfadeVoxel: (latticePosition) ->
		@setVoxelOpacity latticePosition, @defaultOpacity		

	###*
	 * @private
	 * Updates the value of an attribute for some voxel
	 * @param {Number[]} latticePosition 
	 * @param {String} attr Attribute name
	 * @param {Number/THREE.Color/Number[]} value Attribute value
	###
	setAttribute: (latticePosition, attr, value) ->

		# check whether the voxel is present in the mesh
		vertices = @voxelVertices?.get latticePosition...

		# if not then return
		if not vertices? then return

		# if the voxel is present
		else 
			# fetch the requested attribute array and itemSize
			attribute = @attributes[attr]
			array = attribute.array
			itemSize = attribute.itemSize

			# convert value to array
			if value instanceof THREE.Color then value = [value.r, value.g, value.b]
			if not (value instanceof Array) then value = [value]

			# for each vertex, copy value into attribute buffer
			for v in vertices 
				for i in [0...itemSize]
					array[v * itemSize + i] = value[i]

			# mark attribute to be refreshed
			attribute.needsUpdate = true

	###*
	 * Gets the value of an attribute for some vertex
	 * @param  {Number} vertex Vertex index
	 * @param  {String} attr Attribute name
	 * @return {Mixed} Attribute value
	###
	getAttribute: (vertex, attr) ->
		# @attributes[attr].value[vertex]
		@attributes[attr].array[vertex]

	###*
	 * Determines whether a voxel's mesh should be culled. Voxels are culled 
	 * from the mesh if they have two neighbors in each direction (or if the
	 * voxel is absent); if #meshMode is 'full', no voxels are culled.
	 * @param  {Number[]} latticePosition 
	 * @return {Boolean} `true` to cull the voxel, else `false`.
	###
	cullCondition: (latticePosition) ->
		if @meshMode is 'full'
			false 
		else 
			# (not @visibility.get(latticePosition...)) or vox.utils.hasNeighbors(latticePosition, 2, @visibility)
			(not (@visibility[latticePosition])) or vox.utils.hasNeighborsObj(latticePosition, 2, @visibility)

	###*
	 * Generates a new #geometry from all voxels in this chunk. Each 
	 * `latticePosition` is evaluated according to the #cullCondition, 
	 * and culled voxels are excluded entirely from the mesh.
	###
	updateGeometry: () ->
		tl = @tl
		br = @br
		lattice = @lattice

		# build a new BufferGeometry to hold the mesh data
		geometry = new THREE.BufferGeometry()
		geometries = []
		matrices = []
		materialAttributes = {
			voxelColor: { type: 'c', value: [] }
			voxelVisible: { type: 'f', value: [] }
			voxelOpacity: { type: 'f', value: [] }
		}
		attributes = geometry.attributes

		# build map from lattice positions to vertices
		voxelVertices = @voxelVertices = new ndhash(lattice.shape())
		vertexCount = 0
		geoVertexCount = 0
		latticePositions = @latticePositions = []

		# for each latticePosition [i,j,k] in the chunk
		for i in [tl[0]...br[0]]
			for j in [tl[1]...br[1]]
				for k in [tl[2]...br[2]]
					if @cullCondition([i,j,k]) then continue

					geo = lattice.cellGeometry(i,j,k)
					geometries.push geo
					matrices.push new THREE.Matrix4().makeTranslation lattice.latticeToPoint(i,j,k)...
					geoVertexCount = geo.attributes.position.array.length / 3

					# remember which vertices are associated with this object
					voxelVertices.set i,j,k, _.range(vertexCount, vertexCount+geoVertexCount)
					vertexCount += geoVertexCount

					# remember that this latticePosition was included in the 
					# mesh and should have attributes set 
					latticePositions.push [i,j,k]

		# merge all geometries into the single bufferGeometry
		geometry.mergeMany geometries, matrices

		# add custom attributes (these will be populated later)
		voxelColors = new Float32Array vertexCount * 3
		geometry.addAttribute 'voxelColor', new THREE.BufferAttribute(voxelColors, 3) 
		voxelVisible = new Float32Array vertexCount
		geometry.addAttribute 'voxelVisible', new THREE.BufferAttribute(voxelVisible, 1) 
		voxelOpacity = new Float32Array vertexCount
		geometry.addAttribute 'voxelOpacity', new THREE.BufferAttribute(voxelOpacity, 1) 

		# calculate vertex normals
		geometry.computeFaceNormals()
		geometry.computeVertexNormals()

		@geometry = geometry
		@attributes = attributes
		@materialAttributes = materialAttributes

		# apply attribute values to new geometry buffers
		for latticePosition in @latticePositions
			@setAttribute latticePosition, 'voxelVisible', +(@visibility[latticePosition] or 0)
			if latticePosition of @colors 
				@setAttribute latticePosition, 'voxelColor', @colors[latticePosition]
			@setAttribute latticePosition, 'voxelOpacity', @opacities[latticePosition] ? @defaultOpacity

	###*
	 * @private
	 * Called upon each {@link #meshVoxels remeshing} event; determines whether
	 * the chunk should give up and mesh every voxel
	###
	updateMeshMode: () ->
		@remeshCount = @remeshCount ? 0
		@remeshCount += 1 
		if @remeshCount > @maxRemeshCount 
			@meshMode = 'full'
			debug 'Setting mesh mode to full'

	###*
	 * @private
	 * Generates a #mesh for all voxels represented by this chunk and
	 * adds it to the scene. The mesh geometry is built by #updateGeometry,
	 * and attributes are set according to C3D.views.Voxels#visibility,
	 * C3D.views.Voxels#colors, and C3D.views.Voxels#opacities
	###
	meshVoxels: () ->
		# check if meshing mode should be updated
		debug 'Remeshing voxels'
		@updateMeshMode()

		# remove old mesh
		if @mesh then @canvas.scene.remove @mesh

		# build new geometry
		@updateGeometry()

		# if the geometry doesn't have any vertices, then don't add it to the canvas
		if not @geometry.getAttribute('position')? then return

		# get material and update material attributes
		material = @canvas.views.Voxels.getMaterial().clone()
		material.attributes = @materialAttributes
		material.lights = true

		# build mesh and add to canvas
		@mesh = new THREE.Mesh( @geometry, material )
		@mesh.position.set 0,0,0
		@mesh.isVoxel = true
		@mesh.chunk = @

		@canvas.scene.add @mesh

	###*
	 * Removes this chunk from the canvas
	###
	destroy: () ->
		if @mesh then @canvas.scene.remove @mesh

###*
 * @class C3D.views.SST
 * @extends {C3D.views.View}
 * Visualizes DNA tiles (represented as C3D.models.SST objects)
###
class C3D.views.SST extends C3D.views.View
	name: 'Strands'

	constructor: () ->
		super arguments...

		###*
		 * @property {Object} strands
		 * Hash mapping model cids to {@link #drawStrand strand} objects in the
		 * {@link C3D.Canvas3D#scene canvas scene}.
		###
		@strands = {}
		@strandModels = {}
		@canvas.on 'change:lattice', @reset
		@on 'change:crystal', @updateCrystalMap
		@updateCrystalMap()
		@reset()

	activate: () ->
		if @chunks then for chunk in @chunks
			chunk.activate()

	deactivate: () ->
		if @chunks then for chunk in @chunks
			chunk.deactivate()


	reset: () =>
		if @chunks then for chunk in @chunks
			chunk.destroy()

		@chunkMap = @chunkMap ? {}
		@chunks = @chunkQueue = @chunkQueue ? []
		@chunkSize = @chunkSize ? 100

		@strands = {}
		@strandModels = {}
		@slice = new vox.Slice [[0,@canvas.lattice.width], [0,@canvas.lattice.height], [0,@canvas.lattice.depth]]


	match: (model) -> model.type == 'sst'

	updateCrystalMap: () =>
		crystal = @get 'crystal'
		@crystalMap = vox.utils.periodicWrap crystal
		@edgeMap = vox.utils.periodicEdge crystal

	###*
	 * Gives the position, tangent, normal, and binormal vectors for a given base
	 * @param  {vox.dna.Base} r Base object
	 * @param  {Number} i Index of the base within its {@link vox.dna.Strand#routing}
	 * @param  {'X'/'Y'} [plane=null] Plane in which the base's strand lies
	 * @return {THREE.Vector3[]}
	 * Returns an array of four vectors: [position, tangent, normal, binormal]
	###
	base3d: (r, i, plane=null) =>
		# get base position and center in world coordinates
		{ point, tangent, normal, binormal } = @canvas.lattice.base(r.pos..., r.dir)
		center = new THREE.Vector3(@canvas.lattice.latticeToPoint(r.pos[0],r.pos[1],r.pos[2])...)
		point.add(center)

		# use the binormal to offset the X and Y strands
		disp = binormal.clone().normalize().add(normal).normalize()
		# if plane? 
		# 	if plane is 'X' then point.add(disp.multiplyScalar(@x_disp)) else point.add(disp.multiplyScalar(@y_disp))
		if r.dir? 
			point.add(disp.multiplyScalar(@disp * r.dir)) 
		# return R, T, N, B
		[point, tangent, normal, binormal]

	###*
	 * Gives an array of points for the strand described by a particular `model`
	 * @param  {C3D.models.SST} model
	 * @param {Object} options 
	 * @return {THREE.Vector3[]} Array of points
	###
	strand3d: (model, options=null) =>
		options = options ? {}
		points = []
		lines = [points]

		routing = model.get('routing')
		plane = model.get('plane')

		scale = 3/8
		size = @canvas.lattice.cell[2]*scale
		@disp = @canvas.lattice.cell[0]/32
		@x_disp = -@canvas.lattice.cell[0]/32
		@y_disp = +@canvas.lattice.cell[0]/32

		# length in world coordinates that an off-lattice base gets
		base_length = 10 #scale/dlen

		# factor mapping length to height (in world coordinates) of an
		# off-lattice loop.
		loop_height = base_length

		# keep track of the most recent 5' ("last") base encountered that was
		# on the lattice, as well as the next 3' ("next") base that is on
		# the lattice
		lastOnLattice = null
		nextOnLattice = null

		# gets the position of a base in 3D space, centers it in world coordinates, and gives
		# the tangent, normal, and binormal vectors as well
		base = @base3d

		# for each base in the strand routing
		for r,i in routing

			# get 5' and 3' neighbors
			r_5p = if i < (routing.length-1) then routing[i+1] else undefined
			r_3p = if i > 0                  then routing[i-1] else undefined

			point = null

			# if the base is on the lattice
			if @canvas.lattice.isOnLattice r.pos...

				# draw it at the position given by the lattice
				[point, tangent, normal, binormal] = base(r, i, plane)

				# remember that this was the most recent base still on the lattice
				lastOnLattice = [r, i]

				# deal with crystal boundary bases
				if options?.crystal
					edges = @edgeMap r.pos[0..2]...
					edges_5p = if r_5p? then @edgeMap(r_5p.pos[0..2]...) else undefined
					edges_3p = if r_3p? then @edgeMap(r_3p.pos[0..2]...) else undefined
					vs = [binormal, normal, tangent]

					points.push point
					point2 = null
					has5pEdge = false

					# for each axis
					for l in [0..2]

						# if there's an edge here
						if edges[l] isnt 0 

							# if this base is the last one before a crystal edge
							if r_5p? and edges[l] is -edges_5p[l]
								point2 = point2 ? point.clone()
								point2.add(vs[l].clone().multiplyScalar(edges[l] * @canvas.lattice.cell[l]))
								has5pEdge = true

							# if this base is the first one after a crystal edge
							if r_3p? and edges[l] is -edges_3p[l]
								point2 = point2 ? point.clone()
								point2.add(vs[l].clone().multiplyScalar(edges[l] * @canvas.lattice.cell[l]))

					point = null
					if point2? then points.push point2
					if has5pEdge
						points = []
						lines.push points

			# if not do some stuff to figure out where to draw it
			else
				# search ahead to find the next base that's actually on the lattice
				if (not nextOnLattice) or (nextOnLattice[1] < i)
					nextOnLattice = null
					if i < routing.length - 1
						for j in [i+1...routing.length]
							if @canvas.lattice.isOnLattice routing[j].pos...
								nextOnLattice = [routing[j], j]
								break

				# this is a 5' extension
				if nextOnLattice and not lastOnLattice
					[next_r, next_i] = nextOnLattice
					[point, tangent, normal, binormal] = base(next_r,next_i, plane)

					#           ^
					#     dir \ | normal
					#          \|
					#    <------*------->
					#  -tangent   tangent

					dir = tangent.multiplyScalar(-1).add(normal.multiplyScalar(1)).normalize()
					# dir = binormal.multiplyScalar(-1).normalize()
					# dir = normal.multiplyScalar(-1).normalize()
					# dir = tangent.multiplyScalar(-1).normalize()
					point.add(dir.multiplyScalar( (next_i-i) * base_length ))

				# this is a loop
				else if lastOnLattice and nextOnLattice

					# we use the point last point and the next point on the
					# lattice to define a cubic Bezier curve; control points
					# are just given by projection in the direction of the
					# normal of some magic length determined by the size
					# of the loop
					#
					#               * c2
					#    * c1
					#               | /
					#    | /        |/
					#    |/         *--
					#    *--        p2
					#    p1

					[last_r, last_i] = lastOnLattice
					[next_r, next_i] = nextOnLattice
					len = next_i - last_i

					[p1, t1, n1, b1] = base(last_r, last_i, plane)
					[p2, t2, n2, b2] = base(next_r, next_i, plane)
					c1 = p1.clone().add(n1.multiplyScalar(len * loop_height))
					c2 = p2.clone().add(n2.multiplyScalar(len * loop_height))
					curve = new THREE.CubicBezierCurve3(p1, c1, c2, p2)

					point = curve.getPointAt( (i - last_i)/len )

				# this is a 3' extension
				else if lastOnLattice and not nextOnLattice
					[last_r, last_i] = lastOnLattice
					[point, tangent, normal, binormal] = base(last_r,last_i, plane)

					#           ^
					#    normal | / dir
 					#           |/
					#    <------*------->
					#            tangent

					dir = tangent.add(normal).normalize()
					# dir = binormal.multiplyScalar(+1).normalize()
					# dir = normal.multiplyScalar(+1).normalize()
					# dir = tangent.multiplyScalar(-1).normalize()
					point.add(dir.multiplyScalar( (i-last_i) * base_length ))
				else
					null

			if point 
				point._index = i
				point._strand = model.cid
				points.push point
		
		if options?.crystal 
			if lines.length > 1 and lines[lines.length-1].length is 0 
				lines.splice lines.length-1, 1
			lines 
		else points

	###*
	 * Draws a visual representation of a strand model
	 * @param  {C3D.models.SST} model Model representing the strand
	 * @return {THREE.Line} Object representing the strand, to be added to the #canvas
	###
	drawStrand: (model, options) =>
		plane = model.get('plane')
		seq = model.get('sequence')
		points = @strand3d model

		vertexColors = false

		colorMode = model.get('colorMode') ? 'auto'

		if colorMode is 'auto'
			colorMode = if seq? then 'sequence' else 'plane'

		switch colorMode
			when 'plane'
				color = model.get('color') ? (if plane is 'X' then 0x428bca else 0x444444)
				vertexColors = false
			when 'phase'
				color = model.get('color') ? (if plane is 'X' then 0x428bca else 0x444444)
				vertexColors = false
			when 'sequence'
				vertexColors = true

		material = new THREE.LineBasicMaterial({
			color: if vertexColors then 0xffffff else color
			# linewidth: 4
			linewidth: 2
			fog: true
			vertexColors: if vertexColors then THREE.VertexColors else THREE.NoColors
			shading: THREE.FlatShading
		})
		scale = 3/8
		size = @canvas.lattice.cell[2]*scale

		# <<<<<<< crystal
		# object = if options?.crystal
		# 	lines = @strand3d model, options

		# 	objects = for points in lines

		# 		geo = new THREE.Geometry()
		# 		geo.vertices = geo.vertices.concat points
		# 		line = new THREE.Line(geo, material)

		# 		last = points[points.length-1].clone()
		# 		last2 = points[points.length-2].clone()


		# 		arrowDir = last.clone().sub(last2).normalize()
		# 		arrowLen = size/4
		# 		arrow =  new THREE.ArrowHelper(arrowDir, last.clone(), 0, color, arrowLen, arrowLen)
		# 		line.add arrow
		# 		line.isStrand = true
		# 		line
		# 	obj = new THREE.Object3D()
		# 	obj.add o for o in objects
		# 	obj
		# else 
		# 	points = @strand3d model, options

		# 	geo = new THREE.Geometry()
		# 	geo.vertices = geo.vertices.concat points
		# 	line = new THREE.Line(geo, material)

		# 	last = points[points.length-1].clone()
		# 	last2 = points[points.length-2].clone()

		# 	arrowDir = last.clone().sub(last2).normalize()
		# 	arrowLen = size/4
		# 	arrow =  new THREE.ArrowHelper(arrowDir, last.clone(), 0, color, arrowLen, arrowLen)
		# 	line.add arrow
		# 	line

		# object.isStrand = true
		# object.model = model
		# object

		# =======
		geo = new THREE.Geometry()
		geo.vertices = geo.vertices.concat points
		if vertexColors
			switch colorMode
				when 'sequence'
					geo.colors = for v,i in geo.vertices
						j = v._index
						b = seq[j]
						C3D.views.Sequences.colors[b]
				else
					c0 = new THREE.Color(color)
					c1 = new THREE.Color(color).offsetHSL(0,0,0.5)
					l = points.length
					geo.colors = (c0.clone().lerp(c1, i/l) for i in [0...l])

		line = new THREE.Line(geo, material)
		line.userData.baseVertexMap = (vertex._index for vertex in geo.vertices)
		line.userData.strandVertexMap = (vertex._strand for vertex in geo.vertices)
		arrowColor = model.get('arrowColor') ? 0xff0000
		if points.length >= 2
			last = points[points.length-1].clone()
			last2 = points[points.length-2].clone()
			arrow =  new THREE.ArrowHelper(last.clone().sub(last2).normalize(), last.clone(), size, arrowColor, size/4, size/4)
			line.add arrow

		line.isStrand = true
		line.model = model
		line
		# >>>>>>> dev

	###*
	 * @private
	 * Gives the index of the base associated with the passed vertex
	 * @param  {THREE.Line} line 
	 * @param  {Number} vertex Vertex index
	 * @return {Number} base index
	###
	getBaseFromVertex: (line, vertex) ->
		line.userData.baseVertexMap[vertex]

	###*
	 * @private
	 * Gives the `cid` of the strand associated with the passed vertex
	 * @param  {THREE.Line} line 
	 * @param  {Number} vertex Vertex index
	 * @return {String} strand cid
	###
	getStrandFromVertex: (line, vertex) ->
		line.userData.strandVertexMap[vertex]

	###*
	 * @private
	 * Returns the index of the nearest vertex to `point` on the given `line`
	 * @param  {THREE.Line} line 
	 * @param  {THREE.Vector3} point 
	 * @return {Number/undefined} Index of the nearest point, or undefined if one can't be found
	###
	getNearestVertexIndex: (line, point) ->
		nearest = undefined
		minDistSq = Infinity
		for v, i in line.geometry.vertices
			distSq = v.distanceToSquared point
			if distSq < minDistSq 
				minDistSq = distSq
				nearest = i
		nearest

	###*
	 * @internal
	 * Casts a picking ray from the camera towards the mouse position and 
	 * gets the intersection with the nearest strand. Returns the strand, the
	 * index of the base within the strand, and the 3D position of the 
	 * intersection. 
	 * @param  {Object} options 
	 * Options for the raycasting. See {@link C3D.Canvas3D#getIntersectionPoints} for details.
	 * 
	 * @return {Array} 
	 * Array of results `[strand, base, point]`; if no intersection is found, 
	 * then `[null, null, null]` will be returned
	 * @return {C3D.models.SST} return.0 
	 * `strand` object intersected
	 * @return {Number} return.1 
	 * `base` index on intersected strand; get the actual base by calling
	 * {@link C3D.models.SST#getBase strand.getBase}.
	 * @return {THREE.Vector3} return.2 
	 * 3D position of intersected point
	###
	getIntersection: (options) ->
		options ?= {}
		options.extrude = false
		# options.linePrecision = 0.5
		intersections = @canvas.getIntersectionPoints ((o) -> o.isStrand), options
		for [intersect, point] in intersections
			line = intersect.object
			if not line.userData?.baseVertexMap? then continue

			nearestVertexIndex = @getNearestVertexIndex line, point
			strand = @getStrandFromVertex line, nearestVertexIndex
			baseIndex = @getBaseFromVertex line, nearestVertexIndex

			model = @strandModels[strand]

			if model? 
				return [model, baseIndex, point]

		return [null, null, null]

	###*
	 * @private
	 * Gets the {@link C3D.views.SST.Chunk chunk} associated with a particular
	 * model.
	 * @param  {C3D.models.SST} model 
	 * @return {C3D.views.SST.Chunk} 
	###
	getChunk: (model) ->
		if model.cid of @chunkMap then @chunkMap[model.cid]
		else
			chunk = _.last @chunkQueue
			if not chunk? or chunk.length() > @chunkSize
				chunk = new C3D.views.SST.Chunk @
				@chunkQueue.push chunk
			chunk.addModel model
			@chunkMap[model.cid] = chunk
			chunk

	###*
	 * @private
	 * Determines whether a model has been assigned a chunk
	 * @param  {C3D.models.SST} model [description]
	 * @return {Boolean} [description]
	###
	hasChunk: (model) -> model.cid of @chunkMap

	###*
	 * @internal
	 * Forces an update of the #slice.
	###
	refreshSlice: () =>
		@updateSlice @slice

	###*
	 * Resets the #slice to contain the whole lattice
	###
	resetSlice: () =>
		@slice.set 0, 0, @canvas.lattice.width
		@slice.set 1, 0, @canvas.lattice.height
		@slice.set 2, 0, @canvas.lattice.depth
		@updateSlice @slice

	###*
	 * Updates the #slice to a new configuration
	 * @param  {vox.Slice} slice 
	###
	updateSlice: (slice) ->
		visibleStrands = @canvas.ctrls.SST.getSlice slice
		visibility = {}
		for strand in visibleStrands
			visibility[strand.cid] = true
		for cid, model of @strandModels
			if cid of visibility then @showStrand model
			else @hideStrand model
		@slice = slice

		@canvas.views.Voxels.updateSlice slice

	###*
	 * Determines whether a model should be culled (not rendered)
	 * @param  {C3D.models.SST} model 
	 * @return {Boolean} `true` if the model should be culled, else `false`
	###
	cullCondition: (model) ->
		# cull the model if the view is not active or
		not @get('active') or 

		# there's a slice and the model is not within it
		(if @slice? then not @canvas.ctrls.SST.withinSlice(model, @slice) else false)

	###*
	 * Shows the given strand; delegates to the strand's {@link #getChunk chunk}.
	 * @param  {C3D.models.SST} model 
	 * @param  {Boolean} [force=false] 
	###
	showStrand: (model, force=false) ->
		if not @cullCondition(model) 
			@getChunk(model).showStrand(model)

	###*
	 * Hides the given strand, if visible; delegates to the strand's {@link #getChunk chunk}.
	 * @param  {C3D.models.SST} model 
	 * @param  {Boolean} [force=false] 
	###
	hideStrand: (model) ->
		if @hasChunk model
			@getChunk(model).hideStrand(model)

	###*
	 * Fades the passed strand (optionally to the given opacity)
	 * @param  {C3D.models.SST} model
	 * @param  {Number} [opacity=0.5]
	###
	fadeStrand: (model, opacity=0.5) ->
		@setStrandOpacity model, opacity

	###*
	 * Unfades the passed strand (optionally to the given opacity)
	 * @param  {C3D.models.SST} model
	 * @param  {Number} [opacity=1.0]
	###
	unfadeStrand: (model, opacity=1.0) ->
		@setStrandOpacity model, opacity

	###*
	 * Sets the opacity of the passed strand
	 * @param  {C3D.models.SST} model
	 * @param  {Number} opacity
	###
	setStrandOpacity: (model, opacity) ->
		if @strands[model.cid]
			line = @strands[model.cid]
			line.material.opacity = opacity

	onModelAdd: (model) ->
		@showStrand model
		@strandModels[model.cid] = model

	onModelRemove: (model) ->
		chunk = @getChunk model
		chunk.removeModel model
		delete @chunkMap[model.cid]
		delete @strandModels[model.cid] = model

	onModelChange: (model) ->
		chunk = @getChunk model
		chunk.changeModel model

###*
 * @class C3D.views.SST.Chunk
 * This class represents a "chunk" which renders several strands in a single 
 * mesh for performance.
###
class C3D.views.SST.Chunk
	constructor: (@view) ->
		###*
		 * @property {C3D.views.SST} view
		###
		###*
		 * @property {C3D.Canvas3D} canvas
		###
		@canvas = @view.canvas

		###*
		 * @property {Object} models
		 * Maps `cid`s to {@link C3D.models.SST models} tracked by this chunk 
		###
		@models = {}

		###*
		 * @property {Object} models
		 * Maps `cid`s to `true` (for visible) or `false` (for hidden), for 
		 * all {@link C3D.models.SST models} tracked by this chunk.
		###
		@visible = {}

		###*
		 * @property {String[]} cids 
		 * Stores a list of `cid`s of {@link C3D.models.SST models} tracked by this chunk 
		###
		@cids = []
		@uuid = guid()

		###*
		 * @method scheduleRemesh
		 * Schedules a #remesh to occur {@link C3D.Canvas3D#debounceBeforeDraws before the next rendering}
		###
		@scheduleRemesh = @canvas.debounceBeforeDraws @remesh, "C3D.views.SST.Chunk(#{@uuid})#remesh"

	###*
	 * @private
	 * Rebuilds a mesh of the strands
	###
	remesh: () =>
		@meshStrands()

	###*
	 * Determines how many models are tracked by this chunk.
	 * @return {Number} 
	###
	length: () -> @cids.length

	###*
	 * Called when the #view is activated
	###
	activate: () ->
		if @line then @canvas.scene.add @line

	###*
	 * Called when the #view is deactivated
	###
	deactivate: () ->
		if @line then @canvas.scene.remove @line

	###*
	 * Shows the given strand, if hidden; only effective if the model
	 * is {@link #addModel already tracked} by this chunk
	 * @param  {C3D.models.SST} model 
	 * @param  {Boolean} [force=false] 
	###
	showStrand: (model) ->
		if @models[model.cid]? 
			@visible[model.cid] = true
			@scheduleRemesh()

	###*
	 * Hides the given strand, if visible
	 * @param  {C3D.models.SST} model 
	 * @param  {Boolean} [force=false] 
	###
	hideStrand: (model) ->
		if @models[model.cid]? 
			@visible[model.cid] = false
			@scheduleRemesh()

	###*
	 * Instructs this chunk to track and show a given model
	 * @param {C3D.models.SST} model
	###
	addModel: (model) ->
		@models[model.cid] = model
		@visible[model.cid] = model
		@cids.push model.cid
		@scheduleRemesh()

	###*
	 * Instructs this chunk to stop tracking and hide a given model
	 * @param {C3D.models.SST} model
	###
	removeModel: (model) ->
		i = @cids.indexOf model.cid
		if i isnt -1 
			@cids.splice i, 1
			delete @models[model.cid]
			delete @visible[model.cid]

		@scheduleRemesh()

	###*
	 * Called when a model changes; triggers #remesh
	 * @param {C3D.models.SST} model
	###
	changeModel: (model) ->
		@scheduleRemesh()

	###*
	 * Gemerates a single mesh from strands tracked by this model.
	###
	meshStrands: () ->
		material = new THREE.LineBasicMaterial({
			color: 0xffffff
			vertexColors: THREE.VertexColors
			linewidth: 4
		})
		geo = geometry = new THREE.Geometry()

		baseVertexMap = []
		strandVertexMap = []

		for cid in @cids
			model = @models[cid]
			if not model? then continue
			if not @visible[cid] then continue

			points = @view.strand3d model
			points = @strip2pieces points, false
			geometry.vertices.push points...

			plane = model.get('plane')
			seq = model.get('sequence')
			color = if plane is 'X' then 0x0000dd else 0x222222
			colorMode = model.get('colorMode') ? 'auto'
			if colorMode is 'auto'
				colorMode = if seq? then 'sequence' else 'plane'

			switch colorMode
				when 'plane'
					color = model.get('color') ? (if plane is 'X' then 0x428bca else 0x444444)
					geometry.colors.push (new THREE.Color(color) for v in points)...
				when 'phase'
					color = model.get('color') ? (if plane is 'X' then 0x428bca else 0x444444)
					c0 = new THREE.Color(color)
					c1 = new THREE.Color(color).offsetHSL(0,0,0.5)
					l = points.length
					geometry.colors.push (c0.clone().lerp(c1, i/l) for i in [0...l])...
				when 'sequence'
					geometry.colors.push (for v,i in points
						j = v._index
						b = seq[j]
						C3D.views.Sequences.colors[b])...

			
			scale = 3/8
			size = @canvas.lattice.cell[2]*scale
			if points.length >= 2
				last = points[points.length-1].clone()
				last2 = points[points.length-2].clone()
				dir = last.clone().sub(last2).normalize()
				arrow1 = last.clone()
				arrow2 = last.clone().add(dir.multiplyScalar(size/4))
				arrow = [last.clone(), arrow1, arrow1.clone(), arrow2]
				geometry.vertices.push arrow...
				geometry.colors.push (new THREE.Color(0xff0000) for v in arrow)...

		for vertex in geo.vertices
			baseVertexMap.push vertex._index
			strandVertexMap.push vertex._strand

		if @line then @canvas.scene.remove @line
		@line = new THREE.Line(geometry, material, THREE.LinePieces)
		@line.userData.baseVertexMap = baseVertexMap
		@line.userData.strandVertexMap = strandVertexMap
		@line.isStrand = true
		@line.chunk = @
		@canvas.scene.add @line

	strip2pieces: (vertices, circular=true) ->
		list = [vertices[0]]
		for i in [1...vertices.length]
			v = vertices[i]
			c = v.clone()
			c._strand = v._strand
			c._index = v._index
			list.push v, c
		if circular 
			c = vertices[0].clone()
			c._strand = v._strand
			c._index = v._index
			list.push 
		else list.pop()
		list

	destroy: () ->
		if @line then @canvas.scene.remove @line

