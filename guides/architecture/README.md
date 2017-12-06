# Architecture

This document describes the architecture of the NanoBricks software. For information on building and testing the software, as well as principles for source control, see `README.md` in the project root. 

## Overview

NanoBricks is arranged into several modules, in an attempt to decouple various parts of the interface. This decoupling is not complete, partly because some coupling of components is inevitable, and partly because of laziness. However, the following principles guide the development of the project's architecture:

- Reusability
- Modularity
- Extensibility

NanoBricks mostly uses the [CommonJS module standard](http://wiki.commonjs.org/wiki/Modules/1.1) to organize code; all key code is in CommonJS modules, and most shared dependencies are loaded as CommonJS modules. Some third party libraries are not loaded in this way, because life is complicated (especially in the browser), and not every module we need has a CommonJS version. Oh well. `browserify` handles transforming the `require` calls in our code to stuff that works in the browser. This architecture was chosen in hopes of making it possible to run the whole project in a headless mode if necessary in the future, but we haven't gotten there yet.

Be warned though, not all code plays nicely with CommonJS, so some packages we just have to include using `<script>` tags. These packages are managed by `bower`, rather than `npm` and `browserify`. This is described in more detail in the `README`.

### Core modules

There are three core modules in the NanoBricks software:
	
-	`vox` (`lib/vox/`): contains core routines for manipulating voxels, lattices, and strands. Does not define any user interface.
-	`C3D` (`lib/c3d/`): defines and handles user interaction with the 3D canvas interface. Loads and manages the central data models. 
-	`UI3D` (`lib/ui3d/`): handles buttons, toolbars, windows, etc.---the user interface "chrome" on top of the 3D canvas.

`vox` is a peer dependency of both `C3D` and `UI3D`, while `C3D` is a dependency of `UI3D`. That is, both `UI3D` and `C3D` know about and use methods from the `vox` library, and `UI3D` can instantiate and manage instances of `C3D` classes, but `C3D` has no direct knowledge of `UI3D`, and `C3D` has no knowledge of `UI3D`. 

The entry point of the application is a small module called `voxel-app` (`voxel-app.js`), which loads an instantiates an instance of `UI3D.Canvas3D`. `UI3D.Canvas3D` instantiates various `UI3D` classes and in turn loads and instantiates a `C3D.Canvas3D`. The instance of `C3D.Canvas3D` loads and sets up all the other `C3D` and `vox` classes.

### Dependency management and builds

As alluded to before, NanoBricks uses two package managers (`npm` and `bower`), and two build engines (`browserify` and `usemin`). The basic reason for this is that CommonJS is preferable for loading modules (due to its simplicity and mostly-portable nature), and this is the only real way to load modules in [Node](http://nodejs.org/); for these modules, we manage dependencies using [`npm`](https://www.npmjs.org/); dependencies are listed in [`package.json`](https://www.npmjs.org/doc/files/package.json.html), and dependency modules can be `require`d directly from our code. [`browserify`](http://browserify.org/) parses these `require` statements and includes the relevant modules into a big bundle. 

However, many packages written for the browser are either not written using CommonJS, or include resources other than Javascript (e.g. CSS files). For those packages, we use [`bower`](http://bower.io/) to manage dependencies; these dependencies are listed in [`bower.json`](http://bower.io/docs/creating-packages/#bowerjson), and dependency modules must be manually added to `dev.html` using `<script>` tags (for Javascript) and `<link>` tags (for CSS). When it's time to build a release, [`usemin`](https://github.com/yeoman/grunt-usemin) will chew through `dev.html` and generate individual compressed `dist/build.js` and `dist/styles/build.css` files that get included by `index.html`. 

All of the stuff needed to do these builds is automated by `grunt` commands, which are described in the `README`.

### Key libraries

Important libraries that NanoBricks code uses: 

-	[Underscore](http://underscorejs.org/): utility functions for Javascript. 
	-	[`underscore-contrib`](https://github.com/documentcloud/underscore-contrib): contains even more useful functions.
-	[jQuery](http://jquery.com/): functions for manipulating the DOM.
-	[Backbone](http://backbonejs.org/): functions for managing data models.
-	[Three.js](http://threejs.org/docs/): library for 3D scene management and rendering with WebGL.
-	[ndarray](https://github.com/mikolalysenko/ndarray): library for storing multidimensional arrays. 
	-	[`ndarray-hash`](https://github.com/mikolalysenko/ndarray-hash): provides a hash table which looks like an ndarray; used for creating large sparse arrays. 
-	[Rivets.js](http://rivetsjs.com/): library for 2-way data binding to the DOM.
-	[Keypress](http://dmauro.github.io/Keypress/) handles the keyboard input, though all keyboard handling should be done through the {@link C3D.Canvas3D#registerKey} and {@link C3D.tools.Tool#registerKey} APIs.
-	[Bootstrap](http://getbootstrap.com/): mostly a CSS library, but also has some jQuery plugins; used by UI3D for the user interface elements.
	-	[Bootstrap Dropdowns Enhancement](https://github.com/behigh/bootstrap_dropdowns_enhancement): lets dropdown menus act like checkboxes and radio buttons.
	-	[FontAwesome](fortawesome.github.io/Font-Awesome/): font-based icon library
-	[CodeMirror](http://codemirror.net/): in-browser code editor; used for PowerEdit and similar functionality.

Important modules that we use for development:

-	[CoffeeScript](http://coffeescript.org/): language which compiles to Javascript, but adds many helpful syntactic features. 
-	[Jade](http://jade-lang.com/): simple templating language for generating HTML. Generally we just use this for generating static HTML, and we leave the dynamic data binding to Rivets.
-	[Browserify](http://browserify.org/): parses our CommonJS code and merges in any modules that we `require`, building  a single file that can be loaded in the browser.
	-	[Coffeify](https://github.com/jnordberg/coffeeify): Lets us `require` Coffeescript files 
	-	[Jadeify](https://github.com/domenic/jadeify): Lets us directly `require` Jade templates (returns the template as a function)
-	[Grunt](http://gruntjs.com/): task runner that manages building the app, documentation, etc.
-	[Less](http://lesscss.org/): CSS preprocessor which adds variables, mixins, etc.
-	[Usemin](https://github.com/yeoman/grunt-usemin): combines our Javascript files with those that don't use CommonJS (and thus can't be browserified), as well as our CSS files with those from various libraries; bundles each up together into a `build.js` and `build.css` file.
-	[Mocha](http://visionmedia.github.io/mocha/): unit testing framework.

### Directory structure

All modules are contained in files or subdirectories within `lib/`. Mostly these are CoffeeScript or Javascript files, but the `lib/views/` subdirectory contains Jade views, while the `lib/css` and `lib/less` directories contain styles. 


## `vox`

`vox` contains shared utilities for working with voxels, generally in three categories:

-	Lattices: objects with functions for mapping voxel coordinates to 3D space
-	Translation schemes (also referred to as "compilers"): routines for converting a set of voxels to a set of strands
-	Utility functions: functions for generating and manipulating base, domain, and strand objects. 

Bases, domains, and strands are generally pseudo-classes, in that they aren't actual Javascript classes, but are defined implicitly as interfaces. See their documentation in the {@link vox} namespace for details.

## `C3D`

`C3D` is built around a relaxed Model, View, Controller (MVC) paradigm. Instances of the central class `C3D.Canvas3D` (canvases) are responsible for instantiating four types of objects:

-	Models (subclasses of `C3D.models.Model`): objects that store data associated with the application
-	Views (subclasses of `C3D.views.View`): objects which render presentational representations of the models to the 3D canvas
-	Controllers (subclasses of `C3D.ctrls.Controller`): objects which manage and make changes to the models
-	Tools (subclasses of `C3D.tools.Tool`): objects which manage modes of user interaction. Generally one tool is active at a time, and that tool recieves mouse and keyboard input from the canvas.

In addition, canvases are responsible for setting up the 3D scene, rendered and several common elements (lights, a grid, a camera, etc.). 

The canvas manages all data models in a single `Backbone.Collection`, and notifies the views and controllers of any models that are added, removed, or changed. Views and Controllers each define a `match` method which accepts an object and determines whether the view or controller should be notified of changes to the object. This architecture allows one view (or controller) to manage many objects of the same (or several related) type.

Our architecture is different from standard MVC in a few key ways:

-	Rather than communicating with controllers, views directly watch for changes to the models. Views are intended to be entirely passive, only responding to changes to models that they hear about from the canvas. 
-	Controllers make structured changes to the models, but should also respond to changes that may originate from elsewhere (for instance, from a `UI3D` class). Generally the `UI3D` classes will interact with the controller rather than the model directly, but this is not a strict requirement. 
-	Tools interact with both Controllers and Views, and therefore act like the typical "user" or "consumer" in a standard MVC paradigm. Tools _are_ allowed to make changes directly to the model, but in most cases they will want to make those changes via a controller.

In practice `C3D.Canvas3D` is generally a singleton, but it is designed so that it should be possible to instantiate multiple canvases on a single page (or in a single CommonJS environment).

See [the data model guide](#!/guide/data) for details on how the MVC paradigm works in NanoBricks.

## `UI3D`

`UI3D` provides the user interface "chrome" on top of the 3D canvas rendered by `C3D.Canvas3D`. `UI3D` classes are generally interface elements (mostly dialog boxes) that handle a particular interaction with the canvas. Each of these classes usually has an associated Jade template in `lib/views/`. 
