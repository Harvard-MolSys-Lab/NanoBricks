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

_ = require 'underscore'
marked = require 'marked'
jade = require 'jade'

module.exports = (grunt) ->

	# Project configuration.
	grunt.initConfig({
		pkg: grunt.file.readJSON('package.json'),
		semver: require('semver')

		browserify:
			options:
				transform: ['coffeeify', 'jadeify', 'markdownify']
				# external: ['jquery','underscore','backbone','three']
				browserifyOptions: 
					noParse: ['node_modules/jquery/dist/jquery.js', 'node_modules/three/three.js', 'node_modules/underscore/underscore.js']

			# interactive, watches for touched files and rebuilds
			watch:
				options:
					watch: true
					keepAlive: true
					bundleOptions:
						debug: true
				files:
					'dist/index.js': ['lib/**/*.js', 'lib/**/*.coffee']
					# 'dist/index.js': ['lib/voxel-app.js']
			
			# non-interactive, does not watch
			dist: 
				files:
					'dist/index.js': ['lib/voxel-app.js']

		coffee:
			# concatenates our source files for parsing by JSDuck
			docs:
				files: 
					'dist/docs.temp.js': ['lib/**/*.coffee']
					# 'dist/docs.js': ['lib/**/*.coffee']

		copy:
			fonts:
				expand: true
				cwd: 'bower_components/fontawesome/fonts/'
				src: '**'
				dest: 'dist/fonts'
				flatten: true
				filter: 'isFile'

		concat: 
			docs: 
				files: 
					'dist/docs.js': ['dist/docs.temp.js', 'lib/**/*.js']

		# concat: 
		# 	js: 
		# 		options: 
		# 			separator: ';'
		# 		files:
		# 			'dist/build.js': ['dist/index.js','bower_components/bootstrap/dist/js/bootstrap.min.js' ]
		# 	css: 
		# 		files:
		# 			'dist/styles/build.css': [
		# 				'lib/css/styles.css',
		# 				'bower_components/bootstrap/dist/css/bootstrap.min.css',
		# 				'bower_components/fontawesome/css/font-awesome.min.css', 
		# 				'node_modules/backgrid/lib/backgrid.min.css'
		# 			]

		uglify:
			options:
				# ensure unicode characters are not encoded
				beautify: 
					"ascii_only": true
					beautify: false
				mangle: false
				sourceMap: false
				banner: """
				/*
					--------------------------------------------------------------------------
					NanoBricks

					(c) 2014 Molecular Systems Lab
					Wyss Institute for Biologically-Inspired Engineering
					Harvard University
					------------------------------------------------------------------------- 
				*/
				"""
			dist:
				files: 
					'dist/build.min.js': 'dist/index.js'

		"git-describe":
			dist:
				options:
					failOnError: true

		# bumps release version in git, package.json, bower.json
		bump:
			options:
				push: false
				updateConfigs: ['pkg']
				commit: true
				# commitFiles: ['package.json', 'bower.json']
				commitFiles: ['-a']

		# interactive prompt for bumping versions
		prompt:
			bump:
				options:
					questions: [
						{
							config: "bump.options.increment"
							type: "list"
							message: "Bump version from " + "<%= pkg.version %>".cyan + " to:"
							choices: [
								{
									value: "build"
									name: "Build:  ".yellow + "<%= pkg.version %>-?".yellow + " Unstable, betas, and release candidates."
								}
								{
									value: "patch"
									name: "Patch:  ".yellow + "<%= semver.inc(pkg.version, 'patch') %>".yellow + "   Backwards-compatible bug fixes."
								}
								{
									value: "minor"
									name: "Minor:  ".yellow + "<%= semver.inc(pkg.version, 'minor') %>".yellow + "   Add functionality in a backwards-compatible manner."
								}
								{
									value: "major"
									name: "Major:  ".yellow + "<%= semver.inc(pkg.version, 'major') %>".yellow + "   Incompatible API changes."
								}
								{
									value: "custom"
									name: "Custom: ?.?.?".yellow + "   Specify version..."
								}
							]
						}
						{
							config: "bump.options.version"
							type: "input"
							message: "What specific version would you like"
							when: (answers) ->
								answers["bump.increment"] is "custom"

							validate: (value) ->
								valid = semver.valid(value) and true
								valid or "Must be a valid semver, such as 1.2.3-rc1. See " + "http://semver.org/".blue.underline + " for more details."
						}
						{
							config: "bump.options.files"
							type: "checkbox"
							message: "What should get the new version:"
							choices: [
								{
									value: "package.json"
									name: "package.json" + ((if not grunt.file.isFile("package.json") then " file not found, will create one".grey else ""))
									checked: grunt.file.isFile("package.json")
								}
								{
									value: "bower.json"
									name: "bower.json" + ((if not grunt.file.isFile("bower.json") then " file not found, will create one".grey else ""))
									checked: grunt.file.isFile("bower.json")
								}
								{
									value: "git"
									name: "git tag"
									checked: grunt.file.isDir(".git")
								}
							]
						}
					]
					then: (results) ->
						if "git" in results['bump.options.files']
							i = results['bump.options.files'].indexOf 'git'
							results['bump.options.files'].splice i, 1
							grunt.config 'bump.options.files', results['bump.options.files']
							grunt.config 'bump.options.createTag', true
						else 
							grunt.config 'bump.options.createTag', false 

		useminPrepare:
			html: 'dev.html'
			options: 
				dest: 'dist'

		usemin:
			options: {}
			html: 'index.html'

		jsduck:
			docs:
				src: ['dist/docs.js']
				dest: 'docs'
				options:
					title: 'NanoBricks Documentation (v<%= pkg.version %>)'
			json: 
				src: ['dist/docs.js']
				dest: 'docs/json'
				options:
					export: 'full'
					tags: ['etc/internal_tag.rb']

			options: 
				guides: 'guides.json'
				# keep this list alphabetical please
				external: [
					'Backbone'
					'Backbone.Collection'
					# 'Backbone.Model'
					'Backbone.UndoManager'
					'Blob'
					'CodeMirror'
					'jQuery'
					# 'ndarray'
					'ndhash'
					'rivets.View'
					'THREE.Box3'
					'THREE.Camera'
					'THREE.Color'
					'THREE.CombinedCamera'
					'THREE.Face'
					'THREE.Line'
					'THREE.Geometry'
					'THREE.Object3D'
					'THREE.Material'
					'THREE.Matrix4'
					'THREE.Mesh'
					# 'THREE.Projector'
					'THREE.Renderer'
					'THREE.Scene'
					'THREE.Vector2'
					'THREE.Vector3'
					'THREE.Vector4'
				].join(",")

		less:
			dist:
				options:
					paths: ['bower_components/bootstrap/less']
				files: 
					'lib/css/styles.css': 'lib/less/styles.less'
	});

	# Load plugins.
	grunt.loadNpmTasks('grunt-usemin')
	grunt.loadNpmTasks('grunt-browserify')
	grunt.loadNpmTasks('grunt-contrib-copy')
	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-concat')
	grunt.loadNpmTasks('grunt-contrib-cssmin')
	grunt.loadNpmTasks('grunt-contrib-uglify')
	grunt.loadNpmTasks('grunt-contrib-less')
	grunt.loadNpmTasks('grunt-filerev')
	grunt.loadNpmTasks('grunt-git-describe')
	grunt.loadNpmTasks('grunt-bump')
	grunt.loadNpmTasks('grunt-prompt')
	grunt.loadNpmTasks('grunt-jsduck')


	# builds the documentation
	# grunt.registerTask('docs', ['jsduck:docs'])
	grunt.registerTask 'docs', ['coffee:docs', 'concat:docs', 'jsduck:docs', 'jsduck:json']
	grunt.registerTask 'docs:json', ['coffee:docs', 'jsduck:json']
	grunt.registerTask 'help', () ->
		# load topics list 
		topics = grunt.file.readJSON 'help/topics.json'
		console.log topics

		# load each topic
		help = []
		api = []

		fixLinks = (out, baseUrl) ->
			# #!/api/Class-member -> /api/Class.html#member
			out = out.replace(/#!\/api\/([\w.]+)-([\w\-]+)/g, baseUrl+'/api/$1.html#$2')
			# #!/api/Class -> /api/Class.html
			out = out.replace(/#!\/api\/([\w.]+)/g,baseUrl+'/api/$1.html')

			# href="docs:guide/tools" -> baseURL+"../../../docs/index.html#!/guide/tools"
			out = out.replace(/href=(["'])docs:([^."']*)\1/g, "href=$1"+baseUrl+"/../../../docs/index.html#!/$2$1 target=$1_blank$1")

			# href="topic" -> href="topic.html" 
			out = out.replace(/href=(["'])([^."']+)\1/g,'href=$1$2.html$1')

			out

		# for help topics, run markdown
		topicTemplate = jade.compileFile 'lib/ui3d/views/help-topic.jade'
		for topic in topics.help
			src = grunt.file.read('help/'+topic.id+'.md')
			topic.url = topic.id+'.html'
			topic.path = 'dist/help/html/'+topic.url
			out = topicTemplate { body: marked(src), title: topic.name }
			out = fixLinks out, '.'
			grunt.file.write topic.path, out
			help.push topic

		# for API topics, run jade
		apiTemplate = jade.compileFile 'lib/ui3d/views/help-api.jade'
		for topic in topics.api
			data = grunt.file.readJSON('docs/json/'+topic.id+'.json')

			# remove private members
			data.members = (member for member in data.members when (not member.private and not member.internal))

			# partition members
			data.members = _.groupBy data.members, (member) -> member.tagname
			data.members.property ?= {}
			data.members.method ?= {}
			data.members.cfg ?= {}
			data.extend = data.extends

			data.title = topic.name
			topic.url = 'api/'+topic.id+'.html'
			topic.path = 'dist/help/html/'+topic.url
			out = apiTemplate(data)
			out = fixLinks out, '..'
			grunt.file.write topic.path, out
			api.push topic

		# build index
		index = { api: api, help: help, baseUrl: '' }
		navTemplate = jade.compileFile 'lib/ui3d/views/help-nav.jade'
		grunt.file.write 'dist/help/html/nav.html', navTemplate( index )
		indexTemplate = jade.compileFile 'lib/ui3d/views/help-index.jade'
		grunt.file.write 'dist/help/html/index.html', indexTemplate( index )
		grunt.file.write 'dist/help/index.json', JSON.stringify(index)


	# builds files for a release, assuming `browserify:dist` has already run
	grunt.registerTask('build-usemin', [
		'useminPrepare',
		'copy:fonts'
		'concat:generated',
		'cssmin:generated',
		'uglify:generated',
		# 'filerev',
		'usemin'
	])

	# builds a release, including running browserify:dist
	grunt.registerTask('build', [
		# 'update-version'
		'browserify:dist'
		'build-usemin'
	])

	# Release bump warning text
	grunt.registerTask 'pre-bump', () ->
		grunt.log.write """

			Please read carefully.

			""".red + 
			"""

			You are about to generate a new release. Please make sure you
			have already:

				* Built a new version by running:

					grunt build

				* Merged the changes from your topic branch into the `dev` branch 
				  and tested.
				* Merged the changes from `dev` into `master` and tested:

				    git checkout master
				    git merge --no-ff dev

				* Checked that you have a clean working directory with `git status`.

			""".yellow +
			"""

			If you have not done this, please exit now by pressing Ctrl-C.
			
			""".red +
			"""
			
			You will be asked whether to increment to a patch, minor, or major 
			release version, and to choose whether to update the version in 
			package.json, bower.json, and/or to add a tag in git; please 
			update all of them.

			One more build will also be generated to update the version number in 
			dist/build.js, so that the right version number shows up in the UI. 
			All changes will be committed.

			After you select these options, the commit may take a few minutes; 
			be patient.
			""".yellow

	grunt.registerTask 'post-bump', () ->
		grunt.log.write """

			You have generated a new release, but you're not done yet! If you
			ran this command in the virtual machine, switch back to your host
			and run:

				git commit --amend --reset-author
				git log

			to ensure the commit is properly marked with your authorship
			(rather than the `vagrant` user). Check that everything is correct.
			Then run: 

				git push origin --all && git push origin --tags

			to push the commit and tag to GitHub. If something went wrong, 
			you can use: 

				git reset --hard HEAD~1

			to undo the automatic commit. 

			""".yellow

	# bumps the version in git tag, package.json, and bower.json
	grunt.registerTask 'bump-interactive', ['pre-bump', 'prompt:bump', 'bump', 'post-bump']
	grunt.registerTask 'bump-dummy', ['pre-bump', 'post-bump']
	
	# bumps the version in git tag, package.json, and bower.json, AND builds a new release		
	grunt.registerTask 'release-interactive', ['pre-bump', 'prompt:bump', 'bump::bump-only', 'build', 'bump::commit-only', 'post-bump']

	# Default task; runs browserify in watch mode
	grunt.registerTask('default', ['browserify:watch']);

