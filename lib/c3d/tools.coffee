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
 * @class C3D.tools
 * This namespace contains tools that control interaction with a C3D.Canvas3D
 *
 * @singleton
 * @static
###
module.exports = C3D.tools = {}

###*
 * @class C3D.tools.Tool
 * @extends {Backbone.Model}
 * Allows user interaction with a C3D.Canvas3D via mouse and keyboard.
 * @abstract
###
class C3D.tools.Tool extends Backbone.Model
	constructor: (@canvas) ->
		super arguments...
		###*
		 * @property {C3D.Canvas3D} canvas
		 * The managing Canvas object
		###
		@cv = @canvas

		###*
		 * @property {String}
		 * Name of the tool class (within the {@link C3D.tools} namespace).
		 * That is, `C3D.tools[this.toolName]` should resolve to the
		 * {@link #constructor} for this tool.
		###
		@toolType = @constructor.name

		###*
		 * @property {String} name
		 * Human-readable name for the tool.
		###
		@name = @name ? @toolType

		###*
		 * @property {String} iconCls
		 * [Font Awesome icon class](fortawesome.github.io/Font-Awesome/icons/)
		 * to represent the tool in the toolbar
		###

	init: () ->

	###*
	 * @property
	 * Instructions to display to the user when the tool is active
	###
	instructions: ''

	showInToolbar: true

	###*
	 * Called each time the tool becomes active
	 * @abstract
	###
	activate: () ->

	###*
	 * Called each time the tool is deactivated (before another tool becomes
	 * active).
	 * @abstract
	###
	deactivate: () ->

	###*
	 * Called when the `mousedown` event occurs on the {@link #canvas}
	 *  {@link C3D.Canvas3D#renderer renderer} element.
	 * @param {Event} event The event object
	###
	mousedown: () ->

	###*
	 * Called when the `mouseup` event occurs on the {@link #canvas}
	 *  {@link C3D.Canvas3D#renderer renderer} element.
	 * @param {Event} event The event object
	###
	mouseup: () ->

	###*
	 * Called when the `mousemove` event occurs on the {@link #canvas}
	 *  {@link C3D.Canvas3D#renderer renderer} element.
	 * @param {Event} event The event object
	###
	mousemove: () ->

	###*
	 * Called when the `click` event occurs on the {@link #canvas}
	 *  {@link C3D.Canvas3D#renderer renderer} element.
	 * @param {Event} event The event object
	###
	click: () ->

	###*
	 * Called when the `dblclick` event occurs on the {@link #canvas}
	 *  {@link C3D.Canvas3D#renderer renderer} element.
	 * @param {Event} event The event object
	###
	dblclick: () ->

	###*
	 * Registers a key combo handler to be applied only when this tool is
	 * active. Arguments are the same as for C3D.Canvas3D#registerKey .
	 * Prefer using this method within tools, because C3D.Canvas3D#registerKey
	 * will only register _global_ event handlers, and key combos pressed
	 * while other tools are active will still be fired for this tool.
	 *
	 * @param  {String/String[]} combo Space-separated list or array of keys
	 * @param  {Function/Object} options Handler or options
	###
	registerKey: (combo, options) =>
		wrapHandler = (handler) => () =>
			if @active then handler arguments...

		if _.isFunction options then options = wrapHandler(options)
		else if _.isObject options
			options.keydown = if options.keydown? then wrapHandler(options.keydown)
			options.keyup = if options.keyup? then wrapHandler(options.keyup)
			options.release = if options.release? then wrapHandler(options.release)

		@canvas.registerKey combo, options


C3D.tools.InstructionFragments =
	arrowKeys: """
	<table class="key-arrows">
	<tr><td />                     <td><kbd>&uarr;</kbd> </td><td />                    </tr>
	<tr><td><kbd>&larr;</kbd> </td><td><kbd>&darr;</kbd> </td><td><kbd>&rarr;</kbd> </td></tr>
	</table>
	"""

	orbit: """
	                                                Drag  : <span class='instr-action'><i class="fa fa-refresh"></i>      rotate/orbit  </span><br />
	<span class="label label-default">Right</span>  Drag  : <span class='instr-action'><i class="fa fa-arrows"></i>       pan           </span><br />
	                                                Wheel : <span class='instr-action'><i class="fa fa-search"></i>       zoom          </span><br />
	"""

	fly: """
	                                                Mouse : <span class='instr-action'><i class="fa fa-refresh"></i>      turn/aim      </span><br />  
	                                                Drag  : <span class='instr-action'><i class="fa fa-arrows"></i>       fly           </span><br />
	"""

###*
 * Allows the user to pan and orbit the view
 * @extends {C3D.tools.Tool}
###
class C3D.tools.Orbit extends C3D.tools.Tool
	constructor: () ->
		super arguments...

	instructions: "<div class='instructions'>
		#{C3D.tools.InstructionFragments.orbit}
	</div>"
	iconCls: "fa-refresh"


###*
 * Allows the user fly around the scene
 * @extends {C3D.tools.Tool}
###
class C3D.tools.Fly extends C3D.tools.Tool
	constructor: () ->
		super arguments...

	instructions: "<div class='instructions'>
		#{C3D.tools.InstructionFragments.fly}
	</div>"
	iconCls: "fa-rocket"

	init: () ->
		@registerKey 'esc', () => @canvas.setActiveTool 'Orbit'

	activate: () -> 
		@canvas.controls.enabled = false
		@canvas.flyControls.enabled = true
		@canvas.flyControls.reset()
		# @canvas.flyControls.pointerLock()
		undefined

	deactivate: () -> 
		@canvas.controls.enabled = true
		@canvas.flyControls.enabled = false
		@canvas.flyControls.reset()
		# @canvas.flyControls.exitPointerLock()
		undefined


###*
 * @extends {C3D.tools.Tool}
 * Provides facilities for displaying a voxel brush
 * @abstract
###
class C3D.tools.AbstractBrush extends C3D.tools.Tool
	constructor: () ->
		@colors = [0x2ECC71, 0x3498DB, 0xFF4444]
		super arguments...
		@canvas.on 'change:lattice', @resetBrush

	resetBrush: () ->
		if @brush
			null

	activate: () ->
		@sphere = do () ->
			geometry = new THREE.SphereGeometry( 5, 32, 32 );
			material = new THREE.MeshBasicMaterial( {color: 0xff0000} );
			new THREE.Mesh( geometry, material );

		# @snapSphere = do () ->
		# 	geometry = new THREE.SphereGeometry( 5, 32, 32 );
		# 	material = new THREE.MeshBasicMaterial( {color: 0x0000ff} );
		# 	new THREE.Mesh( geometry, material );

		if @sphere? then @canvas.scene.add( @sphere );
		if @snapSphere? then @canvas.scene.add( @snapSphere );

		# Brush
		CubeMaterial = THREE.MeshLambertMaterial
		cube = @canvas.lattice.cellGeometry(0,0,0).clone()
		@brushMaterial = new CubeMaterial( { vertexColors: THREE.NoColors, opacity: 0.5, transparent: true } )
		@brushMaterial.color.setHex(@colors[1])
		@createBrush cube
		# @updateWireMesh()

		visible(@brush,false)

	deactivate: () ->
		if @sphere then @canvas.scene.remove(@sphere); delete @sphere
		if @snapSphere then @canvas.scene.remove(@snapSphere); delete @snapSphere
		if @brush then @canvas.scene.remove @brush; delete @brush
		if @wireMesh then @canvas.scene.remove @wireMesh; delete @wireMesh

	###*
	 * Updates the position of the #brush
	 * @param  {THREE.Vector3} position
	 * Position to which the brush should be moved (will be snapped to lattice)
	 *
	 * @param {Boolean} [brushVisible=true]
	 * True to show the brush, false to hide it
	###
	updateBrush: (position, brushVisible=true, color=1) =>
		lp = @canvas.lattice.pointToLattice(position.x, position.y, position.z, true)
		latticePosition = lp[0..2]

		if @canvas.lattice.isOnLattice latticePosition...
			@cursor = lp
			len = @canvas.lattice.length latticePosition...
			@set('status', '<span>Position: ' + lp.join(', ') + '</span><span class="pull-right">' + len + ' nt</span>')
			snapPos = @canvas.lattice.latticeToPoint(latticePosition...)
			newGeom = @canvas.lattice.cellGeometry(latticePosition...).clone()

			@createBrush newGeom, color

			[@brush.position.x, @brush.position.y, @brush.position.z] = snapPos
			if @sphere then [@sphere.position.x, @sphere.position.y, @sphere.position.z] = [position.x, position.y, position.z]
			if @snapSphere then [@snapSphere.position.x, @snapSphere.position.y, @snapSphere.position.z] = snapPos

		visible(@brush,brushVisible)
		if @wireMesh? then visible(@wireMesh,brushVisible)

	###*
	 * Creates a new brush
	 * @param  {THREE.Geometry} cube Geometry to use (will be moved to proper position)
	###
	createBrush: (cube, color=1) ->
		###*
		 * @property {THREE.Mesh} brush
		 * Object representing the brush on the canvas
		###
		if @brush then @canvas.scene.remove @brush
		@brush = new THREE.Mesh(cube, @brushMaterial)
		@brushMaterial.color.setHex(@colors[color])
		# @brush.isBrush = true
		@canvas.scene.add( @brush )

	###*
	 * Updates the #wireMesh associated with the #brush
	###
	updateWireMesh: () ->
		###*
		 * @param {THREE.Geometry} wireMesh
		 * Object showing a wireframe around the brush on the canvas
		###
		return
		if @wireMesh then @canvas.scene.remove @wireMesh
		@wireMesh = new THREE.EdgesHelper(@brush, @brush.material.color.clone().addScalar(0.05))

		@canvas.scene.add(@wireMesh)

	###*
	 * Gets the 3-component position of the brush on the lattice
	 * @return {Array} [x,y,z1]
	###
	getBrushPosition: (base=false) ->
		@canvas.lattice.pointToLattice @brush.position.x,@brush.position.y,@brush.position.z, base

	###*
	 * Gets the 4-component position of the cursor on the lattice 
	 * @return {Array} [x,y,z1,z2]
	###
	getCursorPosition: () ->
		@cursor ? [0,0,0,0]

	###*
	 * Moves the brush by the given amount (in lattice coordinates)
	 * @param  {Number[]} dirs 3-element array with a delta (in lattice coordinates) for each dimension
	###
	moveBrush: (dirs, args...) ->
		latticePosition = @getBrushPosition()
		latticePosition = (latticePosition[i]+dr for dr,i in dirs)
		position = @canvas.lattice.latticeToPoint latticePosition...
		@updateBrush new THREE.Vector3(position...), args...

	guessLatticeProjection: () ->
		latticePosition = @getBrushPosition()
		position = @brush.position.clone()
		camera_brush = @canvas.camera.position.clone().sub(position)

		# get a set of 3 vectors, representing +x, +y, and +z for the camera (in world coordinates)
		# camera_up = @canvas.camera.localToWorld(@canvas.camera.up.clone()).normalize()
		camera_up = (new THREE.Vector3( 0, 1, 0 )).applyQuaternion(@canvas.camera.quaternion).normalize()
		camera_look = (new THREE.Vector3( 0, 0, -1 )).applyQuaternion(@canvas.camera.quaternion).normalize()
		camera_right = (new THREE.Vector3()).crossVectors(camera_look, camera_up).normalize()

		# px = camera_right.clone().multiplyScalar(@canvas.lattice.cell[0]).add(position)
		# nx = camera_right.clone().multiplyScalar(-@canvas.lattice.cell[0]).add(position)
		# py = camera_up.clone().multiplyScalar(@canvas.lattice.cell[1]).add(position)
		# ny = camera_up.clone().multiplyScalar(-@canvas.lattice.cell[1]).add(position)
		# pz = camera_look.clone().multiplyScalar(@canvas.lattice.cell[2]).add(position)
		# nz = camera_look.clone().multiplyScalar(-@canvas.lattice.cell[2]).add(position)

		# for pair in [[px, nx], [py, ny], [pz, nz]]
		# 	for r in pair
		# 		p = @canvas.lattice.pointToLattice(r.x, r.y, r.z)
		# 		(latticePosition[i]-p[i]) for l,i in p

		# proj = for pair, i in [['x', camera_right], ['y', camera_up], ['z', camera_look]]
		# 	[axis, vector] = pair
		# 	signum(vector[axis])

		# dirs = for pair in [[[1,0,0],[-1,0,0]], [[0,1,0],[0,-1,0]], [[0,0,1],[0,0,-1]]]
		# 	for dir in pair
		# 		proj[i]*r for r,i in dir

		# dirs

		dirs = for vector, i in [camera_right, camera_up, camera_look]
			for dir in [1, -1]
				# v = [signum(Math.round(vector.x)), signum(Math.round(vector.y)), signum(Math.round(vector.z))]
				# v
				(signum(Math.round(dir*vector[c])) for c in ['x','y','z'])

	###*
	 * Attempts to move the cursor in the given direction with respect to the 
	 * camera's current view. Uses #guessLatticeProjection to guess how this 
	 * direction translates to movement on the lattice. 
	 * @param  {'+x'/'-x'/'+y'/'-y'/'+z'/'-z'} dir Direction to move
	###
	smartMove: (dir) ->
		directions = @guessLatticeProjection()
		deltas = switch dir
			when '+x' then directions[0][0]
			when '-x' then directions[0][1]
			when '+y' then directions[1][0] 
			when '-y' then directions[1][1] 
			when '+z' then directions[2][0]
			when '-z' then directions[2][1]

		if deltas? 
			@moveBrush deltas
		else
			@updateBrush @brush.position

	registerSmartMoveKeys: () ->
		@registerKey 'up', { exclusive: true, keyup: () => @smartMove('+y') }
		@registerKey 'down', { exclusive: true, keyup: () => @smartMove('-y') }
		@registerKey 'left', { exclusive: true, keyup: () => @smartMove('-x') }
		@registerKey 'right', { exclusive: true, keyup: () => @smartMove('+x') }
		@registerKey 'ctrl up', { exclusive: true, keyup: () => @smartMove('+z') }
		@registerKey 'ctrl down', { exclusive: true, keyup: () => @smartMove('-z') }
		@registerKey 'ctrl left', { exclusive: true, keyup: () => @smartMove('-x') }
		@registerKey 'ctrl right', { exclusive: true, keyup: () => @smartMove('+x') }


class C3D.tools.StrandLigator extends C3D.tools.Tool
	name: "Ligate Strands"
	iconCls: "fa-link"
	instructions: "
	<span class='label label-default'>1st</span> Click : <span class='instr-action'>Choose 3' end </span><br />
	<span class='label label-default'>2nd</span> Click : <span class='instr-action'>Choose 5' end and ligate </span><br />
	<kbd>Esc</kbd> : <span class='instr-action'>Cancel</span>
	"
	constructor: () -> 
		super arguments...
		@states = {
			CHOOSE_3P: 0
			CHOOSE_5P: 1
		}

	init: () ->
		@registerKey 'esc', () => @reset()

	activate: () ->
		super arguments...
		if not @spheres
			geometry = new THREE.SphereGeometry( 5, 32, 32 )
			material = new THREE.MeshBasicMaterial( {color: 0xff0000} )

			@spheres = [
				new THREE.Mesh( geometry, material ),
				new THREE.Mesh( geometry.clone(), material )
			]

		@canvas.scene.add @spheres[0]
		@canvas.scene.add @spheres[1]
		@state = @states.CHOOSE_3P
		@reset()
		undefined

	deactivate: () ->
		super arguments...
		if @spheres
			@canvas.scene.remove @spheres[0]
			@canvas.scene.remove @spheres[1]
		undefined		

	unfadeStrands: () ->
		if @strand_5p? then @canvas.views.SST.unfadeStrand @strand_5p
		if @strand_3p? then @canvas.views.SST.unfadeStrand @strand_3p

	fadeStrands: () ->
		if @strand_5p? then @canvas.views.SST.fadeStrand @strand_5p
		if @strand_3p? then @canvas.views.SST.fadeStrand @strand_3p

	reset: () ->
		@unfadeStrands()
		@strand_5p = null
		@strand_3p = null

		visible @spheres[0], true
		visible @spheres[1], false
		@state = @states.CHOOSE_3P

	updateStatus: () ->
		@set 'status', ((if @strand_3p? then @strand_3p.get3p() else "?") + " &rarr; " + (if @strand_5p? then @strand_5p.get5p() else "?"))

	mousemove: () ->
		@unfadeStrands()

		# get intersections with mouse
		[strand, base, position] = @canvas.views.SST.getIntersection()

		if position?
			switch @state
				when @states.CHOOSE_3P
					pos = strand.get3p()
					sphere = @spheres[0]
					@strand_3p = strand
				when @states.CHOOSE_5P
					pos = strand.get5p()
					sphere = @spheres[1]
					@strand_5p = strand

			point = @canvas.lattice.latticeToPoint pos...
			[sphere.position.x, sphere.position.y, sphere.position.z] = point

			@fadeStrands()
			@updateStatus()

	mouseup: () -> 
		switch @state
			when @states.CHOOSE_3P
				visible @spheres[1], true
				@state = @states.CHOOSE_5P

			when @states.CHOOSE_5P

				@canvas.ctrls.SST.ligateStrands @strand_3p, @strand_5p
				@reset()
				@state = @states.CHOOSE_3P



class C3D.tools.StrandCutter extends C3D.tools.Tool
	name: "Cut Strands"
	iconCls: "fa-cut"
	instructions: "
	<div class='instructions'>
	Click : <span class='instr-action'><i class='fa fa-cut'></i> Cut strand between bases        </span>
	</div>
	"
	constructor: () -> 
		super arguments...

	activate: () ->
		super arguments...
		if not @cutSpheres
			geometry = new THREE.SphereGeometry( 5, 32, 32 )
			material = new THREE.MeshBasicMaterial( {color: 0xff0000} )

			@cutSpheres = [
				new THREE.Mesh( geometry, material ),
				new THREE.Mesh( geometry.clone(), material )
			]

		@canvas.scene.add @cutSpheres[0]
		@canvas.scene.add @cutSpheres[1]
		undefined

	deactivate: () ->
		super arguments...
		if @cutSpheres
			@canvas.scene.remove @cutSpheres[0]
			@canvas.scene.remove @cutSpheres[1]
		undefined

	mousemove: () ->
		# unfade any faded strands
		if @strand 
			@canvas.views.SST.unfadeStrand @strand
		@strand = null
		@base = null

		# get intersections with mouse
		[strand, base, position] = @canvas.views.SST.getIntersection()
		if position?
			if base >= strand.length()-1
				if strand.length() < 2 then return
				base = strand.length()-2

			@strand = strand
			@base = base

			routing = @strand.get 'routing'
			if not routing[base]?.pos? or not routing[base+1]?.pos? then return

			positions = [ 
				@canvas.lattice.latticeToPoint routing[base  ].pos...
				@canvas.lattice.latticeToPoint routing[base+1].pos...
			]

			@set 'status', "Cut [#{routing[base].pos}] (\##{base}) / [#{routing[base].pos}] (\##{base + 1})"

			for s, i in @cutSpheres
				[s.position.x, s.position.y, s.position.z] = positions[i]

			@canvas.views.SST.fadeStrand strand

	mouseup: () ->
		# ignore dragging motion
		if @canvas.mouse.downPosition.length() > 5 then return

		# If any strands are marked for cutting
		if @strand? and @base?
			@canvas.views.SST.unfadeStrand @strand
			@canvas.ctrls.SST.cutStrand @strand, @base
			@strand = null
			@base = null

###*
 * Allows the user to erase strands from the canvas by clicking
 * @extends {C3D.tools.AbstractBrush}
###
class C3D.tools.StrandEraser extends C3D.tools.AbstractBrush
	name: "Strand Eraser"
	iconCls: "fa-eraser"
	instructions: "
	<div class='instructions'>

	Click : <span class='instr-action'><i class='fa fa-minus-circle'></i> delete strand        </span><br />  
	<kbd>Shift</kbd> + Click : <span class='instr-action'><i class='fa fa-minus-circle'></i> delete base          </span><br />  
	</div>
	"

	constructor: () ->
		super arguments...

	mousedown: () ->

	mouseup: () ->
		# ignore dragging motion
		if @canvas.mouse.downPosition.length() > 5 then return

		# If any strands are marked for erasing
		if @strand

			# If a particular base is marked
			if @base
				if @base is 0
					@strand.truncate 1, -1
				else if @base is (@strand.length()-1)
					@strand.truncate 1, 1
				else
					strands = @canvas.ctrls.SST.cutStrand @strand, @base
					strands[0].truncate 1, 1
			else 
				# remove each of them
				@canvas.data.remove @strand

		@strand = null
		@base = null

	mousemove: () ->
		###*
		 * @property {C3D.models.SST[]} strands
		 * List of strand(s) currently hovered
		###

		# unfade any faded strands
		if @strand 
			@canvas.views.SST.unfadeStrand @strand
		@strand = null
		@base = null

		# get intersections with mouse
		[strand, base, position] = @canvas.views.SST.getIntersection()
		if position?

			# update position of brush and cursor
			@updateBrush position, false
			# lp = @getBrushPosition(true)

			@canvas.views.SST.fadeStrand strand
			@strand = strand

			if @canvas.keys.isShiftDown
				@base = base

			# # search for strands running in both directions
			# dirs = [-1,1]
			# for dir in dirs
			# 	s = @canvas.ctrls.SST.getStrandAt lp..., dir
				
			# 	# if there's a strand at the brush position, fade it and 
			# 	# mark it for erasing
			# 	if s?
			# 		[strand, base_index] = s 
			# 		@canvas.views.SST.fadeStrand strand
			# 		@strands.push strand

			@set 'status', strand.getSummary(base)


###*
 * Allows the user to extend strands on the canvas by clicking and dragging
 * @extends {C3D.tools.AbstractBrush}
###
class C3D.tools.StrandExtender extends C3D.tools.AbstractBrush
	name: "Strand Extender"
	iconCls: "fa-long-arrow-right fa-rotate-45"
	instructions: "
	<div class='instructions'>
	Click : <span class='instr-action'><i class='fa fa-minus-circle'></i> delete        </span><br />  
	</div>
	"

	scaleFactor: 1.0
	
	constructor: () ->
		super arguments...

	mousedown: () ->
		###*
		 * @property {C3D.models.SST[]} strands 
		 * List of strand(s) currently hovered
		###

		# unfade any faded strands
		if @strands 
			for strand in @strands
				@canvas.views.SST.unfadeStrand strand
		@strands = []

		# get intersection with mouse
		[strand, base, position] = @canvas.views.SST.getIntersection()
		if position?

			# update position of brush and cursor
			@updateBrush position, false
			@baseIndex = base

			# fade and record strand
			@canvas.views.SST.fadeStrand strand
			@strands.push strand

			# determine which end should be extended; we set this value
			# here (rather than in mousemove) so that it doesn't jump around 
			# when the user is dragging.
			if base > @strands[0].length()/2
				@extensionEnd = 1;
			else
				@extensionEnd = -1;

	mouseup: () ->

		# for any selected strands
		for strand in @strands

			# extend the strand by amount determined 
			strand.extend(@movement, @extensionEnd)

			# unfade the strand
			@canvas.views.SST.unfadeStrand strand

		# remove the preview
		if @preview then @canvas.scene.remove @preview
		@strands = []

	mousemove: () ->

		# re-enable orbit controls
		@canvas.controls.enabled = true

		# if user has clicked and is dragging a strand
		if @canvas.mouse.isDown

			# calculate displacement of mouse, scale by some factor
			@movement = new THREE.Vector2().subVectors(@canvas.mouse.position, @canvas.mouse.downPosition).length()
			@movement = Math.round(@movement / @scaleFactor)

			# if the user has selected any strands
			if @strands[0]

				# update the status bar
				@set 'status', "Extension: #{@movement} nt"

				# disable the orbit controls
				@canvas.controls.cancel()
				@canvas.controls.enabled = false

				# make a fake model to display a preview of the extension
				# TODO: make multiple previews for multiple strands
				@clone = @strands[0].clone()
				@clone.extend(@movement, @extensionEnd)
				
				# remove old preview object, add new one to the canvas
				if @preview then @canvas.scene.remove @preview
				@preview = @canvas.views.SST.drawStrand @clone
				@canvas.scene.add @preview
		
		# if the user hasn't clicked a strand, just 
		else 
			[strand, base, position] = @canvas.views.SST.getIntersection()
			if position?
				@updateBrush position, false
			
###*
 * Allows the user to add and remove voxels
 * @extends {C3D.tools.AbstractBrush}
###
class C3D.tools.Pointer extends C3D.tools.AbstractBrush
	constructor: () ->
		super arguments...

	instructions: "
	<div class='instructions'>

	#{C3D.tools.InstructionFragments.orbit}

	<hr class='hr-close' />
	                                                Click : <span class='instr-action'><i class='fa fa-cube'></i>         place         </span><br />
	<kbd>Shift</kbd> +                              Click : <span class='instr-action'><i class='fa fa-minus-circle'></i> delete        </span><br />
	<kbd>Alt</kbd> +                                Mouse : <span class='instr-action'><i class='fa fa-arrows-alt'></i>   paint         </span><br />
	<kbd>Shift</kbd> + <kbd>Alt</kbd> +             Mouse : <span class='instr-action'><i class='fa fa-eraser'></i>       erase         </span><br />

	<hr class='hr-close' />
	<div>
		(<kbd>Ctrl</kbd> +) #{C3D.tools.InstructionFragments.arrowKeys} : <span class='instr-action'>Move brush</span>
	</div>
	                                     <kbd>Space</kbd> : <span class='instr-action'><i class='fa fa-cube'></i>         place         </span><br />
	<kbd>Shift</kbd> +                   <kbd>Space</kbd> : <span class='instr-action'><i class='fa fa-minus-circle'></i> delete        </span><br />
	<kbd>Enter</kbd>                                      : <span class='instr-action'>Toggle X-ray</span>
	</div>
	"
	iconCls: "fa-cube"

	init: () ->
		@registerSmartMoveKeys()
		@registerKey 'space', () => @paint null, @brush.position
		@registerKey 'enter', () => @toggleXray()

	activate: () ->
		super arguments...

		# Brush vector
		@lineMaterial = new THREE.LineBasicMaterial({
			color: 0xff00f0,
		})
		@canvas.controls.noKeys = true

	deactivate: () ->
		super arguments...
		@canvas.controls.noKeys = false

	###*
	 * Toggles #xray mode
	###
	toggleXray: () ->
		###*
		 * @property {Boolean} xray
		 * Determines whether x-ray mode is active; if active, voxels around
		 * the {@link #hover brush position} are faded to show interior detail
		###
		@xray = not @xray
		if not @xray and @hovered? 
			@unfadeAround @hovered
			# @canvas.views.Voxels.unfadeVoxel @hovered

	###*
	 * Attempts to move the cursor in the given direction with respect to the
	 * camera's current view. Uses #guessLatticeProjection to guess how this
	 * direction translates to movement on the lattice.
	 * @param  {'+x'/'-x'/'+y'/'-y'/'+z'/'-z'} dir Direction to move
	###
	smartMove: (dir) ->
		@clearHover()
		super dir
		if @canvas.keys.isAltDown
			@paint null, @brush.position
		@setHover @getBrushPosition()

	updateBrush: (position, showBrush=null, brushColor=null) ->
		showBrush ?= (!@canvas.keys.isShiftDown or @xray)
		brushColor ?= (if @canvas.keys.isShiftDown then 2 else 1)
		super position, showBrush, brushColor

	###*
	 * Fades voxels with the given radius around some position
	 * @param  {Number[]} latticePosition 3-component position on the lattice
	 * @param  {Number} [r=2] Radius around which to fade
	###
	fadeAround: (latticePosition, r=2) ->
		dist = (i,j,k) ->
			Math.sqrt((i-latticePosition[0])**2 +
				(j-latticePosition[1])**2 +
				(k-latticePosition[2])**2)
		maxdist = Math.sqrt(3)*r

		for i in [latticePosition[0]-r..latticePosition[0]+r]
			for j in [latticePosition[1]-r..latticePosition[1]+r]
				for k in [latticePosition[2]-r..latticePosition[2]+r]
					@canvas.views.Voxels.fadeVoxel [i,j,k], dist(i,j,k)/maxdist
	###*
	 * Unfades voxels with the given radius around some position
	 * @param  {Number[]} latticePosition 3-component position on the lattice
	 * @param  {Number} [r=2] Radius around which to unfade
	###
	unfadeAround: (latticePosition, r=2) ->
		for i in [latticePosition[0]-r..latticePosition[0]+r]
			for j in [latticePosition[1]-r..latticePosition[1]+r]
				for k in [latticePosition[2]-r..latticePosition[2]+r]
					@canvas.views.Voxels.unfadeVoxel [i,j,k]

	###*
	 * Hovers to the given lattice position
	 * @param  {Number[]} latticePosition 3-component position on the lattice
	###
	setHover: (latticePosition) ->
		###*
		 * @property {Number[]} 3-component position on the lattice of the
		 * currently-hovered voxel
		###
		@hovered = latticePosition
		if @xray then @fadeAround latticePosition
		@canvas.views.Voxels.fadeVoxel latticePosition, 0.1

	###*
	 * Clears the #hover and {@link #unfadeAround unfades} surrounding voxels
	###
	clearHover: () ->
		if @hovered
			if @xray then @unfadeAround @hovered
			@canvas.views.Voxels.unfadeVoxel @hovered
			@hovered = null

	refreshHover: () ->
		if @hovered then hover = @hovered
		@clearHover()
		if hover then @setHover hover

	mousedown: () ->

	mouseup: () ->
		if @canvas.mouse.downPosition.length() > 5 then return

		[intersect, position] = @canvas.views.Voxels.getIntersection({ burrow: @canvas.keys.isShiftDown })
		if intersect then @paint intersect, position
		# render()
		@interact()

	mousemove: () ->
		@interact()

	###*
	 * Paints a cube at the position of the #brush or, if shift is down,
	 * deletes the voxel at the the position of the intersected object
	 * @param  {THREE.Object3D} intersect Intersected cube
	###
	paint: (intersect, position, override=null) ->
		[x, y, z] = override ? [null, null, null]
		if @canvas.keys.isShiftDown
			if not (intersect?.object.isPlane)
				x = x ? position.x
				y = y ? position.y
				z = z ? position.z
				latticePosition = @canvas.lattice.pointToLattice(x, y, z)
				@canvas.getCtrl('Voxels')?.removeAt(latticePosition...)
		else
			if @brush.visible #@brush.position.y != 2000
				x = x ? @brush.position.x
				y = y ? @brush.position.y
				z = z ? @brush.position.z
				latticePosition = @canvas.lattice.pointToLattice(x, y, z)
				@canvas.getCtrl('Voxels')?.addAt(latticePosition...)

	###*
	 * Updates the position of the brush and {@link #paint paints} voxels if
	 * appropriate keys are down
	###
	interact: () =>
		if !@canvas.raycaster? then return

		@clearHover()

		# determine whether to show or hide the brush
		showBrush = !@canvas.keys.isShiftDown or @xray
		brushColor = if @canvas.keys.isShiftDown then 2 else 1

		# get intersection of mouse with voxels
		[intersect, position] = @canvas.views.Voxels.getIntersection { burrow: @canvas.keys.isShiftDown }
		if intersect

			# snap hover position to lattice
			newCube = @canvas.lattice.snap position.x, position.y, position.z
			latticePosition = @canvas.lattice.pointToLattice position.x, position.y, position.z

			# if alt is down, paint with movement of mouse
			if @canvas.keys.isAltDown

				# lock y-position if dragging is beginning
				if !@isAltDragging
					@isAltDragging = true
					@altDragPosition = [null, newCube[1], null]

				if !@currentCube then @currentCube = newCube

				# paint if cursor has moved
				if @currentCube.join('') != newCube.join('')
					@paint intersect, position, (if @canvas.keys.isShiftDown then null else @altDragPosition)

				@currentCube = newCube

			# if shift is down, just update brush
			else if @canvas.keys.isShiftDown
				@isAltDragging = false
				@altDragPosition = null

			# otherwise just update brush
			else
				@isAltDragging = false
				@altDragPosition = null

			@updateBrush(position, showBrush, brushColor)
			@setHover latticePosition

###*
 * Allows the user to paint voxels in rectangular regions by clicking corners
 * of the rectangle
 * @extends {C3D.tools.AbstractBrush}
###
class C3D.tools.Rectangle extends C3D.tools.AbstractBrush
	instructions: """
	<span class="label label-default">1st</span> Click : <span class='instr-action'>Start rectangle  </span><br />
	<span class="label label-default">2nd</span> Click : <span class='instr-action'>Finish rectangle </span><br />
	"""
	iconCls: "fa-external-link"

	activate: () ->
		super arguments...

		@state = {
			painting: false
		}
		@rect = {}
		shape = @canvas.lattice.shape() #[@canvas.lattice.width,@canvas.lattice.depth,@canvas.lattice.height]

		###*
		 * Store an array of temporary brush objects
		###
		@brushes = ndarray([],shape)

	###*
	 * Gets the minimum and maximum extents of the selection, in the following
	 * form:
	 *
	 *		[ [ min_x, min_y, min_z ], [ max_x, max_y, max_z ] ]
	 *
	 * @return {Array} extents
	###
	getExtents: () ->
		min = [ Math.min(@rect.start[0], @rect.end[0]), Math.min(@rect.start[1], @rect.end[1]), Math.min(@rect.start[2], @rect.end[2]) ]
		max = [ Math.max(@rect.start[0], @rect.end[0]), Math.max(@rect.start[1], @rect.end[1]), Math.max(@rect.start[2], @rect.end[2]) ]
		return [min, max]

	###*
	 * Updates the visibility of the #brushes according to the current
	 * {@link #getExtents extents} of the selection
	###
	updatePreview: () ->
		[min, max] = @getExtents()
		box = new THREE.Box3(new THREE.Vector3(min...), new THREE.Vector3(max...))

		# for i in [min[0]..max[0]]
		# 	for j in [min[1]..max[1]]
		# 		for k in [min[2]..max[2]]
		@canvas.lattice.each (a,b,c) =>
			obj = @brushes.get(a,b,c)
			if box.containsPoint new THREE.Vector3(a,b,c)
				if not obj?
					geo = @canvas.lattice.cellGeometry(a,b,c).clone()
					obj = new THREE.Mesh(geo, @brushMaterial)
					[obj.position.x, obj.position.y, obj.position.z] = @canvas.lattice.latticeToPoint(a,b,c)
					@canvas.scene.add obj
					@brushes.set(a,b,c, obj)
				visible(obj, true)
			else
				if obj? then visible(obj, false)

	mousedown: (event) ->
		# if !@canvas.raycaster? then return

	mousemove: (event) ->
		[intersect, position] = @canvas.views.Voxels.getIntersection()
		if intersect
			if @state.painting
					latticePosition = @canvas.lattice.pointToLattice(position.x, position.y, position.z)
					@rect.end = latticePosition
					@updatePreview()
			else
				@updateBrush position
			event.preventDefault()

	mouseup: (event) ->
		if @canvas.mouse.downPosition.length() > 5 then return
		if not @state.painting

			# find an object the cursor intersects
			[intersect, position] = @canvas.views.Voxels.getIntersection()
			if intersect
				latticePosition = @canvas.lattice.pointToLattice(position.x, position.y, position.z)
				@rect.start = latticePosition
				@rect.end = latticePosition

			@state.painting = true

		else
			# create voxels
			[min, max] = @getExtents()
			for i in [min[0]..max[0]]
				for j in [min[1]..max[1]]
					for k in [min[2]..max[2]]
						@canvas.getCtrl('Voxels')?.addAt(i,j,k)

			# remove brushes
			@canvas.lattice.each (a,b,c) =>
				brush = @brushes.get(a,b,c)
				if brush? then @canvas.scene.remove brush
				@brushes.set(a,b,c, undefined)

			@state.painting = false
		event.preventDefault()

###*
 * Allows the user to store multiple voxels as a shape
###
class C3D.Shape
	constructor: (@canvas, @voxels, @anchor) ->
		###*
		 * @property {C3D.models.Voxel} anchor 
		 * "Anchor" voxel; the voxel that the user is dragging, and relative to which
		 * member #voxels should be {@link #displace displaced}.
		###
		###*
		 * @property {C3D.models.Voxel[]} voxels 
		 * Voxels managed by this shape
		###
		undefined
	
	###*
	 * Fades all selected voxels
	###
	fade: () ->
		for voxel in @voxels
			latticePosition = voxel.get 'latticePosition'
			@canvas.views.Voxels.setVoxelOpacity latticePosition, 0.25
	
	###*
	 * Unfades all selected voxels
	###
	show: () ->
		for voxel in @voxels
			latticePosition = voxel.get 'latticePosition'
			@canvas.views.Voxels.setVoxelVisible latticePosition, 1.0

	###*
	 * Get displaced positions for all voxels relative to the current
	 * position of the #anchor voxel
	 * @param  {Number[]} currentPosition latticePosition of the anchor voxel 
	 * @return {Array} 
	 * Array of [latticePosition, voxel] pairs; each pair gives the displaced
	 * 3-element lattice position of the indicated `voxel`.
	###
	displace: (currentPosition) ->
		if @anchor
			anchorPosition = @anchor.get 'latticePosition'
			d = (r - anchorPosition[i]  for r,i in currentPosition)

			newVoxelLatticePositions = for voxel in @voxels
				latticePosition = voxel.get 'latticePosition'
				newLatticePosition = (r + d[i] for r,i in latticePosition)
				[newLatticePosition, voxel]
			return newVoxelLatticePositions		

###*
 * Allows the user to select and manipulate voxels (move and delete)
 * by dragging and dropping.
 * @extends {C3D.tools.Tool}
###
class C3D.tools.Select extends C3D.tools.Tool
	instructions: "Click : select a voxel. <br />
	<kbd>Shift</kbd> + Click : add/remove voxel from selection. <br />
	Drag : move selected voxel(s) <br />"

	iconCls: "fa-hand-o-up"

	init: () ->
		@registerKey 'delete', { exclusive: true, keyup: () => @delete() }

	###*
	 * Get all selected voxels
	 * @return {C3D.models.Voxel[]}
	###
	getSelectedVoxels: () ->
		voxels = _.values @canvas.data.selected
		return voxels
	
	###*
	 * Delete all selected voxels
	###
	delete: () ->
		voxels = @getSelectedVoxels()
		for voxel in voxels
			@canvas.data.remove voxel

	activate: () ->

	deactivate: () ->

	mousedown: () ->
		# get location of mouse
		[intersect, position] = @canvas.views.Voxels.getIntersection({burrow: true})
		if intersect?			
			latticePosition = @canvas.lattice.pointToLattice(
				position.x, position.y, position.z)

			# check if a voxel exists at the mouse position
			voxel = @canvas.ctrls.Voxels.find latticePosition...

			# enable the orbit tool and deselects all voxels when the user clicks the canvas
			if not voxel
				@canvas.controls.enabled = true
				@canvas.data.deselectAll()
			
			# disable orbit tool and add voxel to selection if user clicks on voxel
			else 
				@canvas.controls.enabled = false
				
				if  @canvas.keys.isShiftDown
					voxel?.toggleSelected()
				else if voxel and not voxel.selected
					@canvas.data.deselectAll()
					voxel.select()

				# Create new shape
				@shape = new C3D.Shape @canvas, @getSelectedVoxels(), voxel
				@isShapeClicked = true

	mousemove: () ->
		# get location of mouse
		[intersect, position] = @canvas.views.Voxels.getIntersection({real: true})
		if intersect?
			currentPosition = @canvas.lattice.pointToLattice(
				position.x, position.y, position.z)

			# if the user clicks on a shape voxel
			if @shape and @isShapeClicked

				# hide old proxy voxels
				if @proxy
					for pair in @proxy
						[latticePosition, voxel] = pair
						if not @canvas.ctrls.Voxels.find latticePosition...
							@canvas.views.Voxels.setVoxelVisible latticePosition, false
				
				# create new proxy based on current position	
				newProxy = @shape.displace currentPosition

				# show new proxy voxels
				if newProxy
					@shape.fade()
					for pair in newProxy
						[latticePosition, voxel] = pair
						
						# check that voxel model doesn't exist in proxy position
						if not @canvas.ctrls.Voxels.find latticePosition...
							# show proxy voxel
							@canvas.views.Voxels.setVoxelVisible latticePosition, true
							
							# set color of proxy voxel depending on if they are on the canvas
							if not @canvas.lattice.isOnLattice latticePosition...
								@canvas.views.Voxels.setVoxelColor latticePosition, new THREE.Color('red')
							else
								@canvas.views.Voxels.setVoxelColor latticePosition, new THREE.Color('yellow')
					# set new proxy
					@proxy = newProxy
			
			# otherwise (if not clicked on shape), re-enable orbiting
			else
				@canvas.controls.enabled = true
					

	mouseup: () ->
		@isShapeClicked = false

		# permanently move voxels in the proxy
		if @proxy 
			for pair in @proxy
				[latticePosition, voxel] = pair

				# unfade the old lattice position
				@canvas.views.Voxels.unfadeVoxel voxel.get('latticePosition')

				# remove voxels not on lattice
				if not @canvas.lattice.isOnLattice latticePosition...
					@canvas.views.Voxels.setVoxelVisible latticePosition, false
					voxel.deselect()
					@canvas.data.remove voxel

				# move voxels on lattice
				else
					voxel.moveTo latticePosition...

###*
 * Allows the user to draw strands on the canvas by clicking to choose crossover
 * positions.
 * @extends {C3D.tools.AbstractBrush}
###
class C3D.tools.Strand extends C3D.tools.AbstractBrush
	instructions: """
	<span class="label label-default">1st</span> Click : <span class='instr-action'>Start strand (5')</span><br />
	<span class="label label-default">2nd</span> Click : <span class='instr-action'>Start crossover</span><br />
	<span class="label label-default">3rd</span> Click : <span class='instr-action'>Finish crossover</span><br />
	... <br />
	<span class="label label-default">Double</span> Click / <kbd>Enter</kbd> : <span class='instr-action'>Finish strand (3')</span><br />
	<kbd>Esc</kbd> : <span class='instr-action'>Cancel</span><br />
	"""
	iconCls: "fa-long-arrow-right"

	constructor: () ->
		super arguments...
		@states = {
			SELECT_START: 0
			SELECT_CROSSOVER_BEGIN: 1
			SELECT_CROSSOVER_END: 2
		}
		@reset()
		
	init: () ->
		@registerKey 'esc', (() => @reset(); @updatePreview())	
		@registerKey 'enter', (() => @finish(); @updatePreview())	


	deactivate: () ->
		super arguments...
		if @preview then @canvas.scene.remove @preview

	reset: () ->
		@state = @states.SELECT_START
		@segments = []
		@current_segment = []
		delete @strand_5p
		delete @strand_3p

	getRouting: () ->
		_.cat @segments..., @current_segment

	###*
	 * Creates a C3D.models.SST for a given routing
	 * @param  {Array} [routing] (Defaults to #routing)
	 * @return {C3D.models.SST}
	###
	createModel: (routing=undefined) ->
		routing = routing ? @getRouting()
		if @strand_5p
			routing_5p = _.clone @strand_5p.get 'routing'
			routing = routing_5p.concat routing
		if @strand_3p
			routing_3p = _.clone @strand_3p.get 'routing'
			routing = routing.concat routing_3p

		new C3D.models.SST { plane: 'X', routing: routing }

	finish: () ->
		if @strand_5p then @canvas.data.remove @strand_5p
		if @strand_3p then @canvas.data.remove @strand_3p

		# create strand
		@canvas.data.add @createModel()
		
		# return to default state
		@reset()

	###*
	 * Updates the preview displayed in the canvas
	###
	updatePreview: () ->
		routing = @getRouting()
		if @preview then @canvas.scene.remove @preview
		if routing.length > 0
			@preview = @canvas.views.SST.drawStrand @createModel(routing)
		else
			lp = @getCursorPosition()
			latticePosition = lp[0..2]
			len = @canvas.lattice.length latticePosition...
			dir = if lp[3] > (len / 2) then 1 else -1
			routing = @domain(latticePosition, dir, len)
			@preview = @canvas.views.SST.drawStrand @createModel(routing)
		@canvas.scene.add @preview

	###*
	 * Builds a new base
	 * @param  {Array} pos 4-component position
	 * @param  {1/-1} dir Direction of the base
	 * @param  {Object} options Other options
	 * @return {Object} Base
	###
	base: (pos, dir, options) ->
		options = options ? {}
		_.extend { pos: pos, dir: dir }, options

	###*
	 * Builds a new domain
	 * @param  {Array} pos 3-component voxel position
	 * @param  {1/-1} dir Direction of the domain
	 * @param  {Number} dlen Length of the domain in bases
	 * @param  {Object} options Other options
	 * @return {Object} Domain
	###
	domain: (pos, dir, dlen=domain_length, options) ->
		options = options ? {}
		if dir is 1
			for i in [0...dlen]
				_.extend({ pos: pos.concat([i]), dir: dir }, options)
		else
			for i in [dlen-1..0] by -1
				_.extend({ pos: pos.concat([i]), dir: dir }, options)

	###*
	 * Generates a routing from the given starting position to the given ending position
	 * @param  {Number} start 4-component lattice position to start
	 * @param  {Number} end   4-component lattice position to end
	 * @param  {-1/1} dir     Direction to proceed (1 for 5' to 3', -1 for 3' to 5')
	 * @return {vox.dna.Base[]} 
	###
	route: (start, end, dir) ->
		[x_s, y_s, z1_s, z2_s] = start
		[x_e, y_e, z1_e, z2_e] = end

		x = x_s
		y = y_s

		bases = []

		for z1 in [z1_s..z1_e] by dir
			if dir is 1 
				z2_1 = 0
				z2_2 = (@canvas.lattice.length x, y, z1)-1
			else if dir is -1
				z2_1 = (@canvas.lattice.length x, y, z1)-1
				z2_2 = 0


			if z1 is z1_s and z1_s?
				z2_1 = z2_s
			if z2 is z1_e and z2_e?
				z2_2 = z2_e

			for z2 in [z2_1..z2_2] by dir
				bases.push @base [x, y, z1, z2], dir

		bases

	dblclick: () ->
		@finish() 

	mouseup: () ->
		# ignore dragging motion
		if @canvas.mouse.downPosition.length() > 5 then return

		# get cursor position from last mouse move
		lp = @getCursorPosition()
		latticePosition = lp[0..2]
		len = @canvas.lattice.length latticePosition...

		# if @keys.isShiftDown
		# 	switch @state
		# 		when @states.SELECT_START then null
		# 		when @states.SELECT_CROSSOVER_BEGIN

		# 		when @states.SELECT_CROSSOVER_END
		# 			@current_segment = []
		# 			@state = @states.SELECT_CROSSOVER_BEGIN
		# 	return

		switch @state 
			when @states.SELECT_START
				if @strand_5p?
					base = 0
					@direction = @strand_5p.getBase(base)?.dir
					# @canvas.views.SST.fadeStrand @strand
					@segment_start = { pos: _.clone(@strand_5p.getBase(base).pos) }	
				else 
					@direction = if lp[3] > (len / 2) then 1 else -1
					@segments.push @domain(latticePosition, @direction, len)
					@segment_start = { pos: latticePosition.concat([if @direction is 1 then (len-1) else 0]) }
				@state = @states.SELECT_CROSSOVER_BEGIN

			when @states.SELECT_CROSSOVER_BEGIN
				@segments.push @current_segment
				@current_segment = []
				@state = @states.SELECT_CROSSOVER_END

			when @states.SELECT_CROSSOVER_END
				if @strand_3p?
					@finish()
				else 
					@segments.push @current_segment
					@current_segment = []
					@segment_start = { pos: latticePosition.concat([if @direction is 1 then (len-1) else 0]) }
					@state = @states.SELECT_CROSSOVER_BEGIN

	mousemove: () ->

		# unfade any previous strand
		if @strand_5p 
			@canvas.views.SST.unfadeStrand @strand_5p
		if @strand_3p 
			@canvas.views.SST.unfadeStrand @strand_5p

		# get intersections with mouse
		# snap to strand if possible
		[strand, base, position] = @canvas.views.SST.getIntersection()
		if strand? and base?
			lp = _.clone strand.getBase(base)?.pos
		else
			# otherwise get nearest voxel position
			[intersect, position] = @canvas.views.Voxels.getIntersection()
	
		if not position? then return 

		# update position of brush and cursor
		@updateBrush position, false
		if not lp?
			lp = @getCursorPosition()

		# if we found a cursor position
		if lp?
			latticePosition = lp[0..2]
			len = @canvas.lattice.length latticePosition...

			switch @state
				when @states.SELECT_START
					if strand? and (base is 0 or base is strand.length()-1)
						@strand_5p = strand
						@direction = strand.getBase(base)?.dir
						@canvas.views.SST.fadeStrand @strand_5p
					else 
						@strand_5p = null
						@direction = if lp[3] > (len / 2) then 1 else -1


				when @states.SELECT_CROSSOVER_BEGIN
					segment_start = @segment_start
					segment = []
					dir = vox.lit.cmp lp[2..3], segment_start.pos[2..3]
					# dir = signum(latticePosition[2] - segment_start.pos[2])
					@direction = dir

					# generate routing from segment_start to latticePosition
					# if dir != 0 
					# 	for i in [segment_start.pos[2]+dir..latticePosition[2]] by dir
					# 		pos = [segment_start.pos[0], segment_start.pos[1], i]
					# 		len = @canvas.lattice.length pos...
					# 		segment = segment.concat @domain( pos, dir, len, {} )
					if dir isnt 0
						segment = @route segment_start.pos, lp, dir

					@current_segment = segment

				when @states.SELECT_CROSSOVER_END
					if strand? and (base is 0 or base is strand.length()-1)
						@strand_3p = strand
						@direction = strand.getBase(base)?.dir
						@canvas.views.SST.fadeStrand @strand_3p
						@current_segment = [ _.clone strand.getBase(base) ]
					else 
						@strand_3p = null
						@direction = if lp[3] > (len / 2) then 1 else -1
						@current_segment = [ @base( latticePosition.concat([if @direction is 1 then (len-1) else 0]), @direction, {} ) ]

			@updatePreview()
			event.preventDefault()


class C3D.tools.CaDNAnoImporter extends C3D.tools.AbstractBrush
	name: "Import structure from caDNAno"
	iconCls: "fa-import"
	instructions: """
	Click to place origin of caDNAno structure on canvas, or press <kbd>Enter</kbd> to place in default position <br />
	<kbd>Shift</kbd> : Flip X axis<br />
	<kbd>Alt</kbd> : Flip Y axis<br />
	"""
	showInToolbar: false

	constructor: () ->
		super arguments...

	deactivate: () ->
		super arguments...
		@doCallback null

	init: () ->
		@registerKey 'enter', () => @place [0,0,0,0]	
		@registerKey 'esc', () => @canvas.setActiveTool 'Orbit'	

	mousemove: () ->
		# get intersections with mouse
		[intersect, position] = @canvas.views.Voxels.getIntersection()
		if intersect

			# update position of brush and cursor
			@updateBrush position
			
	mouseup: () ->
		if @canvas.mouse.downPosition.length() > 5 then return
		
		reflect = [ @canvas.keys.isShiftDown, @canvas.keys.isAltDown ]

		lp = @getCursorPosition()
		@place lp, reflect

	import: (data, callback) ->
		@data = data
		@callback = callback

	place: (offsets, reflect) ->
		options = {
			offsets: offsets
			reflect: reflect
		}
		@canvas.ctrls.SST.fromCaDNAno @data, options
		@canvas.setActiveTool 'Pointer'
		@doCallback null

	doCallback: () ->
		if @callback?
			@callback arguments...
		delete @callback


class C3D.tools.Importer extends C3D.tools.Tool
	name: "Import Model"
	iconCls: "fa-import"
	instructions: """
	Position the imported model on the canvas
	<hr class='hr-close' />
	<kbd>S</kbd> : Center <br />
	<kbd>D</kbd> : Scale to fit 
	<hr class='hr-close' />
	<kbd>Q</kbd> : World &harr; Local coordinates <br />
	<kbd>W</kbd> : Translate mode <br />
	<kbd>E</kbd> : Scale mode <br />
	<kbd>R</kbd> : Rotate mode <br />
	<kbd>A</kbd> : Toggle wireframe 
	<hr class='hr-close' />
	<kbd>Enter</kbd> : Voxelize mesh <br />
	<kbd>Esc</kbd> : Cancel <br />
	"""
	showInToolbar: false

	init: () ->
		@registerKey 'w', () => @setMode 'translate'
		@registerKey 'e', () => @setMode 'scale'
		@registerKey 'r', () => @setMode 'rotate'
		@registerKey 'q', () => @toggleSpace()
		@registerKey 'a', () => @toggleWireframe()
		@registerKey 's', () => @center()
		@registerKey 'd', () => @scaleToFit()
		@registerKey 'enter', () => @voxelize()
		@registerKey 'esc', () => @canvas.setActiveTool 'Orbit'	

	activate: () ->
		super arguments...
		# @canvas.controls.noRotate = true
		@canvas.controls.addEventListener 'change', @updateControls

	deactivate: () ->
		# @canvas.controls.noRotate = false
		@reset()
		@canvas.controls.removeEventListener 'change', @updateControls
		@doCallback null

	reset: () ->
		if @controls
			@canvas.scene.remove @controls
			@controls.detach()
			delete @controls
		if @mesh
			@canvas.scene.remove @mesh
			delete @mesh

	###*
	 * Attaches this tool to an imported `mesh`
	 * @param  {THREE.Object3D/THREE.Mesh} mesh
	 * Imported object; will be added to the {@link C3D.Canvas3D#scene}.
	 *
	 * @private
	###
	attach: (mesh) ->
		###*
		 * @property {THREE.Object3D/THREE.Mesh} mesh
		 * An object to be positioned/rotated/scaled on the scene and then
		 * {@link #voxelize voxelized}.
		###
		@mesh = mesh
		@canvas.scene.add @mesh

		###*
		 * @property {THREE.TransformControls} controls
		 * Displays gizmos for scaling, moving, and rotating the #mesh
		 * within the scene
		###
		@controls = new THREE.TransformControls( @canvas.camera, @canvas.renderer.domElement )
		@controls.attach @mesh
		@canvas.scene.add @controls

	###*
	 * Switches the #mesh between wireframe and normal views
	###
	toggleWireframe: () ->
		if @mesh?
			if @mesh instanceof THREE.Mesh
				meshes = [@mesh]
			else if @mesh.children?
				meshes = @mesh.children

			if meshes? then for mesh in meshes
				mesh.material.wireframe = not mesh.material.wireframe

	###*
	 * Imports the passed `data` using the passed `importer` object
	 * @param  {Mixed} data
	 * Data to send to the importer. Can be a string (for text formats) or
	 * a BinaryString (for binary formats).
	 * @param  {THREE.Importer/Object} importer
	 * @param {Function} importer.parse
	 * Function which accepts `data` and returns an object or mesh
	 * @param {Mixed} importer.parse.data
	 * @param {THREE.Object3D/THREE.Mesh} importer.parse.return
	###
	import: (data, importer, callback) ->
		@reset()

		object = importer.parse data
		if (object instanceof THREE.Geometry) or (object instanceof THREE.BufferGeometry)
			material = new THREE.MeshLambertMaterial()
			mesh = new THREE.Mesh object, material
		else mesh = object
		@attach mesh

		@callback = callback

	###*
	 * Sets the mode of the #controls
	 * @param {'translate'/'scale'/'rotate'} mode
	###
	setMode: (mode) ->
		@controls?.setMode mode

	###*
	 * Sets the coordinate space of the #controls
	 * @param {'local'/'world'} space
	###
	setSpace: (space) ->
		@controls?.setSpace space

	###*
	 * Toggles the {@link #setSpace coordinate space} between
	 * `'local'` and `'world'`.
	###
	toggleSpace: () ->
		if @controls?.space is 'world' then @setSpace 'local'
		else if @controls?.space is 'local' then @setSpace 'world'

	###*
	 * Forces the #controls to be updated to the current position/scale/
	 * rotation of the #mesh
	###
	updateControls: () =>
		if @controls? then @controls.update()

	###*
	 * Gets the 3D bounding box of the attached #mesh
	 * @return {THREE.Box3}
	###
	getMeshBox: () ->
		box = if @mesh.geometry? then @mesh.geometry.boundingBox.clone()
		else new THREE.Box3().setFromObject(@mesh)

		box.applyMatrix4 @mesh.matrix

	###*
	 * Scales the #mesh so that the largest dimension fits within the scene
	###
	scaleToFit: () ->
		max = @canvas.lattice.latticeToPoint @canvas.lattice.max()...
		min = @canvas.lattice.latticeToPoint @canvas.lattice.min()...
		box = new THREE.Box3(new THREE.Vector3(min...), new THREE.Vector3(max...))

		meshBox = @getMeshBox()
		scale = box.size().divide(meshBox.size())
		factor = Math.min scale.x,scale.y,scale.z

		# @mesh.applyMatrix new THREE.Matrix4().makeScale(scale.x,scale.y,scale.z)
		@mesh.applyMatrix new THREE.Matrix4().makeScale factor, factor, factor
		@updateControls()

	###*
	 * Centers the #mesh within the {@link vox.lattice.Lattice#centroid}
	###
	center: () ->
		center = new THREE.Vector3 @canvas.lattice.latticeToPoint(@canvas.lattice.centroid()...)...
		meshCenter = @getMeshBox().center()
		diff = center.sub meshCenter

		@mesh.applyMatrix new THREE.Matrix4().makeTranslation(diff.x,diff.y,diff.z)
		@updateControls()

	###*
	 * Transforms the #mesh into a set of voxels
	###
	voxelize: () =>
		# normalize THREE.Mesh or THREE.Object3D into a collection of objects
		objects = if @mesh instanceof THREE.Mesh then [@mesh] else if @mesh.children? then @mesh.children

		lineLength = (v1, v2) ->
			# Retrieve the distance between two vertices
			new THREE.Vector3().subVectors(v1, v2).length()

		halfPoint = (v1, v2) ->
			# Retrieve the point halfway between two vertices
			new THREE.Vector3().addVectors(v1, v2).divideScalar(2)

		sierpinskify = (threshold, ve1, ve2, ve3) ->
			# Split a triangular mesh into smaller triangles until all edges are below
			# the given threshold.
			result = []
			# initialize queue with first face
			q = [[ve1, ve2, ve3]]
			while q.length > 0
				# pull a triangle from the queue
				vals = q.shift()
				v1 = vals[0]
				v2 = vals[1]
				v3 = vals[2]
				# if the triangle is small enough, add its vertices to the result
				if (lineLength v1, v2) < threshold and (lineLength v2, v3) < threshold and
				(lineLength v3, v1) < threshold
					result.push [v1, v2, v3]... 
				# otherwise, split the triangle into four smaller triangles and add those to queue
				else
					pts = [v1, (halfPoint v1, v2), v2, (halfPoint v2, v3), v3, (halfPoint v3, v1)]
					q.push [
						[pts[5], pts[0], pts[1]]
						[pts[1], pts[2], pts[3]]
						[pts[3], pts[4], pts[5]]
						[pts[1], pts[3], pts[5]]
					]...
			result

		for o in objects
			# update the object's world matrix
			o.updateMatrixWorld()
			geometry = o.geometry

			allVert = []
			# define a threshold for the maximum edge length on a triangular face
			thresh = 0.8 * (Math.min @canvas.lattice.cell...)

			# apply the matrix transformation to each vertex in the geometry
			geometry.applyMatrix o.matrixWorld

			for face in geometry.faces
				# retrieve vertex information for each face
				a = geometry.vertices[face.a]
				b = geometry.vertices[face.b]
				c = geometry.vertices[face.c]

				# split the triangular face into smaller triangles, if necessary
				allVert.push (sierpinskify thresh, a, b, c)...
			
			for v in allVert
				# add a voxel at the location of every vertex in the modified mesh
				latticePosition = @canvas.lattice.pointToLattice v.x, v.y, v.z
				@canvas.ctrls.Voxels.addAt latticePosition...

		@canvas.setActiveTool 'Pointer'
		@doCallback null

	doCallback: () ->
		if @callback?
			@callback arguments...
		delete @callback
