# NanoBricks Data Model

This guide describes how NanoBricks stores data about the structure being designed, how the user interface classes make changes to that data, and how those changes are propogated throughout the user interface. 

NanoBricks is built around a relaxed Model, View, Controller (MVC) paradigm; in NanoBricks this has four parts:

## Models 

{@link C3D.models.Model Models} store data associated with the application; in general, each object on the {@link C3D.Canvas3D canvas}  (e.g. each voxel, each strand, each {@link C3D.models.SequenceSet sequence set}, etc.) is associated with a model. Models are stored in a {@link Backbone.Collection collection} called on the {@link C3D.Canvas3D canvas} called '{@link C3D.Canvas3D#data data}'.

Models have certain _attributes_ (distrinct from regular JavaScript _properties_) which fire {@link Backbone.Events events} when changed. This allows models report to the {@link C3D.Canvas3D canvas} (or any other object which is {@link Backbone.Events#on listening}) when their attributes change. These properties are accessed using the special {@link C3D.models.Model#get get} and {@link C3D.models.Model#set set} methods. 

A central rule of NanoBricks is that "the models are the central source of truth." This means that all other components---views, controllers, tools, etc. should respond automatically to changes in the models. This allows the user interface to consistently respond to changes to the data---regardless which component triggers the changes.

See the [strands guide](#!/guide/strands) for information on how strands specifically are modeled in NanoBricks.

## Views

{@link C3D.views.View Views} are responsible for drawing a visual representation of their associated models to the 3D canvas. Views can indicate what models they're interested in by defining a {@link C3D.views.View#match match} function. Whenever a model is added, removed, or changed, the {@link C3D.Canvas3D canvas} notifies any view(s) that {@link C3D.views.View#match match} the model by calling those views' {@link C3D.views.View#onModelAdd onModelAdd}, {@link C3D.views.View#onModelRemove onModelRemove}, or {@link C3D.views.View#onModelChange onModelChange} methods.

## Controllers

All models are stored in the {@link C3D.Canvas3D#data} collection; this is convenient because it allows undoing changes, serialization, etc. to be handled in a centralized fashion. However, a flat list of models is inconvenient for performing certain structured queries or changes to the models. For instance, asking whether there is a voxel at a particular location would be very inconvenient if one had to iterate over each model in {@link C3D.Canvas3D#data} and examine the model's {@link C3D.models.Voxel#latticePosition latticePosition}.

{@link C3D.ctrls.Controller Controllers} maintain structured caches of the models---for instance, {@link C3D.ctrls.Voxels voxels controller} maintains a cache of which voxel is at which lattice position, and the {@link C3D.ctrls.SST strand controller} keeps track of which strand/base is at which position in the lattice. 

Controllers are notified by the {@link C3D.Canvas3D} of changes to {@link C3D.ctrls.Controller#match matching} models in the same way as views---the canvas calls their {@link C3D.ctrls.Controller#onModelAdd onModelAdd}, {@link C3D.ctrls.Controller#onModelRemove onModelRemove}, or {@link C3D.ctrls.Controller#onModelChange onModelChange} methods as appropriate. 

Controllers can also make structured changes to the data---for instance, the {@link C3D.ctrls.Voxels voxel controller} implements the {@link C3D.ctrls.Voxels#selectTransform selectTransform} method which forms the basis of the Power Editing tool. Importantly, these types of methods will make direct changes to the models _without_ directly modifying the controllers' internal caches. Instead, the caches are only updated in response to changes in the models.

## Tools

Tools are different modes of user interaction that can make changes to the models. Generally tools will interact with the views to provide a user interface (e.g. drawing a proxy of a voxel representing the cursor, or fading a strand before deleting it), but all changes ultimately happen by modifying the models (either directly or using the controllers).

See the [tools guide](#!/guide/tools) for information on how to write custom tools.

## See also

* [Architecture](#!/guide/architecture-c3d) for an overview of MVC in the C3D module
* [Strands](#!/guide/strands) for an explanation of how strands specifically are modeled in NanoBricks.