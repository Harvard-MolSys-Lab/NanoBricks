# Developing Tools for NanoBricks

This guide describes how to implement different user-facing {@link C3D.tools.Tool Tools}. A Tool is basically a single "mode" of user interaction. For instance, there is a {@link C3D.tools.Pointer voxel painter tool}, a {@link C3D.tools.Rectangle rectangle/cuboid drawing tool}, and so on; users can switch between tools using the toolbar.

Two steps are needed to build and enable a new tool:

1. Implement a {@link C3D.tools.Tool} subclass: This defines the class which will implement the tool's functionality
2. Register the tool with {@link C3D.Canvas3D}: This causes instances of C3D.Canvas3D to instantiate an instance of the tool class from step (1). This will also automatically add the tool to the toolbar.

## Implementing a tool class

This is pretty easy; just create a class (within the {@link C3D.tools} namespace) which extends {@link C3D.tools.Tool}:

```coffeescript
class C3D.tools.MyNewTool extends C3D.tools.Tool
	instructions: "Click to add a voxel"

	activate: () ->
		alert "I'm alive!"

	deactivate: () -> 
		alert "That's all for now!"

	mouseup: () ->
		[intersect, position] = @canvas.getIntersectingPoint()
		if intersect?
			latticePosition = @canvas.lattice.pointToLattice(
				position.x, position.y, position.z)
			@canvas.ctrls.Voxels.addAt latticePosition...
```

- Provide a set of instructions to the user in the {@link C3D.tools.Tool#instructions instructions} property. You can also update this property to dynamically change the instructions
- Override {@link C3D.tools.Tool#activate activate} and {@link C3D.tools.Tool#deactivate deactivate} to provide handlers for when the tool is activated or deactivated
- Override `mouseup`, `mousedown`, `mousemove`, etc. to handle mouse events.  

You may also want to:

- Add a {@link C3D.tools.Tool#name name} to your tool (that will show up in tooltips and above the instructions box)
- Add a [Font Awesome icon class](http://fortawesome.github.io/Font-Awesome/icons/) with the {@link C3D.tools.Tool#iconCls iconCls} property.

You can look at the documentation for C3D.tools.Tool for details on the available methods to override.

## Registering the tool

To ensure that canvases instantiate the tool by default, you'll need to update the {@link C3D.Canvas3D#constructor constructor of C3D.Canvas3D}, overriding the default value of the {@link C3D.Canvas3D#cfg-tools tools config} to also include the name of your tool:

```coffeescript
		_.extend @, {

			###*
			 * @cfg {String[]} tools
			 * List of names of C3D.tools.Tool subclasses to be added to this canvas
			###
			tools: ['Pointer', 'Rectangle', 'Orbit', 'Strand', 'StrandEraser', 'MyNewTool']

			# ...
		}
```

(Note that the string added must exactly match the name of the tool, within the C3D.tools namespace).
