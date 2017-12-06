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

Chance = require('chance')
XLS = require('xlsjs')
XLSX = require('xlsx')
harb = require('harb')

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
 * @class C3D.models
 * @singleton
 * @static
 *
 * This namespace contains models for use storing data in
 * the {@link C3D.Canvas3D#data data property} of the canvas.
 * All classes in this namespace should inherit
 * from C3D.models.Model, and should define a {@link C3D.models.Model#_class}
 * property so that they can be properly serialized.
###
module.exports = C3D.models = {}

###*
 * Serializable Backbone.Model class. Automatically adds the `_class` property
 * of any subclass as a Backbone attribute.
 * @abstract
 * @extends {Backbone.Model}
###
class C3D.models.Model extends Backbone.Model
	constructor: (c) ->
		c = c ? {}
		###*
		 * @property {String} _class
		 * Fully-qualified name of the class, for vivification with
		 * {@link _#vivify}.
		 * @internal
		###
		c._class = @_class
		super c
		Backbone.Select.Me.applyTo @

###*
 * Models a single voxel. Methods of this class can be used to manipulate 
 * individual voxels; to manipulate multiple voxels, you'll want to use 
 * the {@link C3D.ctrls.Voxels voxel controller}.
 * @extends {C3D.models.Model}
###
class C3D.models.Voxel extends C3D.models.Model
	_class: 'C3D.models.Voxel'
	mixin @, C3D.Base
	type: 'voxel'

	###*
	 * @cfg {Array} latticePosition
	 * The position of the voxel on the 
	 * {@link vox.lattice.Lattice lattice}. Should be a 3-element array 
	 * specifying the [x, y, z] position, where 
	 * 0 <= x < {@link vox.lattice.Lattice#width lattice.width} 
	 * 0 <= y < {@link vox.lattice.Lattice#height lattice.height} 
	 * 0 <= z < {@link vox.lattice.Lattice#depth lattice.depth} 

	###

	###*
	 * @cfg {Number/String} color
	 * The color of the voxel; can be anything accepted by the constructor to
	 * [THREE.Color](http://threejs.org/docs/#Reference/Math/Color):

	 * a hexadecimal number, a CSS-style string (e.g. `"rgb(250, 0,0)"`, 
	 * `"rgb(100%,0%,0%)"`, `"#ff0000"`, `"#f00"`, or even `"red"`)
	###

	###*
	 * Moves this voxel by the specified amount
	 * @param  {Number} dx
	 * @param  {Number} dy
	 * @param  {Number} dz
	 * @chainable
	###
	move: (dx, dy, dz) ->
		[x,y,z] = @get 'latticePosition'
		@set 'latticePosition', [x+dx, y+dy, z+dz]

	###*
	 * Moves this voxel to the specified position
	 * @param  {Number} x
	 * @param  {Number} y
	 * @param  {Number} z
	 * @chainable
	###
	moveTo: (x, y, z) ->
		@set 'latticePosition', [x, y, z]

###*
 * Models a single DNA strand. Methods of this class can be used to manipulate 
 * individual strands (extending, truncating, inserting, and deleting bases); 
 * to manipulate multiple strands (e.g. for ligation or cutting), you'll want 
 * to use the {@link C3D.ctrls.SST strands controller}.
 * @extends {C3D.models.Model}
###
class C3D.models.SST extends C3D.models.Model
	_class: 'C3D.models.SST'
	mixin @, C3D.Base
	type: 'sst'

	###*
	 * @cfg {vox.dna.Base[]} routing
	 * Describes the path of the strand through helical coordinates on the
	 * {@link vox.lattice.Lattice lattice}. Each element should have at least
	 * the following properties:
	 *
	 * -    `pos`: 4-element array giving the position of the base (X/Y/Z/Z'),
	 *      where Z' represents the position within a voxel.
	 * -    `dir`: +1 for a base pointing 5' -> 3' along the Z-azis, -1 for a
	 *      base pointing 3' -> 5'
	 * -    `seq`: string indicating how sequences should be assigned to the
	 *      base, or containing a single base sequence.
	###

	###*
	 * @cfg {String} name
	 * Name of the strand
	###

	###*
	 * @cfg {String} sequence
	 * Sequence of the strand; should be the same length as the #routing
	###

	###*
	 * Gets the base from the #routing at a particular index
	 * @param  {Number} index 
	 * @return {vox.dna.Base} 
	###
	getBase: (index) ->
		routing = @get 'routing'
		routing[index]

	###*
	 * Inserts some sequence or bases at the given `index`:
	 *
	 * Inserts 10 bases at the 5th base from the 5' end:
	 *
	 *     strand.insert(5, 10)
	 *
	 * Inserts 4 T's at the 3rd base from the 3' end:
	 *
	 *     strand.insert(-3, 'TTTT')
	 *
	 * Inserts 7 random bases at the 5' end, using a `generator` function:
	 *
	 *     strand.insert 0, 7, {}, (opt, i) ->
	 *         opt.seq = chance.character({ pool: 'ATCG' })
	 *         opt
	 *
	 * @param  {Number} index Index at which to insert
	 * @param  {String/Number/Array} value
	 * Sequence to insert. If a String, inserts one base for each letter in the string (using that letter for the base).
	 * If a Number, inserts that many bases. If an Array, inserts one base for each element of the array.
	 * @param  {Object} [options] Options to apply to each base
	 * @param  {Function} [generator] Optional function to modify each base.
	 * @param {Object} generator.options Options for the given base
	 * @param {String/Number/Array} generator.value Value for the given base
	 * @param {Object} generator.return Modified options for the given base
	 * @return {C3D.models.SST} strand
	###
	insert: (index, value, options, generator) ->
		@set 'routing', vox.dna.utils.strands.insert(_.clone(@get('routing')), arguments...)


	###*
	 * Extends the strand from the given `end`:
	 *
	 * Add the sequence 'ATAACAG' to the 3' end:
	 *
	 *     strand.extend 'ATAACAG'
	 *
	 * Add 5 bases to the 5' end:
	 *
	 *     strand.extend 5, -1
	 *
	 * @param  {String/Number/Array} value
	 * Sequence to insert. If a String, inserts one base for each letter in the string (using that letter for the base).
	 * If a Number, inserts that many bases. If an Array, inserts one base for each element of the array.
	 * @param  {Number} [dir=1] Which end to start from; +1 for 3', -1 for 5'
	 * @param  {Object} [options] Options to apply to each base
	 * @param  {Function} [generator] Optional function to modify each base.
	 * @param {Object} generator.options Options for the given base
	 * @param {String/Number/Array} generator.value Value for the given base
	 * @param {Object} generator.return Modified options for the given base
	 * @return {C3D.models.SST} strand
	###
	extend: (value, dir=1, options, generator) ->
		@set 'routing', vox.dna.utils.strands.extend(_.clone(@get('routing')), arguments...)

	###*
	 * Removes bases from the strand
	 *
	 * Remove 5 bases from the 5' end:
	 *
	 *     strand.remove 0, 5
	 *
	 * Remove 7 bases from the 3' end:
	 *
	 *     strand.remove -1, -7
	 *
	 * Remove 5 bases (3' -> 5') from the base before the 3' end:
	 *
	 *     strand.remove -2, -5
	 * 
	 * 
	 * @param  {Number} index 
	 * Index at which to remove (`0` = 5' end); use negative numbers to count 
	 * backwards from the 3' end of the strand (`-1` = 3' end).
	 * 
	 * @param  {Number} length 
	 * Number of bases to remove. Use positive numbers to remove in the 5' -> 3'
	 * direction, negative numbers to remove in the 3' -> 5' direction.
	 * 
	 * @return {C3D.models.SST} strand
	###
	remove: (index, length) ->
		@set 'routing', vox.dna.utils.strands.remove(_.clone(@get('routing')), arguments...)

	###*
	 * Removes bases from the 5' or 3' end of the strand
	 *
	 * Remove 2 bases from the 3' end:
	 *
	 *     strand.truncate 2
	 *
	 * Remove 6 bases from the 5' end:
	 *
	 *     strand.truncate 6, -1
	 * 
	 * @param  {Number} length Number of bases to remove
	 * @param  {Number} [dir=1] Which end to remove from; `+1` for 3', `-1` for 5'
	 * @return {C3D.models.SST} strand
	###
	truncate: (length, end=1) ->
		@set 'routing', vox.dna.utils.strands.truncate(_.clone(@get('routing')), arguments...)

	###*
	 * Moves all bases in the given strand by this amount
	 * @param  {Number} dx
	 * @param  {Number} dy
	 * @param  {Number} [dz1=0]
	 * @param  {Number} [dz2=0]
	 * @return {C3D.models.SST} strand
	###
	move: (dx, dy, dz1=0, dz2=0) ->
		@set 'routing', vox.dna.utils.strands.move(_.clone(@get('routing')), arguments...)

	###*
	 * Gets the 4-component position of the 5' end of this strand
	 * @return {Array} 5' end [x, y, z1, z2]
	###
	get5p: () -> _.first(@get('routing'))?.pos

	###*
	 * Gets the 4-component position of the 3' end of this strand
	 * @return {Array} 3' end [x, y, z1, z2]
	###
	get3p: () -> _.last(@get('routing'))?.pos

	###*
	 * Gets the length, in bases, of this strand
	 * @return {Number} Length
	###
	length: () -> @get('routing').length

	getSummary: (base) ->
		p5 = @get5p()
		p5 = if p5[2] is -1 then '{' + p5[0..1] + '}' else "[#{p5}]"
		p3 = @get3p()
		p3 = if p3[2] is -1 then '{' + p3[0..1] + '}' else "[#{p3}]"
		(@get('name') ? '') + " #{p5} &rarr; #{p3}" + (if base? then " \##{base}" else "")

	###*
	 * Gets a string representation of this strand's #routing
	 * @return {String} Routing string
	###
	routingString: () ->
		C3D.models.SST.routingString @get('routing')

	###*
	 * Generates a string representation of a given #routing string
	 * @param  {vox.dna.Base[]} routing 
	 * @return {String} Routing string
	###
	@routingString: (routing) ->
		# approach: iterate over each base r in the routing, grouping them 
		# into domains. A new domain is created when one base is not in the 
		# same voxel as another, or we move from an off-lattice base to an
		# on-lattice base (or vice-versa)
		doms = []
		if routing.length > 0
			offLatticeCount = 0
			for r,i in routing
				prev = routing[i-1]

				# if there's no previous base, or the previous base
				# is not adjacent to this base, and the bases aren't
				# both off-lattice
				if !prev or 
					(prev? and 					
						(r.pos[0] != prev.pos[0] or 
							r.pos[1] != prev.pos[1] or 
							r.pos[2] != prev.pos[2] or 
							Math.abs(r.pos[3] - prev.pos[3]) != 1) and
						(not (r.pos[2] == prev.pos[2] == -1)))

					# make a new domain; add the old one to the list
					if dom 
						dom.push(prev.pos) 
						doms.push dom
					dom = [r.pos]

				# if the base is off-lattice
				if r.pos[2] is -1
					# if there was no previous base or the previous base
					# wasn't off-lattice
					if prev?.pos[2] isnt -1
						# make a new off-lattice domain; add a 3rd element
						# to keep track of the number of off-lattice bases
						dom[0] = _.clone r.pos
						dom[0][4] = 0

					# count another off-lattice base
					dom[0][4] += 1

			dom.push routing[routing.length-1].pos
			doms.push dom
		
		pcs = for dom in doms
			# is the domain off-lattice? (off-lattice domains won't have a z2 
			# position and will instead record a number of off-lattice bases)
			if not dom[0][3]?
				dom[0][0..1].join(', ') + ' {' + dom[0][4] + '}'
			else 
				dom[0][0..2].join(', ') + ', (' + dom[0][3] + '...' + dom[1][3] + ")"
		pcs.join("; ")

	###*
	 * Merges the attributes from some other strand into this one
	 * @param  {C3D.models.SST} src 
	 * @internal
	###
	merge: (src) ->
		for key, value of src.attributes
			if not @get(key)? then @set(key, value)

# -----------------------------------------------------------------------------


###*
 * Models a set of sequences for a {@link vox.lattice.Lattice lattice}
###
class C3D.models.SequenceSet extends C3D.models.Model
	_class: 'C3D.models.SequenceSet'
	mixin @, C3D.Base
	type: 'sequenceset'
	isSequenceSet: true

	@complements = { 'A': 'T', 'G': 'C', 'T': 'A', 'C': 'G', '_':'_'}

	constructor: () ->
		super arguments...
		@set 'name', @constructor._name

	markGenerate: () ->
		@set 'timestamp', new Date()

	###*
	 * Runs the initial sequence generation algorithm. By default,
	 * calls #generator (if defined) for every voxel position on the
	 * lattice, cacheing the results in the #sequences ndarray.
	 * @param  {vox.lattice.Lattice} lattice
	###
	generate: (lattice) ->
		@sequences = ndarray([], lattice.shape())
		if @generator
			lattice.each (a, b, c) =>
				len = lattice.length(a,b,c)
				seq = @generator(a, b, c, len, lattice)
				@sequences.set a,b,c, seq
		@markGenerate()

	###*
	 * @method generator
	 * @abstract
	 * If defined, this method will be called by #generate for each position
	 * within the lattice; must return a string of the requested `length`.
	 *
	 * @param {Number} a
	 * @param {Number} b
	 * @param {Number} c
	 * @param {Number} length Length of the domain at this position, in bases
	 * @param {vox.lattice.Lattice} lattice
	 * @return {String} generated sequence
	###

	###*
	 * Threads the {@link #generate}d sequences onto the a set of strands
	 * @param  {C3D.models.SST[]} strands
	 * Array of strand models to be threaded. The `sequence` property of
	 * each `strand` will be set to the generated sequence.
	###
	thread: (strands) ->

		if not @canThread() then return 
		for strand in strands
			routing = strand.get('routing')
			sequence = ''

			# for each base in strand routing
			for r, i in routing
				seq = @sequences.get(r.pos[0], r.pos[1], r.pos[2]) ? ''
				b = ''

				# check if base has locked sequence
				if r.seq?
					b = switch r.seq
						when 'polyT' then 'T'
						when 'dom' then ''
						else r.seq

				# if not, then get sequence from grid
				if not b
					# skip off-lattice bases for now
					if r.pos[3] == -1
						b = '_'
					else
						# find appropriate base
						b = seq[r.pos[3]] ? '_'

						# complement if necessary
						if r.dir is -1 then b = @constructor.complements[b]

				sequence += b

			# update sequence
			strand.set('sequence', sequence)

	canThread: () -> @sequences?

###*
 * @singleton
 * @static
 *
 * Classes in this namespace represent
 * {@link C3D.models.SequenceSet sets of sequences}. Each sequence set
 * should be able to provide sequences for every base of every voxel on a
 * {@link vox.lattice.Lattice lattice}.
###
C3D.models.ss = {}

###*
 * @class  C3D.models.ss.LinearSequenceSet
 * Represents a set of sequences that comes from a single linear string.
 * The string is automatically split to represent each voxel.
###
class C3D.models.ss.LinearSequenceSet extends C3D.models.SequenceSet
	_class: 'C3D.models.ss.LinearSequenceSet'
	@_name: 'From existing sequence grid'
	ssType: 'linear'
	description: """

	Load sequences from a block by assigning a sequence to each voxel.
	"""
	constructor: () ->
		super arguments...
		###*
		 * @cfg {String} string
		###

	generate: (lattice) ->
		###*
		 * @cfg {String} string
		 * The string of sequence data to use
		###
		string = @get('string')
		shape = lattice.shape()
		@sequences = ndarray([], lattice.shape())
		me = @

		###*
		 * @cfg {Boolean} lines
		 * If true, the string will be split on newline characters (`"\n"`);
		 * each line will be used as the sequence for one helix.
		###

		# if structure should be split into lines, one per helix
		if @get('lines')
			lines = string.split("\n")

			# keep track of line, col
			pos = [0,0]
			consume = (a, b, c, pos) ->
				[i,j] = pos
				line = lines[i]

				len = lattice.length(a,b,c)
				seq = line.substr(j, len)
				me.sequences.set(a,b,c, seq)

				j += len
				i = if j >= line.length then i+1 else i
				[i,j]

		# otherwise if it's just one long string
		else
			string = string.split("\n").join("")
			# keep track of character in string
			pos = 0
			consume = (a, b, c, pos) ->
				len = lattice.length(a,b,c)
				seq = string.substr(pos, len)
				me.sequences.set(a,b,c, seq)
				pos + len

		# multiple orderings are possible
		vertical = () ->
			# for each col
			for a in [0...shape[0]]
				# for each row
				for b in [0...shape[1]]
					for c in [0...shape[2]]
						pos = consume(a,b,c,pos)

		horizontal = () ->
			# for each row
			for b in [0...shape[1]]
				# for each col
				for a in [0...shape[0]]
					for c in [0...shape[2]]
						pos = consume(a,b,c,pos)

		ribbon = () ->
			# for each row
			for b in [0...shape[1]]
				switch b % 2
					# on even rows, go left to right
					when 0 then for a in [0...shape[1]]
						(pos = consume(a,b,c,pos)) for c in [0...shape[2]]

					# on odd rows, go right to left
					when 1 then for a in [shape[1]...0] by -1
						(pos = consume(a,b,c,pos)) for c in [0...shape[2]]

		###*
		 * @cfg {"vertical"/"horizontal"/"ribbon"} order
		 * Determines the order in which sequences are consumed:
		 *
		 * - "vertical": sequences are consumed per column, starting
		 *    with the top helix in the first column, moving down, then right.
		 * - "horizontal": sequences are consumed per row, starting
		 *    with the leftmost helix in the first row, moving right then down.
		 * - "ribbon": sequences are consumed in caDNAno order: left to right
		 *    for the first row, then right to left for the second, and so on.
		###
		switch @get('order')
			when 'vertical' then vertical()
			when 'horizontal' then horizontal()
			when 'ribbon' then ribbon()
			else horizontal()

		@markGenerate()

###*
 * @class C3D.models.ss.RandomSequenceSet
 * Represents a set of sequences generated using a seeded pseudorandom
 * number generator (a Mersenne Twister).
###
class C3D.models.ss.RandomSequenceSet extends C3D.models.SequenceSet
	_class: 'C3D.models.ss.RandomSequenceSet'
	@_name: 'Randomly'
	ssType: 'random'
	description: """
	Generate (seeded) random sequences for the structure.
	"""
	priority: 0
	constructor: (config) ->
		config ?= {}
		config.seed ?= 0
		super config
		###*
		 * @cfg {Number} seed
		 * Seed to use for the PRNG; provide the same seed and same lattice,
		 * and you'll get the same sequences.
		###

	generate: (lattice) ->
		ch = new Chance(@get('seed'))
		@generator = (a, b, c, len) ->
			ch.string({length: len, pool: 'ATCG'})
		super lattice

class C3D.models.ss.ExcelSequenceSet extends C3D.models.SequenceSet
	_class: 'C3D.models.ss.ExcelSequenceSet'
	@_name: 'From existing strands'
	ssType: 'excel'
	description: """
	Load sequences for individual strands in the structure from a spreadsheet.
	"""

	constructor: () ->
		super arguments...

		@headerRows = @headerRows ? 1
		@columns = []
		@sheetLabels = {}
		@sheet = {}
		@ignoreMissingStrands = true

	generate: (lattice, canvas) ->
		@canvas = canvas 

		# build sequence map
		@sequences = ndarray([], lattice.shape())

		# build map from caDNAno positions to lattice positions
		# @map = vox.caDNAnoLatticeMap(lattice)
		@map = @buildCaDNAnoMap(lattice, @canvas.ctrls.SST.strands)

		# routing column is used to locate strand
		routingCol = _.find @columns, (col) -> col.dest is 'routing'
		if not routingCol
			throw new Error "Must specify a 'routing' column to map sequences to strands."
		routingCol = routingCol.index

		wb = @getWorkbook()
		if not wb? 
			throw new Error "Must load a workbook"

		# for each sheet
		for sheet in @sheets
			data = @data[sheet]

			# for each row
			for index in [@headerRows...data.length]
				row = data[index]

				# populate strand with data from columns
				str = {}
				for col in @columns 
					prop = col.dest
					val = row[col.index] ? ''
					switch prop 
						# when 'routing' then continue
						# when 'sequence'
						# 	str['sequence']
							# @fromStrand lattice, strand, val
						when '' then continue
						when 'name'
							plane = @guessPlane val
							str['plane'] = plane
							str['name'] = val
						else
							str[prop] = val

				# populate with data from sheet names
				if @sheetLabels.dest
					str[@sheetLabels.dest] = sheet

				# locate strand from routing column
				if not str.routing
					if @ignoreMissingStrands then continue
					else 
						throw new Error "Missing routing on row #{index} of sheet #{sheet}"

				# grab routing to locate strand, but don't clobber routing on existing strand
				routing = str.routing
				delete str.routing
				strand = @findStrand routing

				# depending on settings, ignore this or complain
				if not strand? 
					if @ignoreMissingStrands then continue
					else
						throw new Error "Couldn't find strand from routing '#{routing}'."
				
				# update sequence grid, but don't save sequence to strand
				if str.sequence
					@fromStrand lattice, strand, str.sequence
					delete str.sequence

				strand.set str

		@markGenerate()

	buildCaDNAnoMap: (lattice, strands) ->
		map = {}
		for strand in strands.models
			cno = strand.get 'cadnano'
			if cno? then map[cno.toString()] = strand
		map

	findStrand: (routing) ->
		routing = @parseRouting routing
		if routing.length is 4
			@getStrand routing
		else if routing.length is 2
			@getCaDNAnoStrand routing

	getCaDNAnoStrand: (routing) -> @map[routing]

	getStrand: (latticePosition) ->
		s1 = @canvas.ctrls.SST.getStrandAt latticePosition..., 1
		s2 = @canvas.ctrls.SST.getStrandAt latticePosition..., -1

		if s1? and s2?
			if s2[1] < s1[1] then s2[0]
			else s1[0]
		else if s1? then s1[0]
		else if s2? then s2[0]
		else null

	getLatticePosition: (routing) ->
		pos = @parseRouting(routing)
		if pos.length is 2
			latticePosition = @map.get pos[0], pos[1]
		else if pos.length is 4
			latticePosition = pos
		else throw new Error "Unable to parse routing '#{routing}'. Must specify either [helix number, base index] or [helix X, helix Y, voxel, base]"
		latticePosition

	parseRouting: (routing) ->
		match = routing.match /^\[?\s*([\d\s,]+)\s*\]?/
		if match? then (parseInt(r.trim()) for r in match[1].split(','))
		else throw new Error "Unable to parse routing '#{routing}'. Must specify either [helix number, base index] or [helix X, helix Y, voxel, base]"

	sheetToArray: (sheet) ->
		`function safe_decode_range(range) {
			var o = {s:{c:0,r:0},e:{c:0,r:0}};
			var idx = 0, i = 0, cc = 0;
			var len = range.length;
			for(idx = 0; i < len; ++i) {
				if((cc=range.charCodeAt(i)-64) < 1 || cc > 26) break;
				idx = 26*idx + cc;
			}
			o.s.c = --idx;

			for(idx = 0; i < len; ++i) {
				if((cc=range.charCodeAt(i)-48) < 0 || cc > 9) break;
				idx = 10*idx + cc;
			}
			o.s.r = --idx;

			if(i === len || range.charCodeAt(++i) === 58) { o.e.c=o.s.c; o.e.r=o.s.r; return o; }

			for(idx = 0; i != len; ++i) {
				if((cc=range.charCodeAt(i)-64) < 1 || cc > 26) break;
				idx = 26*idx + cc;
			}
			o.e.c = --idx;

			for(idx = 0; i != len; ++i) {
				if((cc=range.charCodeAt(i)-48) < 0 || cc > 9) break;
				idx = 10*idx + cc;
			}
			o.e.r = --idx;
			return o;
		}`

		out = []
		o = (if not opts? then {} else opts)
		return ""  if not sheet? or not sheet["!ref"]?
		r = safe_decode_range(sheet["!ref"])
		rr = ""
		cols = []
		val = undefined
		R = 0
		C = 0
		C = r.s.c
		while C <= r.e.c
			cols[C] = XLSX.utils.encode_col(C)
			++C
		R = r.s.r
		while R <= r.e.r
			row = []
			rr = XLSX.utils.encode_row(R)
			C = r.s.c
			while C <= r.e.c
				val = sheet[cols[C] + rr]
				txt = (if val isnt `undefined` then "" + XLSX.utils.format_cell(val) else "")
				row.push txt
				++C
			out.push row
			++R
		return out


	fromStrand: (lattice, strand, sequence) ->
		routing = strand.get 'routing'
		for r, i in routing
			seq = @sequences.get r.pos[0..2]...

			if not seq? 
				seq = Array(lattice.length(r.pos[0..2]...) + 1).join('_')

			if r.pos[3] > -1
				# seq[r.pos[3]] = sequence[i] ? '_'
				index = r.pos[3]
				base = sequence[i] ? '_'
				if r.dir is -1 then base = C3D.models.SequenceSet.complements[base] ? '?'
				seq = seq.substr(0,index) + base + seq.substr(index+1)

			@sequences.set r.pos[0..2]..., seq

	getWorkbook: () ->
		@workbook

	setWorkbook: (data, format, opts) ->
		@workbook = switch format
			when 'xlsx' then XLSX.read data, opts
			when 'xls' then XLS.read data, opts
			when 'csv','txt' then harb.read data, opts

		@headerRows = @headerRows ? 1
		# iterate over workbook sheets
		wb = @workbook
		if wb?
			@data = {}
			for sheetName in wb.SheetNames
				sheet = wb.Sheets[sheetName]
				@data[sheetName] = @sheetToArray sheet

			@columns = @guessColumns() 
			@sheets = _.clone wb.SheetNames

	guessColumns: () ->
		wb = @getWorkbook()
		if wb? and @data?
			firstSheetName = _.first wb.SheetNames
			firstSheet = @data[firstSheetName]
			if firstSheet?
				firstRow = firstSheet[@headerRows]
				if firstRow?
					return ({ dest: @guessColumnProperty(t), index: i, col: XLSX.utils.encode_col(i) } for t, i in firstRow)
		return []

	guessColumnProperty: (value) -> switch 
		when value.match /^\[(\d+),\s*(\d+)\]$/
			'routing'
		when value.match /^[ATCGN]+$/i
			'sequence'
		when value.match /^[A-Z]+\d+$/
			'well'
		else 'name'

	guessDir: (latticePosition, lattice) ->
		len = lattice.length latticePosition[0..2]...
		if latticePosition[3] > len/2 then -1 else +1

	guessPlane: (value) ->
		value = value.trim()
		first = value[0]?.toUpperCase() ? ''
		last = value[value.length-1]?.toUpperCase() ? ''
		if first in ['X', 'Y'] then first
		else if last in ['X', 'Y'] then last
		else ''

	getPreviewData: () ->
		wb = @getWorkbook()
		firstSheetName = _.first wb.SheetNames
		firstSheet = @data[firstSheetName]
		if firstSheet?
			last = Math.min(firstSheet.length, 10)
			return firstSheet[@headerRows...last]
		else return []	

	getPreviewSheets: () ->
		wb = @getWorkbook()
		last = Math.min(wb.SheetNames.length, 5)
		wb.SheetNames[0...last]


# -----------------------------------------------------------------------------


###*
 * @class C3D.models.ts
 * @singleton
 * @static
 *
 * Classes in this namespace represent configurations for various translation
 * schemes that convert voxels into DNA strands.
###
C3D.models.ts = {}

###*
 * @class C3D.models.TranslationScheme
 * Represents a general translation scheme. 
###
class C3D.models.TranslationScheme extends C3D.models.Model
	_class: 'C3D.models.TranslationScheme'
	isTranslationScheme: true

	constructor: (config) ->
		config ?= {}

		###*
		 * @cfg {Boolean} active
		 * Indicates whether this translation scheme should be used by
		 * {@link C3D.ctrls.SST#compile}; this property is managed by the
		 * {@link C3D.ctrls.SST SST controller}.
		###
		config.active = config.active ? (!!!@isCustomTranslationScheme)
		super config

		###*
		 * @cfg {String} name
		 * Gives the name of this translation scheme; will be populated
		 * automatically by the #_name member.
		###
		@set 'name', @constructor._name

		###*
		 * @abstract
		 * @private
		 * @static {String} _name
		 * Default name given to instances of this translation scheme
		###

	###*
	 * Compiles a set of voxels using this translation scheme. By default, calls
	 * vox#compile using the defined #generator function, but subclasses may
	 * override.
	 *
	 * @param  {ndarray} voxels ndarray of C3D.model.Voxel objects
	 * @param  {vox.lattice.Lattice} lattice Lattice configuration
	 * @return {C3D.models.SST[]} Array of strands to implement the passed shape
	###
	compile: (voxels, lattice, options) ->
		strands = vox.compile(@generator, voxels, lattice, options)
		strandModels = (new C3D.models.SST(s) for s in strands)

	###*
	 * Factory function that generates the compiler for vox#compile.
	 * @param {ndarray} voxels 
	 * @param {vox.lattice.Lattice} lattice
	 * @return {vox.compilers.Compiler} compiler
	###
	generator: () ->

	###*
	 * Returns an array of subclasses from {@link C3D.models.ts} that are
	 * compatible with the given lattice. Subclasses should override the
	 * static method #isCompatible to provide an arbitrary predicate which may
	 * determine which lattice are compatible
	 * @param  {vox.lattice.Lattice} lattice Lattice object
	 * @return {C3D.models.TranslationScheme} List of compatible translation schemes
	###
	@getCompatible: (lattice) ->
		ts for name, ts of C3D.models.ts when ts.isCompatible(lattice)

	###*
	 * @method  isCompatible
	 * @static
	 * @abstract
	 *
	 * Determine whether this translation scheme is compatible with a given
	 * lattice object, according to an arbitrary predicate. Subclasses
	 * should override this method to be returned by #getCompatible.
	 *
	 * @param  {vox.lattice.Lattice} lattice Lattice object
	 * @return {Boolean} `true` if compatible, else `false`.
	###

	###*
	 * Checks if all domains in a lattice have a given length
	 * @param  {vox.lattice.Lattice} lattice
	 * @param  {Number} length Target length
	 * @return {Boolean}
	###
	@allDomainsEqual: (lattice, length) ->
		lens = _.flatten lattice.each((i, j, k) -> lattice.length(i,j,k))
		_.all lens, (x) -> x is length

	###*
	 * Checks if a lattice is 3-dimensional (`width > 1` and `height > 1` and `depth > 1`)
	 * @param  {vox.lattice.Lattice} lattice
	 * @return {Boolean}
	###
	@is3D: (lattice) ->
		lattice.width > 1 and lattice.height > 1 and lattice.depth > 1

	###*
	 * Checks if a lattice is 2-dimensional (`height == 1`)
	 * @param  {vox.lattice.Lattice} lattice
	 * @return {Boolean}
	###
	@is2D: (lattice) ->
		lattice.height is 1

###*
 * Represents a user-defined translation scheme. The #source property
 * gives a CoffeeScript function which serves as the translation scheme
 * generator.
###
class C3D.models.ts.Custom extends C3D.models.TranslationScheme
	_class: 'C3D.models.ts.Custom'
	@_name: "Custom",
	isCustomTranslationScheme: true
	constructor: (config) ->
		defaultScript = """
		(voxels, lattice, options) ->

			before : (strands) ->

			iterator: (i, j, k, strands) ->

			after : (strands) ->

		"""
		config = _.defaults (config ? {}), { source: defaultScript }
		super config
		@on 'change:source', @updateGenerator
		@updateGenerator

		###*
		 * @cfg {String} source
		 * Source code for the custom translation scheme; when this field
		 * changes, the code will be recompiled and the #generator will be 
		 * updated automatically.
		###

	###*
	 * @private
	 * Recompiles the #source code to build #generator
	###
	updateGenerator: () =>
		@generator = compile @get('source')

	@isCompatible: (lattice) -> true

###*
 * Represents the translation scheme presented in Ke et al., Science 2012
###
class C3D.models.ts.KeScience2012 extends C3D.models.TranslationScheme
	_class: 'C3D.models.ts.KeScience2012'
	@_name: "Ke et al., Science 2012 (3D SST, 8 nt domains)"

	generator: () ->
		vox.compilers.keScience2012 arguments...

	@isCompatible: (lattice) ->
		C3D.models.TranslationScheme.is3D(lattice) and
		C3D.models.TranslationScheme.allDomainsEqual lattice, 8

class C3D.models.ts.KeScience2012alt extends C3D.models.ts.KeScience2012
	_class: 'C3D.models.ts.KeScience2012alt'
	@_name: "Ke et al., Science 2012 (3D SST, 8 nt domains); alternating crossovers"

	generator: () -> vox.compilers.keScience2012alt arguments...

###*
 * Represents the translation scheme presented in Ong et al., Nature 2017
 * for 13 nt-domain 3D SSTs.
###
class C3D.models.ts.Ong13nt2014 extends C3D.models.TranslationScheme
	_class: 'C3D.models.ts.Ong13nt2014'
	@_name: "Ong et al., Nature 2017 (3D SST, 13 nt domains)"

	generator: () ->
		vox.compilers.ong13nt2014 arguments...

	@isCompatible: (lattice) ->
		C3D.models.TranslationScheme.is3D(lattice) and
		C3D.models.TranslationScheme.allDomainsEqual lattice, 13

class C3D.models.ts.Ong13nt2014alt extends C3D.models.ts.Ong13nt2014
	_class: 'C3D.models.ts.Ong13nt2014alt'
	@_name: "Ong et al., Nature 2017 (3D SST, 13 nt domains); alternating crossovers"

	generator: () -> vox.compilers.ong13nt2014alt arguments...

###*
 * Represents the translation scheme presented in Ke et al., Science 2012,
 * Fig. 4 for SSTs on a Hexagonal lattice
###
class C3D.models.ts.KeScience2012hex extends C3D.models.TranslationScheme
	_class: 'C3D.models.ts.KeScience2012hex'
	@_name: "Ke et al., Science 2012 (3D SST, 9 nt domains, hexagonal lattice)"

	generator: () ->
		vox.compilers.keScience2012hex arguments...

	@isCompatible: (lattice) ->
		C3D.models.TranslationScheme.is3D(lattice) and
		lattice.isHexagonal

###*
 * Represents the translation scheme presented in Ke et al., Science 2012,
 * Fig. 4 for SSTs on a Honeycomb lattice
###
class C3D.models.ts.KeScience2012honey extends C3D.models.TranslationScheme
	_class: 'C3D.models.ts.KeScience2012honey'
	@_name: "Ke et al., Science 2012 (3D SST, 9/12 nt domains, honeycomb lattice)"

	generator: () ->
		vox.compilers.keScience2012honey arguments...

	@isCompatible: (lattice) ->
		C3D.models.TranslationScheme.is3D(lattice) and
		lattice.isHoneycomb