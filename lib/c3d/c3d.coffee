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

global = global ? window ? do () -> this

_ = require('underscore')
$ = require('jquery')

###*
 * @class Backbone
 * @singleton
 * @static
 * Global object for Backbone library; see full docs at [http://backbonejs.org/](http://backbonejs.org/)
###
###*
 * @class Backbone.Model
 * @mixin Backbone.Events
 * Base class representing a model with attributes that fire events when changed. See
 * http://backbonejs.org/#Model for full documentation.
###
###*
 * @method get
 * Get the current value of an attribute from the model. For example: `note.get("title")`
 * 
 * @param {String} attribute Attribute to get
 * @return {Mixed} value of the attribute
###
###* 
 * @method set
 * 
 * Set a hash of attributes (one or many) on the model. If any of the attributes 
 * change the model's state, a `change` event will be triggered on the model. 
 * Change events for specific attributes are also triggered, and you can bind to 
 * those as well, for example: `change:title`, and `change:content`. You may also 
 * pass individual keys and values.
 * 
 *     note.set({title: "March 20", content: "In his eyes she eclipses..."});
 *    
 *     book.set("title", "A Scandal in Bohemia");
 *
 * @param {String/Object} attribute(s)
 * @param {Object} [options]
 * @param {Boolean} [options.silent=true] Don't fire `change` or `change:` events
###
###* 
 * @method has
 * 
 * Returns true if the attribute is set to a non-null or non-undefined value.
 * 
 *     if (note.has("title")) {
 *       ...
 *     }
 * 
 * @param {String} attribute
 * @return {Boolean} `true` if the attribute is non-null or non-undefined, else `false`
###
###* 
 * @method unset
 * 
 * Remove an attribute by deleting it from the internal attributes hash. Fires a 
 * "change" event unless `silent` is passed as an option.
 * 
 * @param {String} attribute
 * @param {Object} [options]
 * @param {Boolean} [options.silent=true] Don't fire `change` or `change:` events
###
###* 
 * @method clear
 * 
 * Removes all attributes from the model, including the id attribute. Fires a 
 * "change" event unless `silent` is passed as an option.
 * 
 * @param {Object} [options]
 * @param {Boolean} [options.silent=true] Don't fire `change` or `change:` events
###
###* 
 * @method clone
 * 
 * Returns a copy of the model.
 *
 * @return {Backbone.Model} copy of the model
###
###*
 * @event change
 *
 * Fired when an attribute of the model is changed using {@link #set}.
 * 
 * @param {String} name Name of the attribute that changed
 * @param {Backbone.Model} model Reference to this model
 * @param {Object} value New value of the attribute
 * 
###


###*
 * @class  Backbone.Events
 * A module that can be mixed in to *any object* in order to provide it with
 * custom events. You may bind callback functions to an event with #on or 
 * remove them with #off. {@link #trigger triggering} an event fires all 
 * callbacks in succession.
 * 
 *     var object = {};
 *     _.extend(object, Backbone.Events);
 *     object.on('expand', function(){ alert('expanded'); });
 *     object.trigger('expand');
###
###*
 * @method on
 * Bind an event to a `callback` function. Passing `"all"` will bind
 * the callback to all events fired.
 * 
 * @param {String} name 
 * Name of the event to be fired.
 * 
 * @param {Function} callback 
 * Function to be executed when the event is fired. This function will
 * be passed any arguments that the event provides.
 * 
 * @param {Object} [context] 
 * Context in which to execute the callback function
###
###*
 * @method once
 * Bind an event to only be triggered a single time. After the first time
 * the callback is invoked, it will be removed.
 * 
 * @param {String} name 
 * Name of the event to be fired.
 * 
 * @param {Function} callback 
 * Function to be executed when the event is fired. This function will
 * be passed any arguments that the event provides.
 * 
 * @param {Object} [context] 
 * Context in which to execute the callback function
###
###*
 * @method off
 * Remove one or many callbacks previously added with {@link #on}. 
 *
 * @param {String} name 
 * Name of the event to stop listening to. If `name` is null, removes all 
 * bound callbacks for all events.
 * 
 * @param {Function} callback 
 * Callback function to stop executing.  If `callback` is null, removes all
 * callbacks for the event. 
 * 
 * @param {Object} [context] 
 * Context in which to execute the callback function. If `context` is null, 
 * removes all callbacks with that function. 
###
###*
 * @method trigger
 * Trigger one or many events, firing all bound callbacks. Callbacks are
 * passed the same arguments as `trigger` is, apart from the event name
 * (unless you're listening on `"all"`, which will cause your callback to
 * receive the true name of the event as the first argument).
 *
 * @param {String} name Name of hte vent to trigger. 
###


Backbone = require('backbone')
Backbone.Select = require('backbone.select')
Backbone.$ = $
require('backbone-undo')(_, Backbone)
PageableCollection = require("backbone.paginator")

###*
 * @class THREE
 * @singleton
 * @static
 * Global object for three.js library; see docs at [threejs.org/docs/](http://threejs.org/docs/).
###
THREE = require('three')
require('./three/BufferGeometry.merge')(THREE) # monkey-patch THREE.BufferGeometry
THREE.OrbitControls = require('./three/OrbitControls')
THREE.FlyControls = require('./three/FlyControls')
# THREE.PointerLockControls = require('./three/PointerLockControls')

THREE.CombinedCamera = require('./three/CombinedCamera')
THREE.EdgesHelper = require('./three/EdgesHelper')
THREE.SVGRenderer = require('./three/SVGRenderer')
THREE.STLExporter = require('./three/STLExporter')
THREE.OBJExporter = require('./three/OBJExporter')
THREE.AnaglyphEffect = require('./three/AnaglyphEffect')
# THREE.Projector = require('./three/Projector')

THREE.STLLoader = require('./three/STLLoader')
THREE.PDBLoader = require('./three/PDBLoader')
THREE.VRMLLoader = require('./three/VRMLLoader')
THREE.OBJLoader = require('./three/OBJLoader')
THREE.TransformControls = require('./three/TransformControls')
require('./three/Octree')(THREE)

###*
 * @class ndarray
 * Constructor for N-dimensional arrays; see docs at [https://github.com/mikolalysenko/ndarray](https://github.com/mikolalysenko/ndarray).
###
ndarray = require('ndarray')
ndhash = require("ndarray-hash")
cwise = require('cwise')
pool = require('ndarray-scratch')

semver = require('semver')

global.vox = require('../vox')
VERSION = require('../version')

THREE.Raycaster::pickingRay = ( coords, camera ) ->

    # the camera is assumed _not_ to be a child of a transformed object

    if camera instanceof THREE.PerspectiveCamera or camera.inPerspectiveMode

        this.ray.origin.copy( camera.position );

        this.ray.direction.set( coords.x, coords.y, 0.5 ).unproject( camera ).sub( camera.position ).normalize();

    else if camera instanceof THREE.OrthographicCamera or camera.inOrthographicMode

        this.ray.origin.set( coords.x, coords.y, - 1 ).unproject( camera )

        this.ray.direction.set( 0, 0, - 1 ).transformDirection( camera.matrixWorld )

    else 

        console.error( 'ERROR: Raycaster.js encountered an unknown camera type.' )

###*
 * @class C3D
 * Supports an interactive 3D canvas rendered by THREE.js
 * @static
 * @singleton
###
C3D = module.exports ? this

DEBUG = C3D.DEBUG = true

debug = C3D.debug = () -> if DEBUG then console.log arguments...

guid = C3D.guid = do () ->
	s4 = () ->
	    Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
	
	return () ->
		s4() + s4() + '-' + s4() + '-' + s4() + '-' +
		s4() + '-' + s4() + s4() + s4()

signum = C3D.signum = (x) ->
	if x > 0 then 1 else if x < 0 then -1 else 0

each3d = vox.utils.each3d

visible = C3D.visible = (obj, vis) ->obj.traverse( (o) -> o.visible = vis )

compile = C3D.compile = (script) ->
	coffee = require('coffee-script')
	eval(coffee.compile(script, { bare: true }))

getShader = C3D.getShader = (shaderStr) -> 
	shaderStr.replace /^(\s+)#include\s+(\S+)/gim, ( match, indent, p1 ) ->
		lines = (THREE.ShaderChunk[ p1 ] ? "").split("\n")
		lines.unshift "// BEGIN #{p1} "
		lines.push    "// END #{p1}"
		(indent + line for line in lines when line.trim() isnt "").join("\n")

C3D.index = index = vox.index

###*
 * Mixes the prototypes of each element of `mixins` into `base`.
 *
 * Usage:
 *
 *     class MyClass:
 *         mixin @, MyMixin1, MyMixin2, MyMixin3 # etc.
 *         # rest of the class body
 *
 * @param  {Function} base The base class (class to mix into)
 * @param  {Function[]} mixins... Array of mixin classes
###
mixin = C3D.mixin = (base, mixins...) ->
	_.extend(base::, mix::) for mix in mixins

###*
 * Initializes each class in `classes` from the namespace `from`, using the given `arguments`
 * @param  {String[]} classes Array of class names
 * @param  {Object} from Namespace from which to pull the classes
 * @param  {Array} args... List of arguments to pass to the constructors
 * @return {Object} Hash mapping the class names from `classes` to the instantiated objects
###
initialize = C3D.initialize = (classes, from, args...) ->
	objs = {}
	for cls in classes
		if cls of from then objs[cls] = new from[cls](args...)
	return objs

###*
 * @class _
 * @alias underscore
 * NanoBricks-specific mixins to Underscore.js. See full docs for underscore at [http://underscorejs.org/](http://underscorejs.org/).
###
_.mixin
	###*
	 * Converts an object to a plain JSON representation, recursively searching for objects
	 * with a defined toJSON method and converting them as well. This can be used to
	 * recursively create a JSON object for a complex network of, e.g. {@link Backbone.Model}s.
	 *
	 * @param  {Mixed} o Object to serialize
	 * @param  {Boolean} [noop=false]
	 * true to ignore the `.toJSON` member of `o` (useful if you want to
	 * use this function as the implementation of `o`'s `toJSON` function
	 *
	 * @return {Object} Serialized JSON version of the object
	###
	toJSON: (o,noop) ->
		noop || (noop = false);

		# if o defines its own serialization function (ie: for higher level objects), use that
		if (!noop && o && o.toJSON && _.isFunction(o.toJSON))
			return o.toJSON()

		# serialize an array
		if (_.isArray(o))
			return (_.toJSON(x) for x in o)

		# serialize a simple object hash (allow for complex objects contained in the hash)
		if (_.isObject(o))
			r = {};
			for own p, v of o
				r[p] = _.toJSON(v);
			return r;

		# no serialization needed
		return o;

	###*
	 * Vivifies an object by instantiating a class. First finds the class by
	 * examining the object's `_class` member, which should be a string
	 * representing a keypath within some `root` object (defaults to `global`).
	 *
	 * Example:
	 *
	 *     _.vivify({ _class: 'Foo.bar.Baz', option: 'foo', ... })
	 *     // == new Foo.bar.Baz({ option: 'foo', ... })
	 *
	 *     _.vivify({ _class: 'bar.Baz', option: 'foo', ... }, Foo)
	 *     // == new Foo.bar.Baz({ option: 'foo', ... })
	 *
	 * @param  {Object} o Object to vivify
	 * @param  {String} o._class Fully-qualified name of the class to use for vifification
	 * @param  {Object} [root=global] Root object to use for lookup of classes
	 * @return {Object} Result of instantiating the class
	###
	vivify: (o, root=global) ->
		if o._class
			cls = index(root,o._class)
			new cls(o)
		else o

###*
 * @class  C3D.Uniqueue
 * Maintains a queue of unique items, where an item will be added only if it's 
 * not already on the queue. 
###
class C3D.Uniqueue
	constructor: () ->
		@queue = []
		@keys = {}

	###*
	 * Adds an object to the queue with the given key
	 * @param  {Object} object 
	 * @param  {String} key    
	 * Unique key; objects with the same key as an object already on the queue will not be added
	###
	enqueue: (object, key) ->
		if key? 
			if key of @keys then return  
			@keys[key] = object
		@queue.push [key, object]

	###*
	 * Remove the first object added to the queue
	 * @return {Object} 
	###
	dequeue: () ->
		if @queue.length is 0 then return 
		[key, object] = @queue.shift()
		if key? then delete @keys[key] 
		object

	###*
	 * Gets the current length of the queue
	 * @return {Number} 
	###
	length: () -> @queue.length

###*
 * @class C3D.Timer
 * Gets the duration since a certain time
 *
 *    t = new C3D.Timer()
 *    for x in [0...100000]
 *    	console.log 'foo'
 *    console.log 'That took ' + t.duration() = ' ms'
 * 
###
class C3D.Timer
	constructor: () ->
		@start = new Date()

	duration: () ->  (new Date()) - @start

###*
 * @class  C3D.Base
 * Serializable Backbone.Model. Include this in classes using global#mixin
 * @abstract
###
class C3D.Base # extends Backbone.Model
	###*
	 * Returns a deep copy of the provided object, which will be a simple
	 * object. Recursive structures are intelligently handled. If objects
	 * have their own `serialize` method defined, that is used.
	 * @param {Mixed} o
	 * @param {Boolean} isChild
	###
	toJSON: () ->
		return _.toJSON @attributes

###*
 * Serializable Backbone.Collection
 * @extends Backbone.Collection
 * @mixin Backbone.Select.Many
###
class C3D.SerializableCollection extends Backbone.Collection
	initialize: (models) ->
		Backbone.Select.Many.applyTo @, models


	###*
	 * Serializes this collection to a JSON string by calling {@link _#toJSON}
	 * on #models
	 * @return {Object} Serialized models
	###
	toJSON: () ->
		###*
		 * @property {Backbone.Model[]} models
		 * Array of models in the collection
		###
		return _.toJSON @models

	###*
	 * Called whenever a bare JSON object is added to the model in order
	 * of {@link _#vivify vivify} the object
	 * @param  {Object} o
	 * @return {C3D.Base} vivified object
	###
	parse: (o) ->
		_.vivify o

###*
 * @class  C3D.Legacy
 * @static
 * @singleton
 *
 * Handles conversion of legacy .nbk files to be compatible with the current version of NanoBricks
###
C3D.Legacy = 
	###*
	 * @property {Object} adapters
	 * Hash mapping a [semver](http://semver.org/) range to a translation 
	 * function. The translation function should accept a parsed `.nbk` file
	 * (as an Object) and return an updated file (as an Object).
	###
	adapters:  
		"<=0.4.0": (file) ->
			# find lattice and attach
			if not file.lattice
				lattice = _.find file.data, (m) -> m?['_class']?.indexOf('vox.lattice') isnt -1
				if lattice? 
					file.lattice = lattice

			# clear translation schemes
			file.data = _.filter file.data, (o) ->
				o?['_class']?.indexOf('C3D.models.ts.') is -1

			file

class C3D.Canvas3D extends Backbone.Model
	mixin @, C3D.Base

	###*
	 * @class C3D.Canvas3D
	 * @extends Backbone.Model
	 *
	 * Represents a 3D canvas, rendered using WebGL. Manages a
	 * {@link #property-data collection} of {@link C3D.models.Model models},
	 * {@link #property-ctrls controllers} to manage those models,
	 * {@link #property-views views} to render the models to a 3D {@link #scene},
	 * and {@link #property-tools tool} to handle user interactions.
	 *
	 * @constructor
	 * Initializes a Canvas3D object with members in the configuration object
	 * @param  {Object} config Configuration members to copy to `this`
	###
	constructor: (config) ->
		config = config ? {}

		# hmmm these should probably be in the config section...
		_.extend @, {

			###*
			 * @cfg {String[]} tools
			 * List of names of C3D.tools.Tool subclasses to be added to this canvas
			###
			tools: ['Orbit', 'Pointer', 'Select', 'Rectangle', 'Importer', 'CaDNAnoImporter', 'Strand', 'StrandEraser', 'StrandExtender',  'StrandCutter', 'StrandLigator']

			###*
			 * @cfg {String[]} views
			 * List of names of C3D.views.View subclasses to be added to this canvas
			###
			views: ['Voxels','SST','Sequences']

			###*
			 * @cfg {String[]} ctrls
			 * List of names of C3D.ctrls.Controller subclasses to be added to this canvas
			###
			ctrls: ['Voxels','SST','Sequences']

			###*
			 * @property {Object} serializable
			 * Hash indicating which properties should be serialized when saving to a `.nbk` file
			 * with #saveFile. To indicate that a property should be serialized, set its name
			 * as a key of this hash, with the value `true`, e.g.
			 *
			 *    @canvas.serializable['lattice'] = true
			 * 
			###
			serializable: {'data': true}
		}

		super { activeTool: null }

		# vivify canvas properties
		for key, value of config
			if value?
				@[key] = _.vivify value

		###*
		 * @property {C3D.SerializableCollection} data
		 * Collection of models managed by this canvas
		###
		@_data = @data ? []
		@data = new C3D.SerializableCollection()

		# initialize controllers, tools, and views

		###*
		 * @property {Object} ctrls
		 * Mapping of controller names to instances of C3D.ctrls.Controller subclasses
		###
		_ctrls = _.clone @ctrls
		@ctrls = initialize @ctrls, C3D.ctrls, @
		@ctrlsList = (@ctrls[c] for c in _ctrls)

		###*
		 * @property {Object} tools
		 * Mapping of tool names to instances of C3D.tools.Tool subclasses
		###
		_tools = _.clone @tools
		@tools = initialize @tools, C3D.tools, @
		@toolsList = (@tools[t] for t in _tools)

		###*
		 * @property {Object} views
		 * Mapping of view names to instances of C3D.views.View subclasses
		###
		_views = _.clone @views
		@views = initialize @views, C3D.views, @
		@viewsList = (@views[v] for v in _views)

		# initialize mouse & keys

		###*
		 * @property {C3D.Canvas3D.MouseState} mouse
		 * Gives information about the current state of the mouse
		###
		@mouse = new C3D.Canvas3D.MouseState()

		###*
		 * @property {C3D.Canvas3D.KeyState} keys
		 * Gives information about the current state of the keyboard
		###
		@keys = new C3D.Canvas3D.KeyState()

		# initialize data
		@data.on("add", @onModelAdd, @)
		@data.on("change", @onModelChange, @)
		@data.on("remove", @onModelRemove, @)
		@data.on("select:all", @onSelectionChange, @)
		@data.on("select:none", @onSelectionChange, @)
		@data.on("select:some", @onSelectionChange, @)

		###*
		 * Handles #undo and #redo functionality; automatically tracks `change`
		 * events on #data, memorizing them and allowing them to be undone
		 * @property {Backbone.UndoManager}
		###
		@undoMgr = new Backbone.UndoManager({
			register: [@data]
			track: true # changes will be tracked right away
		})

		# store information about scale
		@ruler = {

			# 1 WebGL unit = 1 angstrom
			scale: 1e-10
		}

		@on('change:activeToolName', @activateTool)
		@set('cameraMode', 'perspective')
		@on('change:cameraMode', @changeCameraMode)

	# -------------------------------------------------------------------------
	# data

	###*
	 * Saves #data for the models to JSON.
	 * @return {Object} Serialized canvas
	###
	save: () -> 
		out = @toJSON()
		# data: @data.toJSON()
		# version: VERSION.version+"+"+VERSION.build

		out.version = VERSION.version
		out


	###*
	 * Loads a new C3D.Canvas from a JSON object
	 * @param  {Object} file File, as returned by #save
	 * @return {C3D.Canvas3D} A new Canvas3D object
	###
	@load: (file) ->
		if file.version?
			# fix malformed versions like "0.3.0+"
			if file.version.match(/^([^+]+)\+$/) then file.version = file.version.match(/^([^+]+)\+$/)[1]
			for range, adapter of C3D.Legacy.adapters
				if semver.satisfies file.version, range
					file = adapter file

		new @(file)

	toJSON: () ->
		out = {}
		for key, value of @serializable
			if value
				out[key] = @[key].toJSON()
		out

	###*
	 * Undoes the last action performed
	###
	undo: () =>
		@undoMgr.undo(true)

	###*
	 * Redoes the last action undone
	###
	redo: () =>
		@undoMgr.redo(true)

	###*
	 * Imports data of a given type into the Canvas; activates
	 * the relevant interactive importing tool if appropriate
	 * @param  {Object} data Data to import
	 * @param  {String} type 
	 * Type of data to import; one of:
	 *
	 * - `vrml`/`wrl`/`wrl2`/`wrl1`: a [VRML 2.0](http://gun.teipir.gr/VRML-amgem/spec/index.html) 3D model file
	 * - `obj`: a [Wavefront OBJ](http://en.wikipedia.org/wiki/Wavefront_.obj_file) 3D model file
	 * - `pdb`: a PDB file 
	 * - `stl`: a [STL](http://www.ennex.com/~fabbers/StL.asp) (stereolithography) ASCII file
	 * - `json`: a {@link vox.dna.CaDNAno CaDNAno JSON} file 
	 * 
	 * @param  {Function} callback Callback to execute once the import (possibly interative) has completed
	###
	import: (data, type, callback) =>
		switch type.toLowerCase()
			when 'vrml', 'wrl', 'wrl2', 'wrl1'
				importer = new THREE.VRMLLoader()
			when 'obj'
				importer = new THREE.OBJLoader()
			when 'pdb'
				importer = new THREE.PDBLoader()
			when 'stl'
				importer = new THREE.STLLoader()
			when 'json'
				@setActiveTool 'CaDNAnoImporter'
				@tools.CaDNAnoImporter.import JSON.parse(data), callback
				null

		if importer?
			@setActiveTool 'Importer'
			@tools.Importer.import data, importer, callback

	###*
	 * Exports data in the canvas in the requested file format and returns the data as an object or string
	 * @param  {String} type 
	 * Type of data to export; one of:
	 *
	 * - `svg` (unsupported)
	 * - `stl` (unsupported)
	 * - `obj` (unsupported)
	 * - `png` (unsupported)
	 * 
	 * @param  {Function} cb
	 * @return {Object} 
	###
	export: (type, cb) =>

		switch type
			when 'svg'
				renderer = new THREE.SVGRenderer()
				renderer.setSize( window.innerWidth, window.innerHeight )
				renderer.setClearColor( 0xffffff, 1);
				wrapper = $("<div></div>")
				wrapper.append(renderer.domElement)
				$(document.body).append(wrapper)
				renderer.render( @scene, @camera )
				text = wrapper.html().replace(/<\\?div>/g).replace(/<svg /, '<?xml version="1.0" ?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" ')
				wrapper.remove()
				text

			when 'stl'
				exporter = new THREE.STLExporter()
				exporter.parse @scene

			when 'obj'
				exporter = new THREE.OBJExporter()
				voxels = @views.Voxels.getGeometry()
				exporter.parse voxels

			when 'png'
				renderer = new THREE.WebGLRenderer({antialias: true, alpha: true, preserveDrawingBuffer: true})
				renderer.setSize( window.innerWidth, window.innerHeight )
				wrapper = $("<div></div>")
				wrapper.append(renderer.domElement)
				$(document.body).append(wrapper)
				renderer.render( @scene, @camera )
				data = renderer.domElement.toBlob cb
				wrapper.remove()

			when 'csv'
				csv = @ctrls.SST.toCSV()


	###*
	 * Searches the #data collection for a model that matches the passed
	 * `filter` function and if found, returns it; if none is found,
	 * calls the `generator` to build a new model, adds it to #data,
	 * and returns that.
	 * @param  {Function} filter
	 * @param {Backbone.Model} filter.model The model to assess
	 * @param {Boolean} filter.return `true` to accept the model, else `false`
	 *
	 * @param  {Function} generator
	 * Function to generate a new model if none is found
	 *
	 * @param {Boolean} [multiple=false]
	 * `true` to return all models that match the `filter`; `false` to return
	 * only one. If `true`, `generator` is expected to return a (possibly
	 * singular) array, and the function returns an array of models
	 *
	 * @return {Backbone.Model/Array}
	 * Found or built model (or models if `multiple` is `true)
	###
	findOrAdd: (filter, generator, multiple=false) ->
		if multiple
			models = @data.filter filter
			if models.length is 0
				models = generator()
				if models? then @data.add models
			return models
		else
			model = @data.find filter
			if not model?
				model = generator()
				if model? then @data.add model
			return model
	###*
	 * Works like #findOrAdd, but replaces the item instead.
	###
	replaceOrAdd: (filter, generator, multiple=false) ->
		if multiple
			models = @data.filter filter
			if models.length > 0 then @data.remove models
			models = generator()
			if models? then @data.add models
			return models
		else
			model = @data.find filter
			if model? then @data.remove model
			model = generator()
			if model? then @data.add model
			return model

	###*
	 * Called when a model in #data changes; calls onModelChange
	 * in each {@link C3D.ctrls.Controller#onModelChange controller}
	 * and {@link C3D.views.View#onModelChange view} registered with this
	 * canvas that {@link C3D.ctrls.Controller#match matches} the model.
	 * @private
	 * @param  {Backbone.Model} model Model that changed
	 * @param  {Object} changes Hash of changes to the object
 	###
	onModelChange: (model, changes) ->
		for name, ctrl of @ctrls
			if ctrl.match(model)
				ctrl.onModelChange(model, changes)

		for name, view of @views
			if view.match(model)
				view.onModelChange(model, changes)
	###*
	 * Called when a model is added to #data; calls onModelAdd
	 * in each {@link C3D.ctrls.Controller#onModelAdd controller}
	 * and {@link C3D.views.View#onModelAdd view} registered with this
	 * canvas that {@link C3D.ctrls.Controller#match matches} the model.
	 * @private
	 * @param  {Backbone.Model} model Model that is added
 	###
	onModelAdd: (model) ->
		for name, ctrl of @ctrls
			if ctrl.match(model)
				ctrl.onModelAdd(model)

		for name, view of @views
			if view.match(model)
				view.onModelAdd(model)

	###*
	 * Called when a model is removed from #data; calls onModelRemove
	 * in each {@link C3D.ctrls.Controller#onModelRemove controller}
	 * and {@link C3D.views.View#onModelRemove view} registered with this
	 * canvas that {@link C3D.ctrls.Controller#match matches} the model.
	 * @private
	 * @param  {Backbone.Model} model Model that is added
 	###
	onModelRemove: (model) ->
		for name, ctrl of @ctrls
			if ctrl.match(model)
				ctrl.onModelRemove(model)

		for name, view of @views
			if view.match(model)
				view.onModelRemove(model)

	###*
	 * Called when a model is selected from #data; calls onModelSelect
	 * in each {@link C3D.ctrls.Controller#onModelSelect controller}
	 * and {@link C3D.views.View#onModelSelect view} registered with this
	 * canvas that {@link C3D.ctrls.Controller#match matches} the model.
	 * @private
	 * @param  {Backbone.Model} model Model that is selected
 	###
	onModelSelect: (model) ->
		for name, ctrl of @ctrls
			if ctrl.match(model)
				ctrl.onModelSelect(model)

		for name, view of @views
			if view.match(model)
				view.onModelSelect(model)

	###*
	 * Called when a model is deselected from #data; calls onModelDeselect
	 * in each {@link C3D.ctrls.Controller#onModelDeselect controller}
	 * and {@link C3D.views.View#onModelDeselect view} registered with this
	 * canvas that {@link C3D.ctrls.Controller#match matches} the model.
	 * @private
	 * @param  {Backbone.Model} model Model that is deselected
 	###
	onModelDeselect: (model) ->
		for name, ctrl of @ctrls
			if ctrl.match(model)
				ctrl.onModelDeselect(model)

		for name, view of @views
			if view.match(model)
				view.onModelDeselect(model)

	###*
	 * @private
	 * Called in response to a change in selection in #data
	 * @param  {Object} diff
	 * @param {Array} diff.selected Models newly selected
	 * @param {Array} diff.deselected Models newly deselected
	###
	onSelectionChange: (diff) ->
		for selected in diff.selected
			@onModelSelect(selected)
		for deselected in diff.deselected
			@onModelDeselect(deselected)

	###*
	 * Gets the instance of the given {@link C3D.tools.Tool tool} associated
	 * with this canvas.
	 * @param  {String} name Tool name
	 * @return {C3D.tools.Tool} Tool instance
	###
	getTool: (name) ->
		return @tools[name]

	###*
	 * Gets the instance of the given {@link C3D.views.View view} associated
	 * with this canvas.
	 * @param  {String} name View name
	 * @return {C3D.views.View} View instance
	###
	getView: (name) ->
		return @views[name]

	###*
	 * Gets the instance of the given {@link C3D.ctrls.Controller controller} associated
	 * with this canvas.
	 * @param  {String} name Controller name
	 * @return {C3D.ctrls.Controller} Controller instance
	###
	getCtrl: (name) ->
		return @ctrls[name]

	# -------------------------------------------------------------------------
	# interface

	resetCamera: () ->
		if @lattice?
			center = @lattice.latticeToPoint @lattice.centroid()...
			center[1] = center[1] // 2
			radius = Math.sqrt((@lattice.cell[0] * @lattice.width / 1) ** 2 + 
				(@lattice.cell[1] * @lattice.height / 1) ** 2 + 
				(@lattice.cell[2] * @lattice.depth / 1) ** 2)
		else
			center = [0,200,0] 
			radius = 1600
		###*
		 * @property {THREE.Vector3}
		###
		@target = new THREE.Vector3(center...)
		
		theta = 0 #90
		phi = 60

		if @camera?
			@camera.radius = radius
			@camera.position.x = @target.x - radius * Math.sin( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )
			@camera.position.y = @target.y - radius * Math.sin( -phi * Math.PI / 360 )
			@camera.position.z = @target.z - radius * Math.cos( theta * Math.PI / 360 ) * Math.cos( phi * Math.PI / 360 )

		@controls?.reset @target, @camera.position

	setView: (x,y,z) ->
		x = @target.x - x * @camera.radius
		y = @target.y - y * @camera.radius
		z = @target.z - z * @camera.radius

		@controls?.setView new THREE.Vector3( x, y, z )

	###*
	 * Initializes the canvas; creates the #container, #camera, #scene, and lighting.
	 * Adds event handlers for the #tools
	###
	init: () ->
		###*
		 * @property {Node} container
		 * Container element into which this Canvas will be rendered
		###
		@container = document.createElement( 'div' )
		$(@container).css({ position: 'absolute' }).addClass('nb-container').prop('tabindex','0')
		document.body.appendChild( @container )



		###*
		 * @property {THREE.CombinedCamera} camera
		 * Camera for rendering the scene
		###
		# @camera = new THREE.PerspectiveCamera( 40, window.innerWidth / window.innerHeight, 1, 100000 )
		scale = 1
		@camera = new THREE.CombinedCamera( scale, scale * window.innerHeight / window.innerWidth, 40, 1, 100000, 1, 10000 )
		@target = new THREE.Vector3()

		###*
		 * @property {THREE.Scene} scene
		 * 3D scene rendered by this canvas.
		###
		@scene = new THREE.Scene()

		###*
		 * @property {THREE.Projector} projector
		 * Projector for mapping from sceen to world coordinates
		###
		# @projector = new THREE.Projector()
		@raycaster = new THREE.Raycaster()

		# Lights
		ambientLight = new THREE.AmbientLight( 0x606060 )
		@scene.add( ambientLight )

		directionalLight = new THREE.DirectionalLight( 0xffffff );
		directionalLight.position.set( 1, 0.75, 0.5 ).normalize();
		@scene.add( directionalLight );

		



		# Fog
		# @scene.fog = new THREE.Fog( 0xffffff, @camera.near, @camera.far )
		# @scene.fog = new THREE.FogExp2( 0xffffff, 0.00025 );

		# Grid and Plane
		@buildGrid()
		@on "change:lattice", @buildGrid

		# build renderer and container
		hasWebGL =  do () ->
			try
				return !! window.WebGLRenderingContext && !! document.createElement( 'canvas' ).getContext( 'experimental-webgl' )
			catch e
				return false

		###*
		 * @property {THREE.Renderer} renderer
		###
		if hasWebGL then @renderer = new THREE.WebGLRenderer({antialias: true, alpha: true})
		else @renderer = new THREE.CanvasRenderer()

		@renderer.setSize( window.innerWidth, window.innerHeight )
		@renderer.setClearColor( 0xffffff, 1);
		@container.appendChild(@renderer.domElement)

		@on 'change:anaglyph', (model, active) => @setEffect 'anaglyph', active

		# mouse events
		@mouse.v2D = new THREE.Vector3( 0, 10000, 0.5 )
		$(@renderer.domElement).on( 'mousemove', @mousemove )
		$(@renderer.domElement).on( 'mousedown', @mousedown )
		$(@renderer.domElement).on( 'mouseup', @mouseup )
		$(@renderer.domElement).on( 'contextmenu', @contextmenu )
		$(@renderer.domElement).on( 'click', @click )
		$(@renderer.domElement).on( 'dblclick', @dblclick )
		$(document).on( 'keydown', @documentkeydown )
		$(document).on( 'keyup', @documentkeyup )
		$('body')
			.on('focus', 'input, textarea', () => @keys.listener.stop_listening())
			.on('blur', 'input, textarea', () => @keys.listener.listen())

		@registerKey 'meta z', @undo
		@registerKey 'ctrl shift z', @redo
		@registerKey 'meta y', @redo

		###*
		 * @property {THREE.OrbitControls}
		 * Set of controls to orbit, zoom, and pan the view; individual tools
		 * may disable these controls as well.
		###
		@controls = new THREE.OrbitControls(@camera, @renderer.domElement)
		# @flyControls = new THREE.FlyControls(@camera, @renderer.domElement)
		# @flyControls = new THREE.PointerLockControls(@camera, @renderer.domElement)
		# @flyControls.enabled = false
		@clock = new THREE.Clock()

		# window resizing

		onWindowResize = () => 
			# @camera.aspect = window.innerWidth / window.innerHeight
			@camera.setSize 1, window.innerHeight / window.innerWidth

			@camera.updateProjectionMatrix()
			@renderer.setSize( window.innerWidth, window.innerHeight )
			if @effect then @effect.setSize( window.innerWidth, window.innerHeight )

		window.addEventListener( 'resize', onWindowResize, false )

		@on 'change:lattice', @resetCamera

		###*
		 * @cfg {Object[]} data
		 * Serialized data from {@link C3D.models.Model models} that should be
		 * vivified and added to the #data store once the Canvas has been setup
		###

		# ctrl.init() for name, ctrl of @ctrls
		# tool.init() for name, tool of @tools
		# view.init() for name, view of @views

		# vivify models passed in through the constructor
		@data.add (_.vivify(o) for o in @_data when o)

		# initialize controllers, views, tools
		for c in ['ctrlsList', 'viewsList', 'toolsList']
			for object in @[c]
				if object.init? then object.init()

			# for name, object of @[c]
			# 	if object.init? then object.init()

		# reset camera position
		@resetCamera()

		# begin rendering
		requestAnimationFrame(@frame);

	###*
	 * Generates #grid and #plane geometries from lattice
	###
	buildGrid: () =>
		[gridGeometry,planeGeometry] = do () =>
			gridGeometry = new THREE.Geometry()
			planeGeometry = new THREE.Geometry()
			height = -@lattice.cell[1]/2
			for i in [0...@lattice.width]
				for k in [0...@lattice.depth]
					geo = @lattice.cellFootprint(i, 0, k)
					center = new THREE.Matrix4().makeTranslation(@lattice.latticeToPoint(i,0,k)...)
					gridGeometry.merge geo.clone(), center
					planeGeometry.merge geo, center

			[gridGeometry,planeGeometry]

		###*
		 * @property {THREE.Mesh} grid
		 * Grid showing bottom of the canvas
		###
		if @grid then @scene.remove @grid
		@grid = do () =>
			material = new THREE.LineBasicMaterial( { color: 0x000000, opacity: 0.2 } )
			line = new THREE.Line( gridGeometry, material, THREE.LinePieces )
			# line.type = THREE.LineStrip
			line

		@scene.add( @grid )


		###*
		 * @property {THREE.AxisHelper} axisHelper
		 * 3D axis to orient grid
		###
		if @axisHelper then @scene.remove @axisHelper
		@axisHelper = do () =>
			new THREE.AxisHelper( window.innerWidth/4 )
			# new THREE.AxisHelper( window.innerWidth/2 )

		# @axisHelper.position = @grid.position
		@scene.add( @axisHelper );
		

		###*
		 * @property {THREE.Mesh} plane
		 * Plane that the user can click on to add voxels to an otherwise empty canvas
		###
		if @plane then @scene.remove @plane
		@plane = do () =>
			planeGeometry.computeFaceNormals()
			planeGeometry.computeVertexNormals()

			planeMaterial = new THREE.MeshBasicMaterial({ color: 0x990000, fog: true })
			planeMaterial.fog = true
			# plane.rotation.x = - Math.PI / 2
			plane = new THREE.Mesh( planeGeometry,
			# plane = new THREE.Mesh( new THREE.PlaneGeometry( @lattice.cell[0]*@lattice.width, @lattice.cell[2]*@lattice.depth ),
				planeMaterial )
				# new THREE.MeshBasicMaterial() )
			# plane.rotation.z = + Math.PI
			# plane.rotation.y = - Math.PI / 2
			# plane.rotation.x = plane.rotation.z = - Math.PI / 2
			plane.visible = false
			plane.isPlane = true
			plane

		@scene.add( @plane )

	###*
	 * Takes a function `f` and a unique key, and returns a function
	 * that, when called repeatedly, will run at most once during the 
	 * next #frame.
	 * @param  {Function} f Function to be called
	 * @param  {String} key 
	 * Unique key identifying the function; if multiple functions are 
	 * passed to #debounceBeforeDraw with the same key, only the first
	 * one will be called.
	###
	debounceBeforeDraws: (f, key) -> () =>
		@beforeNextDraw f, key

	###*
	 * Call the function `f` during the next #frame, before the #scene 
	 * is {@link #render}ed, _unless_ another function has already been
	 * scheduled with the same `key`. Mostly used by #debounceBeforeDraws.
	 * Note that the {@link preDraw} scheduler may opt to only call
	 * some number of these functions before this draw, in order to maintain
	 * responsiveness.
	 * @param  {Function} f 
	 * @param  {String} key 
	###
	beforeNextDraw: (f, key) =>
		###*
		 * @property {C3D.Uniqueue} drawQueue 
		 * The draw queue stores a series of functions to be called before
		 * the next time the #scene is {@link #render}ed. 
		###
		if not @drawQueue?
			@drawQueue = new C3D.Uniqueue()
			@drawQueue.totalLength = 0
		@drawQueue.enqueue f, key

	###*
	 * @private
	 * @property {Number} maxDrawTime 
	 * Maximum number of time that may elapse during the #preDraw
	 * function 
	###
	maxDrawTime: 250
	
	###*
	 * @private
	 * Called each #frame before the #scene is {@link #render}ed. Notably
	 * processes the #drawQueue. Specifically, calls as many functions
	 * as possible from the #drawQueue before #maxDrawTime ms have elapsed.
	 * This ensures that the interface remains somewhat responsive while long-
	 * running drawing operations are occurring. If the #drawQueue cannot
	 * be cleared before the end of this #frame, then a #drawprogress
	 * event is emitted with the percent of the #drawQueue completed.
	 * The remainder will be processed, in order, during the next #frame.
	###
	preDraw: () =>
		# start a timer
		timer = new C3D.Timer()
		maxDrawTime = @maxDrawTime

		# if there even is a #drawQueue
		if @drawQueue?

			# if the drawQueue has grown since last frame, remember that
			# so we can estimate the progress
			if @drawQueue.totalLength < @drawQueue.length() 
				@drawQueue.totalLength = @drawQueue.length()

			# do as much as possible before maxDrawTime ms elapses
			while (@drawQueue.length() > 0 and timer.duration() < maxDrawTime)
				f = @drawQueue.dequeue()
				f()

			len = @drawQueue.length()

			###*
			 * @event drawprogress
			 * Emitted when the #drawQueue cannot be cleared in one frame.
			 * @param {Number} progress 
			 * Number between 0.0 and 1.0 indicating how much of 
			 * the #drawQueue has been cleared as of this #frame.
			###
			if len > 0 then @trigger 'drawprogress', ((@drawQueue.totalLength-len)/@drawQueue.totalLength )
			else @trigger 'drawprogress', 1

	###*
	 * @private
	 * Called each #frame before the #scene is {@link #render}ed.
	 * Currently a no-op
	###
	postDraw: () =>
		null

	###*
	 * Loop that {@link #render renders} a single animation frame using 
	 * `requestAnimationFrame`; this function calls #predraw, #render, 
	 * then #postDraw, then schedules another animation #frame.
	 * @private
	###
	frame: () =>
		if @stats then @stats.begin()
		@preDraw()
		@render()
		@postDraw()
		if @stats then @stats.end()
		requestAnimationFrame(@frame);

	###*
	 * Renders a single animation frame; called automatically by #frame.
	 * Also updates the {@link #raycaster} and applies any #effect.
	###
	render: () =>
		# @camera.lookAt( @target )
		delta = @clock.getDelta()
		if @controls.enabled then @controls.update()
		# if @flyControls.enabled then @flyControls.update(delta)	
		# @raycaster = @projector.pickingRay( @mouse.v2D.clone(), @camera )
		@raycaster.pickingRay( @mouse.v2D.clone(), @camera )
		@raycaster.linePrecision = 10

		if window.figureFog?
			figureFog @scene, @camera
		# @scene.fog.near = @camera.near 
		# @scene.fog.far = @camera.near + Math.log(@camera.far-@camera.near)


		if @effect? then @effect.render( @scene, @camera )
		else @renderer.render( @scene, @camera )

	###*
	 * @private
	 * Switches the camera from perspective to orthographic mode
	 * @param {Backbone.Model} model
	 * @param {"perspective"/"ortho"} mode
	###
	changeCameraMode: (model, mode) =>
		if mode is 'perspective' then @camera.toPerspective()
		else if mode is 'ortho' then @camera.toOrthographic()

	setEffect: (name, active) =>
		@effects ?= {}
		switch name
			when 'anaglyph'
				if not @effects.anaglyph? then @effects.anaglyph = new THREE.AnaglyphEffect(@renderer)
				@camera.aspect = window.innerWidth / window.innerHeight
				@camera.updateProjectionMatrix()
				if active
					@effect = @effects.anaglyph
					@effect.setSize( window.innerWidth, window.innerHeight )
				else @effect = null
	
	getIntersections: (filter=null) ->
		filter = filter ? (c) -> c.isVoxel || c.isPlane
		intersectable = @scene.children.filter filter
		intersections = @raycaster.intersectObjects( intersectable )

	###*
	 * Zooms the view
	 * @param  {Number} delta Amount to zoom to
	###
	zoom: (delta) -> undefined

	getIntersections: (filter=null) ->
		filter = filter ? (c) -> c.isVoxel || c.isPlane
		intersectable = @scene.children.filter filter 
		intersections = @raycaster.intersectObjects( intersectable )

	###*
	 * Returns the top object intersecting the #raycaster
	 *
	 * @param {Function} [filter] Function which filters objects in the scene;
	 * by default gives objects that either have `isVoxel` or `isPlane` set to true
	 * @param {THREE.Object3D} filter.object Object to filter
	 * @param {Boolean} filter.return `true` to include the object, `false` to exclude
	 *
	 * @return {THREE.Object3D[]} Intersecting objects
	###
	getIntersecting: (filter=null) ->
		intersections = @getIntersections()
		if (intersections.length > 0)
			return if intersections[ 0 ].object.isBrush then intersections[ 1 ] else intersections[ 0 ]

	###*
	 * Returns the top object intersecting the #raycaster, as well as the
	 * point of the intersection, in world coordinates
	 *
	 * @param {Function} [filter] Function which filters objects in the scene;
	 * by default gives objects that either have `isVoxel` or `isPlane` set to true
	 * @param {THREE.Object3D} filter.object Object to filter
	 * @param {Boolean} filter.return `true` to include the object, `false` to exclude
	 *
	 * @return {Array} [THREE.Object3D, THREE.Vector3]: intersecting object and position
	###
	getIntersectingPoint: (filter=null, options=null) ->
		options ?= {}

		normalMatrix = new THREE.Matrix3()

		# find an object the cursor intersects
		intersections = @getIntersectionPoints(filter)
		if intersections.length > 0 then intersections[0]
		else [null, null]


	###*
	 * Uses raycasting to find objects that intersect with the cursor.
	 *
	 *     # get all points of intersection with voxels, highlighting 
	 *     # intersected objects in blue and showing a red sphere at 
	 *     # each point of intersection
	 *     intersections = @canvas.getIntersectionPoints ((o) -> o.isVoxel)
	 *     
	 *     for [intersect, point] in intersections
	 *         # show a red sphere at intersection point
	 *         sphere = new THREE.SphereGeometry(5,5,5)
	 *         sphere.position = point
	 *         @canvas.scene.add new THREE.Mesh sphere, new THREE.MeshBasicMaterial({color:'red'})
	 *         
	 *         # make the intersected object blue
	 *         intersect.object.material.color.setStyle 'blue'
	 *
	 * This method will shoot a ray from the #camera through the viewing plane 
	 * towards the position of the #mouse; at each point this ray hits an 
	 * object in the scene (matching the `filter`), a result will be generated. 
	 *
	 * For each result, the intersection `point` will be displaced by the 
	 * surface normal of the intersected face, so that the returned point is
	 * slighly above the surface of the intersected object. With the `burrow`
	 * option, the point will be displaced in the direction of the negative surface 
	 * normal, so the resulting point is slightly _inside_ the intersected object.
	 *
	 * Rather than this method, you may want to use C3D.views.Voxels#getIntersection
	 * or C3D.views.SST#getIntersection if you're interested in doing a particular
	 * kind of raycasting.
	 * 
	 * @param  {Function} [filter=null] Filter function to select objects from the #scene
	 * @param {THREE.Object3D} filter.object 
	 * Object from the scene to evaluate
	 * @param {Boolean} filter.return 
	 * `true` to include `object` in the raycasting, `false` to exclude it
	 * 
	 * @param  {Object} [options=null] Options for raycasting
	 * @param {Boolean} [options.burrow=false] 
	 * If `true`, the `point` returned will be `intersect.burrowed`, if `false`
	 * it will be `intersect.extruded`.
	 * 
	 * @return {Array[]} 
	 * List of pairs `[intersect, point]`, where `intersect` contains data 
	 * about the intersection and `point` is a vector giving the point of 
	 * intersection.
	 * 
	 * @return {Object} return.0 `intersect`
	 * @return {THREE.Object3D} return.0.object The intersected object
	 * @return {THREE.Vector3} return.0.point 
	 * The actual point of intersection on the surface of the `object`
	 * @return {THREE.Vector3} return.0.burrowed
	 * The point of intersection, displaced "inwards" (in the direction of the
	 * negative surface normal) by one unit
	 * @return {THREE.Vector3} return.0.extruded
	 * The point of intersection, displaced "outwards" (in the direction of the
	 * surface normal) by one unit
	 * @return {THREE.Vector3} return.0.normal 
	 * The surface normal (in object coordinates) of the intersected face at
	 * the point of intersection.
	 * @return {THREE.Face3} return.0.face 
	 * The intersected face
	 * 
	 * @return {THREE.Vector3} return.1 `point` 
	 * The point of intersection, depending on `options`.
	###
	getIntersectionPoints: (filter=null, options=null) ->
		options ?= {}
		normalMatrix = new THREE.Matrix3()

		# find an object the cursor intersects
		intersections = @getIntersections(filter)
		for intersect in intersections

			# get the position of the intersection
			normalMatrix.getInverse( intersect.object.matrixWorld )
			normalMatrix.transpose()
			if intersect.face
				normal = intersect.face.normal.clone()
				normal.applyMatrix3( normalMatrix ).normalize()
				intersect.burrowed = new THREE.Vector3().addVectors( intersect.point, normal.clone().negate() )
				intersect.extruded = new THREE.Vector3().addVectors( intersect.point, normal )
				intersect.normal = normal
				if options.burrow

					position = intersect.burrowed
				else if options.extrude == false
					position = intersect.point
				else 
					position = intersect.extruded
			else 
				position = intersect.point
			[intersect, position]

	###*
	 * Returns the position of the mouse in 3D world coordinates
	 * @return {THREE.Vector3} Position of the mouse
	###
	unprojectMouse: () ->
		@projector.unprojectVector @mouse.v2D, @camera

	# -------------------------------------------------------------------------
	# tools

	###*
	 * Gives the currently-active tool
	 * @return {C3D.tools.Tool} the active tool
	###
	getActiveTool: () ->
		return @activeTool

	###*
	 * Sets the currently-active tool
	 * @param {String} tool Name of the new active tool
	 * @return {C3D.tools.Tool} the new active tool
	###
	setActiveTool: (toolName) ->
		@set 'activeToolName',toolName

	###*
	 * Called when the #activeTool property changes
	 * @private
	 * @param  {C3D.Canvas3D} me
	 * @param  {String} toolName Name of the {@link #tools tool}
	 * @return {C3D.tools.Tool} New active tool, or false if unsuccessful
	###
	activateTool: (model, toolName) =>
		if toolName of @tools
			if @activeTool
				@activeTool.active = false
				@activeTool.deactivate()
			@tools[toolName].active = true
			@tools[toolName].activate()
			@activeTool = @tools[toolName]
			@set('activeTool',@activeTool)
			# return @activeTool
		else return false

	# -------------------------------------------------------------------------
	# events

	###*
	 * Registers an event handler on the pressed key combo. Combos are handled using the
	 * library [Keypress](http://dmauro.github.io/Keypress/), and much of that
	 * documentation is borrowed here.
	 *
	 * @param  {String/String[]} combo Space-separated string of keys to be used for the combo
	 * @param  {Object/Function} options
	 * Callback to be executed when the key is pressed, or hash of options for the combo:
	 *
	 * @param {String/String[]} options.keys
	 * This option can be either an array of strings, or a single space
	 * separated string of key names that describe the keys that make up the combo.
	 *
	 * @param {Function} [options.keydown]
	 * This is a function that gets called everytime the keydown event for
	 * our combo is fired. We pass all event handlers three arguments: the key event
	 * that triggered it, and an integer representing the number of times the combo
	 * has been pressed (this will be 0 unless it is a counting combo), and whether
	 * or not the event was autorepeated from holding the keydown.
	 * @param {Event} e
	 * @param {Number} count Number of times the combo has been triggered
	 * @param {Boolean} autoRepeat
	 * `true` if the event was automatically repeated from holding the combo down
	 *
	 * @param {Function} [options.keyup ]
	 * Same as above but for keyup events.
	 * @param {Event} e
	 * @param {Number} count Number of times the combo has been triggered
	 * @param {Boolean} autoRepeat
	 * `true` if the event was automatically repeated from holding the combo down

	 * @param {Function} [options.release]
	 * This is similar to keyup, but will fire once when ALL of the keys of
	 * a combo have been released. If you're unsure, you probably want to ignore this
	 * and use `keyup`.
	 * @param {Event} e
	 * @param {Number} count Number of times the combo has been triggered
	 * @param {Boolean} autoRepeat
	 * `true` if the event was automatically repeated from holding the combo down
	 *
	 * @param {Object} [options.scope]
	 * By default, our key event callbacks will be called with their scope set
	 * to window, but we can specify the scope with this option.
	 *
	 * @param {Boolean} [options.preventDefault=false]
	 * Any handlers for your combos will event.preventDefault() for
	 * the relevant event by default (you can return `true` in the handler to prevent
	 * this). But there is additionally a prevent_default property which will
	 * preventDefault() for events of keypresses of all constituent keys of the
	 * combo. What this means is that if you have a combo "shift s", both 'shift' and
	 * 's' keypresses will independently preventDefault() when pressed.
	 *
	 * @param {Object} [options.preventRepeat=false]
	 * Normally the `keydown` callback will be called as fast as your
	 * browser fires the keydown event, but by setting this option to `true`, the
	 * on_keydown callback will only be called the first time.
	 *
	 * @param {Object} [options.unordered=false]
	 * By default we require that the user pressed the keys down in the
	 * same order that they are listed. As an example, a combo of "shift s" will only
	 * fire if shift is pressed before s is pressed. This order can be arbitrary by
	 * specifying `true` for this setting.
	 *
	 * @param {Object} [options.counting=false]
	 * Setting this to `true` will make the combo a counting combo as
	 * described above.
	 *
	 * @param {Object} [options.exclusive=false]
	 * Normally when pressing a key, any and all combos that match will
	 * have their callbacks called. For instance, pressing 'shift' and then 's' would
	 * activate the following combos if they existed: "shift", "shift s" and "s".
	 * When we set is_exclusive to `true`, we will not call the callbacks for any
	 * combos that are also exclusive and less specific. This property is used to
	 * great effect in the arbitrary modifiers demo above to make sure that when you
	 * press diagonal combos, the component direction combos are not also fired.
	 *
	 * @param {Object} [options.sequence=false]
	 * Setting this to `true` will make the combo a "sequence combo," meaning
	 * the event will be fired once each key in the sequence has been pressed.
	 *
	 * @param {Object} [options.solitary=false]
	 * This option will check that ONLY the combo's keys are being pressed
	 * when set to `true`. When set to the default value of `false`, a combo can be
	 * activated even if extraneous keys are pressed.
	###
	registerKey: (combo, options) =>
		if _.isFunction(options)
			@keys.listener.simple_combo combo, options

		else if _.isObject(options)
			opts =
				"keys"              : combo,
				"on_keydown"        : options.keydown,
				"on_keyup"          : options.keyup,
				"on_release"        : options.release,
				"this"              : options.scope,
				"prevent_default"   : options.preventDefault,
				"prevent_repeat"    : options.preventRepeat,
				"is_unordered"      : options.unordered,
				"is_counting"       : options.counting,
				"is_exclusive"      : options.exclusive,
				"is_solitary"       : options.solitary,
				"is_sequence"       : options.sequence

			@keys.listener.register_combo opts

	###*
	 * @private
	 * @param  {Event} event Event object
	###
	contextmenu: (event) =>
		event.preventDefault()

	###*
	 * Called on mousedown in the canvas; delegates to {@link C3D.tools.Tool#mousedown}
	 * @param  {Event} event Event object
	###
	mousedown: (event) =>
		# event.preventDefault()
		@mouse.isDown = true
		@mouse.which = event.which
		[@mouse.isLeft,	@mouse.isRight,	@mouse.isMiddle] = [(@mouse.which == 1), (@mouse.which == 2), (@mouse.which == 3)]

		@mouse.downPosition = new THREE.Vector2()
		@mouse.downPosition.x = event.clientX
		@mouse.downPosition.y = event.clientY
		@mouse.downPosition.target = @target.clone()

		@mouse.position = new THREE.Vector2()
		@mouse.position.x = event.clientX
		@mouse.position.y = event.clientY
		@getActiveTool()?.mousedown(event)

	###*
	 * Called on mouseup in the canvas; delegates to {@link C3D.tools.Tool#mouseup}
	 * @param  {Event} event Event object
	###
	mouseup: (event) =>
		# event.preventDefault()
		@mouse.isDown = false
		[@mouse.isLeft,	@mouse.isRight,	@mouse.isMiddle] = [(@mouse.which == 1), (@mouse.which == 2), (@mouse.which == 3)]
		@mouse.downPosition.x = event.clientX - @mouse.downPosition.x
		@mouse.downPosition.y = event.clientY - @mouse.downPosition.y

		@mouse.position = new THREE.Vector2()
		@mouse.position.x = event.clientX
		@mouse.position.y = event.clientY

		@getActiveTool()?.mouseup(event)

	###*
	 * Called on mousemove in the canvas; delegates to {@link C3D.tools.Tool#mousemove}
	 * @param  {Event} event Event object
	###
	mousemove: (event) =>
		event.preventDefault()
		@mouse.v2D.x = ( event.clientX / window.innerWidth ) * 2 - 1
		@mouse.v2D.y = - ( event.clientY / window.innerHeight ) * 2 + 1

		@mouse.position = new THREE.Vector2()
		@mouse.position.x = event.clientX
		@mouse.position.y = event.clientY

		@getActiveTool()?.mousemove(event)

	###*
	 * Called on mouse click in the canvas; delegates to {@link C3D.tools.Tool#click}
	 * @param  {Event} event Event object
	###
	click: (event) =>
		@getActiveTool()?.click(event)

	###*
	 * Called on dblclick in the canvas; delegates to {@link C3D.tools.Tool#dblclick}
	 * @param  {Event} event Event object
	###
	dblclick: (event) =>
		@getActiveTool()?.dblclick(event)

	###*
	 * Called on mousewheel zoom in the canvas; delegates to {@link C3D.tools.Tool#mousewheel}
	 * @param  {Event} event Event object
	###
	mousewheel: (event) =>
		@zoom(event.wheelDeltaY || event.detail)

	###*
	 * Called on keydown in the document
	###
	documentkeydown: () =>
		switch event.keyCode
			when 16 then @keys.isShiftDown = true
			when 17 then @keys.isCtrlDown = true
			when 18 then @keys.isAltDown = true
		# avoid returning false
		undefined

	###*
	 * Called on keyup in the document
	###
	documentkeyup: (event) =>
		switch event.keyCode
			when 16 then @keys.isShiftDown = false
			when 17 then @keys.isCtrlDown = false
			when 18 then @keys.isAltDown = false
		# avoid returning false
		undefined


###*
 * @class C3D.Canvas3D.MouseState
 * Gives information about the state of the mouse
###
class C3D.Canvas3D.MouseState
	radius: 1600
	theta: 90
	phi: 60

	###*
	 * Tells whether the mouse is down
	 * @type {Boolean}
	###
	isDown: false

	###*
	 * @property {Boolean}
	 * Determines if the left mouse button is down
	###
	isLeft: null

	###*
	 * @property {Boolean}
	 * Determines if the right mouse button is down
	###
	isRight: null

	###*
	 * @property {Boolean}
	 * Determines if the middle mouse button is down
	###
	isMiddle: null

	###*
	 * @property {THREE.Vector2}
	 * During mousedown and mousemove events, gives the position at
	 * which the mouse was pressed down. During mouseup events, gives
	 * the distance between the start of the drag and the end of the
	 * drag.
	###
	downPosition: null

	###*
	 * @property {THREE.Vector2}
	 * Gives the current position of the mouse 
	###
	position: null

	###*
	 * @property {THREE.Vector2}
	 * Gives the position of the mouse on the screen in normalized-device coordinates (between -1 and +1)
	###
	v2D: null

###*
 * @class C3D.Canvas3D.KeyState
 * Gives information about the current state of the keyboard
###
class C3D.Canvas3D.KeyState
	constructor: () ->
		@listener = new keypress.Listener(document.body)
	###*
	 * @property
	 * `true` if the shift key is currently pressed
	###

	isShiftDown: false
	###*
	 * @property
	 * `true` if the alt key is currently pressed
	###
	isAltDown: false
	###*
	 * @property
	 * `true` if the ctrl key is currently pressed
	###
	isCtrlDown: false

	###*
	 * Determines whether a given key is currently down
	 *
	 * @param  {String} key
	 * Name of the key. May be any character on the keyboard, or one of
	 * the modifier keys `'shift'`, `'ctrl'`, or `'alt'`. Note that
	 * `'cmd'` cannot be reliably detected. For spacebar, use `'space'`.
	 *
	 * See the [KeyPress library source](https://github.com/dmauro/Keypress/blob/master/keypress.coffee#L728-864)
	 * for a complete list of accepted keys.
	 *
	 * @return {Boolean}
	###
	isDown: (key) => (key in @listener._keys_down)

	###*
	 * Gets the list of keys currently down
	 *
	 * @return {String[]}
	 * Names of the keys.
	 *
	 * See the [KeyPress library source](https://github.com/dmauro/Keypress/blob/master/keypress.coffee#L728-864)
	 * for a complete list of key names.
	###
	getKeysDown: () => _.clone @listener._keys_down

# -----------------------------------------------------------------------------

require('./tools.coffee')

# -----------------------------------------------------------------------------

require('./views.coffee')

# -----------------------------------------------------------------------------

require('./models.coffee')

# -----------------------------------------------------------------------------

require('./ctrls.coffee')
