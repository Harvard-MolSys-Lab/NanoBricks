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

pathutils = require('../pathutils.coffee')
_ = require('underscore')
async = require('async')
$ = require('jquery')

Backbone = require('backbone')
Backbone.$ = $

# stupid Backgrid
if window 
	window._ = _
	window.jQuery = window.$ = $
	window.Backbone = Backbone
# Backgrid = require('backgrid')
Backbone.LocalStorage = require("backbone.localstorage")

THREE = require('three')
ndarray = require('ndarray')
rivets = require('rivets')
saveAs = require('filesaver')

C3D = require('../c3d');
vox = require('../vox')
VERSION = require('../version')

process.stdout = {}

# -----------------------------------------------------------------------------

rivets.adapters[':'] =
	subscribe: (obj, keypath, callback) ->
		obj.on('change:' + keypath, callback)

	unsubscribe: (obj, keypath, callback) ->
		obj.off('change:' + keypath, callback)

	read: (obj, keypath) ->
		return obj.get(keypath)

	publish: (obj, keypath, value) ->
		obj.set(keypath, value)


rivets.adapters['>'] =
	subscribe: (obj, keypath, callback) ->
		# obj.on('change:' + keypath, callback)

	unsubscribe: (obj, keypath, callback) ->
		# obj.off('change:' + keypath, callback)

	read: (obj, keypath) ->
		return obj[keypath]()


rivets.binders['show-when-equals-*'] = (el, value) -> 
	if (value?.toLowerCase() == this.args[0]) then $(el).show()
	else $(el).hide()

# custom binder to force one-way attribute binding (e.g. for rv-value)
rivets.binders['attr-*'] = (el, value) ->
	if value?
		el.setAttribute this.args[0], value
	else
		el.removeAttribute this.args[0]

rivets.binders['addclass'] = (el, value) ->
	if el.addedClass 
		$(el).removeClass el.addedClass
		delete el.addedClass

	if value 
		$(el).addClass value
		el.addedClass = value

rivets.formatters.toArray = (collection) -> 
	if _.isObject(collection) 
		if collection instanceof Backbone.Collection then collection.models
		else _.values(collection) 

rivets.formatters.identify = (key) -> "element-"+key

rivets.formatters.length = (key) -> key.length

rivets.formatters.empty = (collection) -> 
	collection = if collection instanceof Backbone.Collection then collection.models else collection	
	(collection.length ? 0) is 0

rivets.formatters.notEmpty = (collection) -> 
	collection = if collection instanceof Backbone.Collection then collection.models else collection	
	(collection.length ? 0) isnt 0


rivets.formatters.not = (value) -> not value


# -----------------------------------------------------------------------------

# http://stackoverflow.com/questions/210717/using-jquery-to-center-a-div-on-the-screen
jQuery.fn.center = () ->
    this.css("position","absolute");
    this.css("top", Math.max(0, (($(window).height() - $(this).outerHeight()) / 2) + 
                                                $(window).scrollTop()) + "px");
    this.css("left", Math.max(0, (($(window).width() - $(this).outerWidth()) / 2) + 
                                                $(window).scrollLeft()) + "px");
    return this;

indent = (str) ->
	("\t" + line for line in str.split("\n")).join("\n")

compile = (script) ->
	coffee = require('coffee-script')
	eval(coffee.compile(script, { bare: true }))

destructure = (object) -> "{"+_.keys(object)+"}"

buildScriptFactory = (body, preamble=null) ->
	preamble = preamble ? "(voxels, strands, lattice) -> \n" +
	indent [ "{has, enclosed} = vox.compilers.utils(voxels.voxels, lattice)"
		"#{destructure(vox.shapes)} = vox.shapes"
		"#{destructure(vox.lit)} = vox.lit"
		"morph = morphology = vox.morphology" ].join "\n"

	preamble + "\n" + indent(body)

sorter = (order, def=Infinity) ->
	map = {}
	for key, index in order
		map[key] = index
	return (x) -> map[x] ? def 

# -----------------------------------------------------------------------------
###*
 * @class UI3D
 * @singleton
 * @static
 * Contains classes for rendering the user interface chrome around a {@link C3D.Canvas3D}.
###
UI3D = module.exports ? this


###*
 * @class  UI3D.utils
 * @singleton
 * @static
 * Provides utilities for building user interfaces
###
UI3D.utils = utils = 
	###*
	 * Make a CodeMirror element from the passed textarea
	 * @param  {jQuery/String/HTMLElement} textarea Textarea element or selector
	 * @param  {Object} config Configuration object for CodeMirror
	 * @return {CodeMirror} Generated CodeMirror editor
	###
	codeMirrorFromTextarea: (textarea, config) ->
		config ?= {}
		config = _.extend {
			lineNumbers: false
			mode: 'coffeescript'
			theme: 'bootstrap'
			height: null
			width: null
			indentWithTabs: true
			tabSize: 4
			indentUnit: 4
		}, config
		ed = CodeMirror.fromTextArea $(textarea).get(0), config
		ed.setSize (config.width ? null), (config.height ? null)
		$(ed.display.wrapper).on 'keydown', (e) -> e.stopPropagation()
		ed.on 'change', _.debounce((() -> ed.save()),100)
		ed

	codeMirrorHighlight: (el, selector='pre,code') ->
		$(el).find(selector).each (codeEl) ->
			CodeMirror.runMode codeEl.html(), 'coffeescript', codeEl.get(0)

	###*
	 * Allow the user drag and drop a file onto a textarea to populate the
	 * textarea with the file contents.
	 * @param  {jQuery/String/HTMLElement} el Textarea element
	###
	dragDropTextarea: (el) ->
		dom = $(el).get(0)
		if (typeof window.FileReader == 'undefined') then return
		dom.ondragover = () ->
			# $(this).addClass 'hover'
			$(this).focus()
			return false;

		dom.ondragend = () ->
			# $(this).removeClass 'hover'
			return false
		
		dom.ondrop = (e) ->
			# $(this).removeClass 'hover'
			e.preventDefault()

			file = e.dataTransfer.files[0]
			reader = new FileReader()
			reader.onload = (event) =>
				$(this).val(reader.result).change()

			console.log(file)
			reader.readAsText(file)

			return false

	###*
	 * Resets an `<input type="file">` element. Borrowed from 
	 * http://stackoverflow.com/questions/1043957/clearing-input-type-file-using-jquery
	 * @param  {HTMLElement} el
	 * @return {jQuery} el
	###
	resetFormElement: (el) ->
		el = $(el)
		el.wrap('<form>').closest('form').get(0).reset()
		el.unwrap()
	
	###*
	 * Handles file uploads on the passed input element
	 * @param  {HTMLElement/jQuery} input Input element to handle
	 * @param  {Function} handler 
	 * Function to execute upon upload
	 *
	 * @param {String} handler.contents File contents as string
	 * @param {String} handler.filename File name
	 * @param {FileReader} handler.reader Raw reader objecct 
	 * @param {File} handler.file Raw file object
	 *
	 * @param {String/Function} [mode='text'] 
	 * String specifying the mode in which to read the file from the 
	 * `FileReader`; `'text'` to `readAsText` or `'binary'` to 
	 * `readAsBinaryString`. Alternatively, a function can be passed
	 * which returns `'text'` or `'binary'`.
	 * @param {String} mode.filename Name of the file
	 * @param {String} mode.extname File extension 
	 * @param {'text'/'binary'} mode.return
	###
	handleUpload: (input, handler, mode='text', multi=false) ->
		if multi
			utils.handleMultiUpload input, sort, handler, mode					
		else 
			input = $(input)
			file = input.get(0).files?[0]
			if file?
				utils.handleSingleUpload input, file, handler, mode

	handleSingleUpload: (input, file, handler, mode, reset=true) ->
		reader = new FileReader()
		reader.onload = () =>
			handler(reader.result, file.name, reader, file)
			if reset
				utils.resetFormElement input

		if mode? and _.isFunction mode
			mode = mode(file.name, pathutils.extname(file.name))

		switch mode
			when 'binary'
				reader.readAsBinaryString file
			else 
				reader.readAsText file
		$('body').focus()

	###*
	 * Handles multi-file uploads
	 * 
	 * @param  {HTMLElement/jQuery} input 
	 * @param  {Function} sort Function by which to sort the files
	 * @param  {Function} handler Handler to be called for each uploaded file
	 * 
	 * @param {String} handler.contents File contents as string
	 * @param {String} handler.filename File name
	 * @param {FileReader} handler.reader Raw reader objecct 
	 * @param {File} handler.file Raw file object
	 * @param {Function} handler.next Callback function to be executed once importing is complete
	 * @param {Error} handler.next.err Error if one occurs, `null` if none occcurs, or `false` if the user cancels the import
	 * 
	 * @param {String/Function} [mode='text'] 
	 * String specifying the mode in which to read the file from the 
	 * `FileReader`; `'text'` to `readAsText` or `'binary'` to 
	 * `readAsBinaryString`. Alternatively, a function can be passed
	 * which returns `'text'` or `'binary'`.
	 * @param {String} mode.filename Name of the file
	 * @param {String} mode.extname File extension 
	 * @param {'text'/'binary'} mode.return
	###
	handleMultiUpload: (input, sort, handler, mode, final) ->
		input = $(input);
		files = input.get(0).files ? []
		_.sortBy files, sort

		readFile = (file, next) ->
			utils.handleSingleUpload input, file, ((res,name,reader) -> next(null,[res,name,reader,file])), mode, false

		async.map files, readFile, (err, results) ->
			if err then throw err
			# for args in results
			# 	handler args...
			# utils.resetFormElement input
			async.mapSeries results,
				(args, next) -> 
					handler args..., results.length, next
				(err) ->
					if err then throw err
					utils.resetFormElement input
					if final? then final(null)

	uploadElement: (el, selector, handler, options) ->
		options ?= {}
		options.event ?= 'change'

		el.on event, selector, () ->
			utils.handleUpload this, handler, options.mode

# -----------------------------------------------------------------------------


UI3D.Plugins = do () ->

	###*
	 * @class  UI3D.Plugins.Plugin
	 * @extends Backbone.Model
	 * Model representing an individual plugin which may or may not be loaded.
	###
	class Plugin extends Backbone.Model
		constructor: (options) ->
			options ?= {}
			options.url ?= ""
			super options

			###*
			 * @cfg {String} url
			 * URL of the plugin
			###

			###*
			 * @cfg {Error/false/undefined} error
			 * Status of the plugin:
			 *
			 * - `Error`: plugin was loaded, but an error occurred.
			 * - `false`: plugin was loaded successfully
			 * - `undefined`: plugin was not loaded
			###

		###*
		 * Returns `true` if the plugin has been loaded (whether or not
		 * an error occurred), else `false`.
		 * @return {Boolean}
		###
		isLoaded: () -> @get('error')?

	###*
	 * @class UI3D.Plugins.PluginCollection
	 * @extends Backbone.Collection
	###
	PluginsCollection = Backbone.Collection.extend {
		###*
		 * @property {Backbone.LocalStorage} localStorage
		###
		localStorage: new Backbone.LocalStorage("plugins")
		###*
		 * @property {Function} model
		###
		model: Plugin
	} 

	###*
	 * @class  UI3D.Plugins
	 * @static
	 * @singleton
	 *
	 * Manages NanoBricks plugins.
	###

	plugins = new PluginsCollection()

	inject = (id, url, callback) ->
		d = document
		s = 'script'
		fjs = d.getElementsByTagName(s)[0]
		# if d.getElementById(id) then callback()
		js = d.createElement(s)
		# js.id = id
		
		callback = _.once callback
		js.onload = () -> 
			callback()
		js.onerror = () ->
			callback(new Error("Script #{url} could not load"))

		js.src = url
		fjs.parentNode.insertBefore(js, fjs)

	###*
	 * Load all plugins from localStorage
	 * @param  {Function} callback 
	 * @param {Error/null} [callback.err] 
	###
	load: (callback, options) ->
		options ?= {}
		options.safe ?= false

		if options.safe
			this.safe = true
			console.log "Entering safe mode; not loading any plugins."

		plugins.fetch {
			success: (collection, response, opt) ->
				async.map collection.models, 
					(model, next) ->
						if options.safe 
							next(null)
						else do (model) ->
							inject model.get('url'), model.get('url'), 
							(err) ->
								if err 
									model.set('error', err)
									next(err)
								else
									model.set('error', false)
									console.log "Loaded plugin from " + model.get('url')
									next(null)
					(err) ->
						callback err

			error: (collection, response, opt) -> 
				callback new Error('Unable to fetch plugins from LocalStorage')
		}

	###*
	 * @property {Boolean} safe 
	 * `true` if the page is in "safe mode" (and thus no plugins are loaded).
	 * The plugins #collection will be populated regardless.
	###

	###*
	 * @property {Boolean} dirty 
	 * `true` if the plugins #collection has changed since the page was loaded 
	 * (and therefore if the page needs to be refreshed for changes to take 
	 * effect).
	###
	dirty: false

	###*
	 * @property {UI3D.Plugins.PluginsCollection} collection
	 * Backbone collection containing the loaded plugins
	###
	collection: plugins
	Plugin: Plugin




# -----------------------------------------------------------------------------

###*
 * @class  UI3D.Canvas3D
 * Represents a {@link C3D.Canvas3D 3D canvas} with a toolbar and associated user interface
###
class UI3D.Canvas3D
	constructor: (config) ->
		config ?= {}
		_.extend @, config

		###*
		 * @property {jQuery} el
		###
		@el = $(document.body)
		@filename = 'Untitled'
		@init()

		@version = VERSION

	init: (file) ->
		main = require('./views/main.jade')
		# debugger
		@el.html main(@)
		@el.prop("tabindex","0")
		@el.focus()

		###*
		 * @property {C3D.Canvas3D} cx
		 * @property {C3D.Canvas3D} canvas
		###
		if file? then @cx = C3D.Canvas3D.load file
		else @cx = new C3D.Canvas3D()
		@canvas = @cx

		@cx.stats = @stats
		@cx.init()
		@cx.setActiveTool('Pointer')
		window.cx = @cx


		@test = do =>
			int = (c, r) ->
				[c-r..c+r]

			{width, height, depth} = @canvas.lattice

			flBlock: () => @cx.ctrls.Voxels.addBy (x,y,z) => true
			bigBlock: () => @cx.ctrls.Voxels.addBy (x,y,z) => x in int(width/2,5) and y < 10 and z in int(depth/2,5)
			smBlock: () => @cx.ctrls.Voxels.addBy (x,y,z) => x in int(width/2,2) and y < 4 and z in int(depth/2,2)
			tnBlock: () => @cx.ctrls.Voxels.addBy (x,y,z) => x in int(width/2,1) and y < 2 and z in int(depth/2,1)
			offLattice: () =>
				s = {
					plane: 'X'
					routing: ({ pos: [0,0,0].concat(i), dir: 1 } for i in [-1, -1, -1, 0, 1, 2, 3, -1, -1, -1, -1, -1, 4, 5, 6, 7, 8, 9, 10, 11, 12, -1, -1, -1, -1, -1, -1]) 
				}
				@cx.data.add new C3D.models.SST(s)

		###*
		 * @property {rivets.View}
		###
		@view = rivets.bind @el, { canvas: @cx, ui: @ }

		do (ui=@) =>
			# utils.uploadElement @el, '.nb-open.btn-file :file', (contents, filename, reader, file) ->
			# 	ui.loadNB contents
			# 	ui.filename = pathutils.removeExt filename 

			@el.on 'change', '.nb-open.btn-file :file', () ->
				utils.handleUpload this, (contents, filename, reader, file) ->
					ui.loadNB contents
					ui.filename = pathutils.removeExt filename

			# utils.uploadElement @el, '.nb-import.btn-file :file', (contents, filename, reader, file) ->
			# 	type = pathutils.extname(filename)
			# 	ui.import contents, type

			@el.on 'change', '.nb-import.btn-file :file', (e) =>
				input = e.target
				index = 1
				totalFiles = undefined

				sort = sorter(['json','xlsx','xls','csv','tsv'])

				mode = (filename, type) ->
					switch type 
						when 'xls','xlsx' then 'binary' 
						else 'text'

				handler = (contents, filename, reader, file, total, callback) =>
					@showMessage "Importing #{filename} (<b>#{index}&nbsp;/&nbsp;#{total}</b>)"
					totalFiles = total
					index++ 

					type = pathutils.extname(filename)
					ui.import contents, type, filename, callback

				final = (err) =>
					@showMessage "Finished importing <b>#{totalFiles}</b> files."
					# @hideMessage()

				utils.handleMultiUpload input, sort, handler, mode, final
		###*
		 * @property {UI3D.SequenceWindow}
		###
		@sequenceWindow = new UI3D.SequenceWindow(@)

		###*
		 * @property {UI3D.PowerEdit}
		###
		@powerEdit = new UI3D.PowerEdit(@)

		###*
		 * @property {UI3D.BoxMaker}
		###
		@boxMaker = new UI3D.BoxMaker(@)

		###*
		 * @property {UI3D.TSManager}
		###
		@tsManager = new UI3D.TSManager(@)

		###*
		 * @property {UI3D.CoffeeHelp}
		###
		@coffeeHelp = new UI3D.CoffeeHelp(@)

		###*
		 * @property {UI3D.HelpWindow}
		###
		@helpWindow = new UI3D.HelpWindow(@)

		###*
		 * @property {UI3D.LatticeWindow}
		###
		@latticeWindow = new UI3D.LatticeWindow(@)

		###*
		 * @property {UI3D.DrawProgress}
		###
		@progressBar = new UI3D.DrawProgress(@)
		###*
		 * @property {UI3D.CameraManager} 
		###
		@cameraManager = new UI3D.CameraManager(@)

		###*
		 * @property {UI3D.MessageBox} 
		###
		@messageBox = new UI3D.MessageBox(@)


		###*
		 * @property {UI3D.PluginManager} 
		###
		@pluginManager = new UI3D.PluginManager(@)

		# auto-initialize tooltips
		$('[title]').tooltip {
			container: 'body'
			placement: 'auto'
		}

	###*
	 * Gets the filename associated with this canvas
	 * @return {String} filename
	###
	getFileName: () -> @el.find('.nb-filename').first()?.val()

	import: (data, type, filename, callback) =>
		console.log "Importing #{filename}"

		switch type
			when 'xls','xlsx','csv','tsv','txt'
				@sequenceWindow.handleUpload data, filename
				@sequenceWindow.once 'close', callback
			else 
				@canvas.import data, type, callback

	###*
	 * Prompts a file with the given name and content to be downloaded
	 * @param  {String} filename 
	 * @param  {String/Blob} content 
	###
	saveFile: (filename, content) ->
		if not (content instanceof Blob)
			blob = new Blob([content], {type: "text/plain;charset=utf-8"})
		saveAs(blob, filename)

	ext: 'nbk'

	###*
	 * Saves the current canvas as a NanoBricks (.nbk) file
	###
	saveNB: () =>
		data = @cx.save()
		filename = @getFileName()
		@saveFile filename+'.'+@ext, JSON.stringify(data)

	###*
	 * Loads a NanoBricks (.nbk) file into the editor
	 * @param  {String} text 
	###
	loadNB: (text) =>
		file = JSON.parse(text)
		@init file

	###*
	 * Exports the current strands as caDNAno and saves a .json file
	###
	saveCaDNAno: () =>
		json = @cx.ctrls.SST.toCaDNAno() 
		filename = @getFileName()		
		@saveFile filename+'.json', JSON.stringify(json)

	saveCanDo: () =>
		data = @cx.ctrls.SST.toCanDo() 
		filename = @getFileName()		
		@saveFile filename+'.cdo', data

	saveSVG: () =>
		data = @cx.export('svg') 
		filename = @getFileName()		
		@saveFile filename+'.svg', data

	saveOBJ: () =>
		data = @cx.export('obj') 
		filename = @getFileName()		
		@saveFile filename+'.obj', data

	saveSTL: () =>
		data = @cx.export('stl') 
		filename = @getFileName()		
		@saveFile filename+'.stl', data

	savePNG: () =>
		@cx.export 'png', (blob) =>
			filename = @getFileName()		
			@saveFile filename+'.png', blob

	###*
	 * Exports the sequences of the current strands as a CSV file
	###
	saveCSV: () =>
		data = @cx.export 'csv'
		filename = @getFileName()		
		@saveFile filename+'.csv', data

	###*
	 * Toggle display of the #sequencesWindow
	###
	toggleSequences: () =>
		@sequenceWindow.toggle()

	###*
	 * Toggle display of the #latticeWindow
	###
	toggleLattice: () =>
		@latticeWindow.toggle()

	compile: () =>
		@cx.ctrls.SST.compile()

	showMessage: () => @messageBox.showMessage arguments...
	hideMessage: () => @messageBox.hideMessage arguments...

###*
 * @class  UI3D.DrawProgress
 * Represents the progress of the {@link C3D.Canvas3D#drawQueue drawing queue}.
###
class UI3D.DrawProgress
	constructor: (@ui) ->
		@canvas = @ui.canvas
		@canvas.on 'drawprogress', @update
		@render()
		@el.hide()
		undefined

	render: () ->
		tpl = require("./views/progress-bar.jade")
		@el = $ tpl(@)
		@ui.el.append @el		
		@progressEl = @el.find '.progress-bar'

	update: (progress) =>
		if progress < 1 
			@progressEl.css('width', Math.round(progress * 100)+'%')
			@el.show()
		if progress is 1
			@el.hide()

###*
 * Displays a window for managing {@link UI3D.Plugins plugins}.
###
class UI3D.PluginManager
	constructor: (@ui) ->
		plugins = @plugins = UI3D.Plugins

		tpl = require("./views/plugins-window.jade")
		@el = $ tpl(@)
		@ui.el.append @el
		@modal = @el.modal({ show: false })

		@view = rivets.bind @el, { pm: @, canvas: @ui.cx }
		Backgrid.DeleteCell = Backgrid.Cell.extend {
			className: 'delete-cell'
			template: _.template("<button class='btn btn-danger'>Delete</button>")
			events: {
				"click": "deleteRow"
			}
			deleteRow: (e) ->
				e.preventDefault()
				plugins.dirty = true
				this.model.destroy()
				# this.model.collection.remove(this.model);
			
			render: () ->
				this.$el.html(this.template())
				this.delegateEvents()
				return this
		}

		Backgrid.ErrorCell = Backgrid.Cell.extend {
			className: 'error-cell'
			formatter: {
				fromRaw: (err) ->
					if err is false
						"<span class='text-success' data-toggle='tooltip' title='Plugin loaded successfully.'><i class='fa fa-check'></i> Loaded</span>"
					else if err is undefined
						"<span class='text-warning' data-toggle='tooltip' title='Plugin will be loaded the next time you refresh the page.'><i class='fa fa-question'></i> Not Loaded</span>"
					else if err
						"<span class='text-danger' data-toggle='tooltip' title='Plugin failed to load: #{err.message}'><i class='fa fa-times'></i> Failed to Load</span>"

				toRaw: () ->
			}
			render: () ->
				this.$el.empty();
				this.$el.html(this.formatter.fromRaw(this.model.get(this.column.get("name"))));
				this.$el.find("span[data-toggle='tooltip']").tooltip({ container: 'body' })
				this.delegateEvents();
				return this;
		}


		columns = [{
			name: "error"
			label: "Status"
			cell: "error"
			editable: false
		},{
			name: "url"
			label: "URL"
			cell: "string"
		}, {
			name: "delete",
			label: "",
			cell: "delete"	
		}]

		@grid = new Backgrid.Grid({
			columns: columns,
			collection: @plugins.collection,
			emptyText: "No Plugins Loaded"
		});

		@el.find('.nb-plugins-table').append(@grid.render().el);
		@el.find('.nb-plugins-add').on 'click', () => @add( @el.find('.nb-plugins-url').val() )
		@el.find('.nb-refresh-button').on 'click', @refresh

		url = window.location.origin + window.location.pathname
		@el.find('.nb-plugins-leave-safe-mode').attr('href', url)
		@el.find('.nb-plugins-enter-safe-mode').attr('href', url + "?safe=true")
		@ui.el.find('.nb-plugins-link').on 'click', () => @toggle()

	add: (url) ->
		plugin = new UI3D.Plugins.Plugin {url: url}
		@plugins.collection.add plugin
		@plugins.dirty = true
		plugin.save()

	refresh: () =>
		window.location.reload()

	enterSafeMode: () =>
		url = window.location.origin + window.location.pathname + "?safe=true"
		window.location.href = url

	leaveSafeMode: () =>
		url = window.location.origin + window.location.pathname
		window.location.href = url
	###*
	 * Toggles visibility of this window
	###
	toggle: () ->
		@el.modal('toggle')

###*
 * @class  UI3D.MessageBox
 * Shows a closeable, non-modal message box
###
class UI3D.MessageBox
	constructor: (@ui) ->
		tpl = require("./views/message-box.jade")
		@el = $ tpl(@)
		@ui.el.append @el

	###*
	 * Show a message
	 * @param  {String} message 
	 * @param  {Object} options 
	 * @param {Boolean} options.closeable 
	###
	showMessage: (message, options) =>
		options ?= {}
		options.closeable ?= true

		@el.find('.nb-message-box-content').html message
		if options.closable then @el.find('.nb-message-box .close').show()
		else @el.find('.nb-message-box .close').show()
		@el.show()

	###*
	 * Hide the current message
	###
	hideMessage: () =>
		@el.hide()		

###*
 * Manages the positioning of the camera based on UI buttons
 * @extends {Backbone.Model}
###
class UI3D.CameraManager extends Backbone.Model
	constructor: (@ui) ->
		super { cameraMode: 'perspective' }
		tpl = require("./views/camera-manager.jade")
		@el = $ tpl(@)
		@ui.el.find('.nb-views').prepend @el

		@on 'change:cameraMode', @changeCameraMode
		@view = rivets.bind @el,  { cm: @, canvas: @ui.cx }

		me = @
		@el.find('.nb-view-snap').on 'click', () ->
			me.setView $(@).data 'snap'

	###*
	 * Snaps the camera to a pre-defined view
	 * @param {'top'/'left'/'right'/'front'/'back'/'iso'} view [description]
	###
	setView: (view) =>
		pos = switch view 
			when 'top'   then [0,-1,0]
			when 'right' then [-1,0,0] 
			when 'left'  then [+1,0,0]
			when 'front' then [0,0,+1] 
			when 'back'  then [0,0,-1]
			when 'iso'   then [+1,+1,0]
		@ui.cx.setView pos...
		for r,i in pos
			if r is 0 then $(".range-group[data-slice-axis=#{i}]").addClass 'active'
			else $(".range-group[data-slice-axis=#{i}]").removeClass 'active'

	###*
	 * @private
	 * Switches the camera mode between orthogonal, perspective, and anaglyph.
	 * @param  {Backbone.Model} model
	 * @param  {'perspective'/'ortho'/'anaglyph'} mode [description]
	###
	changeCameraMode: (model, mode) =>
		switch mode
			when 'perspective'
				@ui.cx.set 'cameraMode', 'perspective'
				@ui.cx.set 'anaglyph', false
			when 'ortho'
				@ui.cx.set 'cameraMode', 'ortho'
				@ui.cx.set 'anaglyph', false
			when 'anaglyph'
				@ui.cx.set 'cameraMode', 'perspective'
				@ui.cx.set 'anaglyph', true

###*
 * Shows a window letting the user change the current lattice
###
class UI3D.LatticeWindow
	constructor: (@ui) ->
		tpl = require("./views/lattice-window.jade")
		@el = $ tpl(@)
		@ui.el.append @el
		@modal = @el.modal({ show: false })

		getClassName = (lattice) -> 
			lattice.constructor._class

		###*
		 * @property {String} lattice
		 * Name of the {@link vox.lattice.Lattice} sub-class that's currently 
		 * selected 
		###
		@lattice = getClassName(@ui.cx.lattice)
		# @lattice = @ui.cx.lattice.constructor.name

		@ui.cx.on 'change:lattice', (model, lattice) =>
			@lattice = getClassName(lattice)

		@view = rivets.bind @el, { lw: @, canvas: @ui.cx }

	###*
	 * Gets the {@link vox.lattice.Lattice#description description}
	 * for the currently-selected #lattice
	 * @return {String} 
	###
	latticeDescription: () ->
		@latticeCls()?.prototype.description ? ""

	###*
	 * Gets the class  (within the vox.lattice namespace) for the currently-
	 * selected #lattice.
	 * @return {Function} 
	###
	latticeCls: () ->
		latticeClsName = @lattice
		# latticeCls = vox.lattice[latticeClsName]
		latticeCls = vox.index(global, latticeClsName)

	###*
	 * Determines whether the currently-selected #lattice 
	 * is marked as {@link vox.lattice.Lattice#isExperimental experimental}
	 * @return {String} 
	###
	latticeIsExperimental: () ->
		@latticeCls()?.prototype.experimental or false

	latticeWidth: () -> "Width = " + @latticeCls()?::width ? 10
	latticeHeight: () -> "Height = " + @latticeCls()?::height ? 10
	latticeDepth: () -> "Depth = " + @latticeCls()?::depth ? 10

	###*
	 * Changes the {@link C3D.Canvas3D#lattice lattice} of the canvas
	 * to the currently-selected #lattice.
	###
	changeLattice: () =>
		latticeCls = @latticeCls()
		if latticeCls? 
			width = parseInt($('.nb-lattice-window .nb-width')?.val())
			height = parseInt($('.nb-lattice-window .nb-height')?.val())
			depth = parseInt($('.nb-lattice-window .nb-depth')?.val())
			lattice = new latticeCls {
				width: if isNaN(width) then latticeCls::width else width
				height: if isNaN(height) then latticeCls::height else height
				depth: if isNaN(depth) then latticeCls::depth else depth
			}
			@ui.cx.ctrls.SST.changeLattice lattice

		@el.modal('hide')

	###*
	 * Toggles visibility of this window
	###
	toggle: () ->
		@el.modal('toggle')

###*
 * Shows a popup window with help for Coffeescript
###
class UI3D.CoffeeHelp
	constructor: (@ui) ->
		text = require("../../help/coffee-script.md")
		tpl = require("./views/coffee-help-window.jade")
		@el = $ tpl( { body: text } )
		@ui.el.append @el
		@modal = @el.modal({ show: false })
		# utils.codeMirrorHighlight @el

		$('body').on 'click', '.coffee-help', @toggle

	###*
	 * Toggles visibility of this window
	###
	toggle: () =>
		@el.modal('toggle')

###*
 * Shows a popup window with help for NanoBricks
###
class UI3D.HelpWindow
	constructor: (@ui) ->
		tpl = require("./views/help-window.jade")
		index = require("../../dist/help/index.json")
		index.baseUrl = @baseUrl = 'dist/help/html/'
		@el = $ tpl( index )
		@ui.el.append @el
		@modal = @el.modal({ show: false })
		@iframe = @el.find('iframe')

		me = @
		$('body').on 'click', '.help', () -> 
			href = $(@).attr('href')
			if href? and href isnt '#'
				if href[0] is '#' then href = href.substring 1
				me.go href

			me.toggle()
			false

	###*
	 * Toggles visibility of this window
	###
	toggle: () =>
		@el.modal('toggle')

	go: (id) => 
		if id.indexOf('#') isnt -1
			parts = id.split('#')
			parts[0] = @baseUrl + parts[0] + '.html'
			uri = parts.join('#')
		else 
			uri = @baseUrl+id+'.html'
		@iframe.prop('src', uri)

###*
 * Shows a popup window for generating/editing sequences
###
class UI3D.SequenceWindow
	constructor: (@ui) ->
		_.extend @, Backbone.Events

		# @el = @ui.el.find('.nb-sequences-window')
		tpl = require("./views/sequence-window.jade")
		@el = $ tpl(@)
		@ui.el.append @el
		@modal = @el.modal({ show: false })

		@view = rivets.bind @el, { sw: @, canvas: @ui.cx }
		utils.dragDropTextarea @el.find('textarea')

		do (me=@) ->
			me.el.on 'change', '.nb-sequences-excel-upload', () ->
				utils.handleUpload this, me.handleUpload, (filename, ext) -> if ext is 'xls' or ext is 'xlsx' then 'binary' else 'text'

		# utils.uploadElement @el, '.nb-sequences-excel-upload', ((contents, filename, reader, file) =>
		# 	ext = pathutils.extname filename
		# 	@getActiveSSet()?.setWorkbook contents, ext
		# ), (filename, ext) -> if ext is 'xls' then 'binary' else 'text'

		# seriously hate backgrid
		Backgrid.RoutingCell = Backgrid.Cell.extend {
			className: "routing-cell"
			formatter: {
				fromRaw: (routing) ->
					doms = C3D.models.SST.routingString routing

					pcs = for dom in doms.split('; ')
						"<span class='label label-default' style='display: inline-block;'>#{dom}</span>"
					pcs.join("&nbsp;")

				toRaw: () ->
			}
			render: () ->
				this.$el.empty();
				this.$el.html(this.formatter.fromRaw(this.model.get(this.column.get("name"))));
				this.delegateEvents();
				return this;
		}



		columns = [{
			name: "name"
			label: "Name"
			cell: "string"
		},{
			name: "sequence"
			label: "Sequence"
			cell: "string"
		},{
			name: "routing"
			label: "Routing"
			cell: "routing"
			# cell: "string"
			editable: false,
		}, {
			name: "group"
			label: "Group"
			cell: "string"
		}, {
			name: "plate"
			label: "Plate"
			cell: "string"
		}, {
			name: "well"
			label: "Well"
			cell: "string"
		}, {
			name: "cadnano"
			label: "caDNAno"
			cell: "string"
		}]

		@grid = new Backgrid.Grid({
			columns: columns,
			collection: @ui.cx.ctrls.SST.pagedStrands
		});

		@el.find('.nb-sequences-table').append(@grid.render().el);

		paginator = new Backgrid.Extension.Paginator({

			# If you anticipate a large number of pages, you can adjust
			# the number of page handles to show. The sliding window
			# will automatically show the next set of page handles when
			# you click next at the end of a window.
			windowSize: 20, # Default is 10

			# Used to multiple windowSize to yield a number of pages to slide,
			# in the case the number is 5
			slideScale: 0.25, # Default is 0.5

			# Whether sorting should go back to the first page
			goBackFirstOnSort: false, # Default is true

			collection: @grid.collection

			controls: {
				rewind: {label: "&#x300A;", title: "First"}, 
				back: {label: "&#x3008;", title: "Previous"},
				forward: {label: "&#x3009;", title: "Next"},
				fastForward: {label: "&#x300B;", title: "Last"}
			}
		})

		@el.find('.nb-sequences-table').append(paginator.render().el);
	
		@excelColumnTypes = ({dest: dest} for dest in ['name', 'sequence', 'well', 'plate', 'routing', 'group', ''])

		@el.find('.nb-sequences-generate').on 'click', @generateSequences
		@el.find('.nb-sequences-thread').on 'click', @threadSequences
		@el.find('.nb-sequences-generate-thread').on 'click', @generateThreadSequences
		@el.find('.nb-sequences-preview').on 'click', @toggleSequencePreview
		@el.find('.nb-sequences-export').on 'click', @exportSequences

		@el.on 'show.bs.modal', () =>
			@trigger 'open'
		@el.on 'hide.bs.modal', () =>
			@trigger 'close'

	###*
	 * Toggles visibility of this window
	###
	toggle: () =>
		@el.modal('toggle')
		# if @el.modal
		# if @el.data('bs.modal').isShown
		# 	@hide()
		# else @show()

	show: () =>
		@el.modal('show')

	hide: () =>
		@el.modal('hide')

	toggleSequencePreview: () =>
		seq = @ui.cx.views.Sequences
		seq.set 'active', not seq.get('active')

	tryCatchError: (f) =>
		# do f
		@error = undefined
		try
			do f
		catch e
			console.error e
			@error = e.message

	exportSequences: () =>
		@ui.saveCSV()

	generateSequences: () =>
		@tryCatchError () =>
			@ui.cx.ctrls.Sequences.generateSequences()

	threadSequences: () =>
		@tryCatchError () =>
			@ui.cx.ctrls.Sequences.threadSequences()

	generateThreadSequences: () =>
		@tryCatchError () =>
			@ui.cx.ctrls.Sequences.generateThreadSequences()

	handleUpload: (contents, filename) =>
		ext = pathutils.extname filename
		switch ext
			when 'xls','xlsx','csv','tsv'
				@sequenceFileName = filename
				@updateWorkbook contents, ext
			else
				sset = @getSSetByType('linear')
				sset?.set('string',contents)

		@show()


	updateWorkbook: (contents, ext) =>
		type = if ext is 'xls' or 'xlsx' then 'binary' else 'string'
		sset = @getSSetByType('excel')

		if sset?
			sset.setWorkbook contents, ext, { type: type }
			@previewData = sset.getPreviewData()
			@previewSheets = sset.getPreviewSheets()

	getSSet: (type) =>
		@ui.cx.ctrls.Sequences.getSSet type

	getActiveSSet: () =>
		@ui.cx.ctrls.Sequences.get 'active'

	getSSetByType: (type) =>
		sset = @getActiveSSet()
		if sset?.type isnt type
			sset = @getSSet type
			if sset?
				@ui.cx.ctrls.Sequences.setActive sset
		sset

###*
 * Shows window for programmatically selecting/editing voxels and strands (PowerEdit)
###
class UI3D.PowerEdit extends Backbone.Model
	constructor: (@ui) ->
		super { 'target':'Voxels' }
		tpl = require("./views/poweredit.jade")
		@el = $ tpl(@)
		@ui.el.append @el

		@code = 
			"Voxels":
				select: "(x, y, z, voxel) -> \n\t"
				transform: "(x, y, z, voxel) -> \n\t"
			"Strands":
				select: "(strand) -> \n\t"
				transform: "(strand) -> \n\t"

		# build CodeMirror
		config = {
			height: "5em"
		}
		###*
		 * @property {CodeMirror} select 
		 * Source code for the body of the `select` function
		###
		@select = utils.codeMirrorFromTextarea '.nb-poweredit-select', config

		###*
		 * @property {CodeMirror} transform` 
		 * Source code for the body of the `transform` function
		###
		@transform = utils.codeMirrorFromTextarea '.nb-poweredit-transform', config
		

		# update hints when target changes
		@on 'change:target', @changeTarget
		@changeTarget @, 'Voxels'
		@view = rivets.bind @el, { pe: @ }

		# hide and bind listeners
		@el.hide()
		@ui.el.find('.nb-action-poweredit').on 'click', @toggle
		@el.find('.nb-poweredit-apply').on 'click', @selectTransform
		@el.find('button.close[data-dismiss=panel]').on 'click', @toggle

	changeTarget: (model, target) =>
		@code ? @code = {}
		@code[@previous('target')] = {
			select: @select.getValue()
			transform: @transform.getValue()
		}
		@select.setValue @code[target].select
		@transform.setValue @code[target].transform

	###*
	 * Compiles a CoffeeScript source string, returning the result as a function
	 * @param  {String} script 
	 * @return {Function} 
	###
	compile: (script) -> compile(script)

	selectTransform: () =>
		target = @get('target')
		@set 'select-error', ''
		@set 'transform-error', ''
		selectCode = buildScriptFactory @select.getValue()
		transformCode = buildScriptFactory @transform.getValue()

		try
			selectGenerator = @compile selectCode
		catch e
			@set 'select-error', e

		try 	
			transformGenerator = @compile transformCode
		catch e 
			@set 'transform-error', e

		if selectGenerator? and transformGenerator?
			select = selectGenerator @ui.cx.ctrls.Voxels, @ui.cx.ctrls.SST, @ui.cx.lattice 
			transform = transformGenerator @ui.cx.ctrls.Voxels, @ui.cx.ctrls.SST, @ui.cx.lattice 

			@ui.canvas.ctrls[if target is "Strands" then "SST" else target].selectTransform(select, transform)

	###*
	 * Toggles visibility of this window
	###
	toggle: () =>
		@el.toggle()

###*
 * Manages various {@link UI3D.TSEditor translation scheme editors}; 
 * opens/closes the editor when the item is selected in the translation
 * scheme menu.
###
class UI3D.TSManager extends Backbone.Model
	constructor: (@ui) ->
		super { crystal: false, mode: 'merge' }
		tpl = require("./views/tsmanager.jade")
		@el = @ui.el.find('.nb-compiler')
		@el.append tpl(@)

		me = @
		@tses = {}
		@ui.el.find('.nb-compile').on 'click', @compile
		@el.on 'click', '.nb-ts-list-item', () ->
			cid = $(@).data 'identity'
			me.edit cid

		@view = rivets.bind @el, { tm: @, ui: @ui, canvas: @ui.canvas }

		@on 'change:crystal_x', @updateCrystalMap
		@on 'change:crystal_y', @updateCrystalMap
		@on 'change:crystal_z', @updateCrystalMap

	getExtents: () =>
		extents = @ui.cx.ctrls.Voxels.getExtents()
		shape = @ui.cx.lattice.shape()
		[
			if @get('crystal_x') then [extents[0][0]-1, extents[0][1]+1] else [-1, shape[0]]
			if @get('crystal_y') then [extents[1][0]-1, extents[1][1]+1] else [-1, shape[1]]
			if @get('crystal_z') then [extents[2][0]-1, extents[2][1]+1] else [-1, shape[2]]
		]

	getCrystalMap: () =>
		extents = @ui.cx.ctrls.Voxels.getExtents()
		[
			if @get('crystal_x') then extents[0] else undefined
			if @get('crystal_y') then extents[1] else undefined
			if @get('crystal_z') then extents[2] else undefined
		]

	updateCrystalMap: () =>
		@crystalMap = @getCrystalMap()
		@ui.cx.views.SST.set 'crystal', @crystalMap

	isCrystal: () =>
		@get('crystal_x') or @get('crystal_y') or @get('crystal_z')

	compile: () =>
		options = { merge: (@get('mode') is 'merge') }
		if @isCrystal() 
			options.crystal = @crystalMap
			options.extents = @getExtents()
		@ui.cx.ctrls.SST.compile options

	edit: (cid) ->
		if cid not of @tses
			ts = @ui.cx.ctrls.SST.findTranslationScheme cid
			if not ts then return
			if ts.isCustomTranslationScheme
				if cid not of @tses 
					@tses[cid] = new UI3D.TSEditor(@ui, ts)

		if cid of @tses then @tses[cid].toggle()



###*
 * Allows the user to edit a 
 * {@link C3D.models.ts.Custom custom translation scheme}.
###
class UI3D.TSEditor
	constructor: (@ui, ts) ->
		tpl = require("./views/tsedit.jade")
		@el = $ tpl(@)
		@ui.el.append @el
		@ts = ts ? new C3D.models.ts.Custom { }
		@view = rivets.bind @el, { ed: @, ts: ts }

		config = {
			lineNumbers: true
		}
		@editor = utils.codeMirrorFromTextarea '.nb-tsedit-source', config
		$(@editor.display.wrapper).on 'keydown', (e) -> e.stopPropagation()

		@el.find('button.close').on 'click', @toggle
		@el.hide()

	update: () ->
		try 
			@ts.set 'source', @editor.getValue() 
		catch e
			@set 'error', e
	###*
	 * Compiles a CoffeeScript source string, returning the result as a function
	 * @param  {String} script 
	 * @return {Function} 
	###
	compile: (script) -> compile(script)
	
	###*
	 * Toggles visibility of this window
	###
	toggle: () =>
		@el.toggle()

###*
 * Shows a box allowing the user to programmatically add/remove/update voxels
 * using C3D.ctrls.Voxels#addBy, {@link C3D.ctrls.Voxels#removeBy removeBy},
 * and {@link C3D.ctrls.Voxels#setBy setBy}.
###
class UI3D.BoxMaker
	constructor: (@ui) ->

		tpl = require("./views/boxmaker.jade")
		@el = $ tpl(@)
		@ui.el.append @el

		config = {
			height: "70%"
		}

		@query = utils.codeMirrorFromTextarea @el.find('.nb-boxmaker-query'), config
		@el.find('.nb-boxmaker-add').click @applyQueryAdd
		@el.find('.nb-boxmaker-remove').click @applyQueryRemove
		@el.find('.nb-boxmaker-apply').click @applyQuerySet

		@ui.el.find('.nb-action-boxmaker').on 'click', @toggle
		@el.find('button.close[data-dismiss=panel]').on 'click', @toggle
		@el.hide()
		
		# @el.popover({
		# 	container: 'body'
		# 	html: true
		# 	content: tpl(@)
		# 	title: 'Add voxels'
		# 	placement: 'bottom'
		# }).on('shown.bs.popover', @onShow)

	###*
	 * Gets the Bootstrap tooltip associated with this element
	 * @return {Object} 
	###
	tip: () => @el.data('bs.popover').tip()

	applyQueryAdd: () => @applyQuery 'add'
	applyQueryRemove: () => @applyQuery 'remove'
	applyQuerySet: () => @applyQuery 'set'

	###*
	 * compiles and runs the entered #query with the given mode 
	 * @param  {"add"/"remove"/"set"} action 
	 * Determines whether to use {@link C3D.ctrls.Voxels#addBy},
	 * {@link C3D.ctrls.Voxels#removeBy}, or {@link C3D.ctrls.Voxels#setBy}.
	###
	applyQuery: (action) =>
		queryCode = buildScriptFactory @query.getValue()

		# @queryPreamble = "(x, y, z) -> \n"
		# generator = @compile @preamble + @queryPreamble + indent(@query.getValue())
		generator = @compile queryCode
		f = generator @ui.cx.ctrls.Voxels, @ui.cx.ctrls.SST, @ui.cx.lattice 
		switch action
			when 'add' then @ui.canvas.ctrls.Voxels.addBy f
			when 'remove' then @ui.canvas.ctrls.Voxels.removeBy f
			when 'set' then @ui.canvas.ctrls.Voxels.setBy f

	###*
	 * Compiles a CoffeeScript source string, returning the result as a function
	 * @param  {String} script 
	 * @return {Function} 
	###
	compile: (script) -> compile(script)

	###*
	 * Toggles visibility of this window
	###
	toggle: () =>
		@el.toggle()


