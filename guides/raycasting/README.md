# Raycasting and Object Picking

This tutorial will explain how to use NanoBricks APIs to "pick" objects using the mouse; picking is the process of figuring out which object (or objects) that the user's mouse is hovering over. If you're looking for lower level access to the 2D mouse coordinates, see the Mouse and Keyboard Input guide.

## Background: Projection and Unprojection

To render a 3D scene on a 2D screen, a mathematical technique called _projection_ is used. Briefly, any 3D position in space (represented as a 3-element vector) can be mapped to a 2D position (a 2-element vector) by multiplying that 3D vector by a _projection matrix_. This projection matrix is ultimately what's provided by the {@link C3D.Canvas3D#camera camera} in the 3D rendering pipeline; perspective cameras and orthographic cameras therefore have different types of projection matrices. Both types of camera convert 3D points to 2D points for the sake of displaying them on the screen. 

The inverse technique is _unprojection_, and involves multiplying a 2D point by the inverse of the projection matrix, giving you a position in 3D space. In the case of coordinates on the screen, this is a well-defined location since the screen represents a particular plane in world space.

However, unprojecting (from mouse position to world coordinates) is not enough to pick out objects in the scene, since the objects (by definition) visible in the scene are in front of the plane of the screen. To select these objects, we use _raycasting_. A "picking ray" is cast from the camera position through the mouse position on the screen; any objects that the ray hits are collected and returned. In this way we can figure out all the objects that the user is hovering over.

More details: [Object picking tutorial](http://soledadpenades.com/articles/three-js-tutorials/object-picking/); [Udacity course video](https://www.udacity.com/course/viewer#!/c-cs291/l-124106599/m-175393398)

## Picking Voxels

To pick voxels, use the {@link C3D.views.Voxels#getIntersection} method; this gives you an array of `[intersection, point]` pairs, where `intersection` has data about the intersected object, face, etc. and `point` gives a 3D position of the intersection, in world space coordinates. When selecting voxels, you generally want to convert world space coordinates to lattice coordinates (e.g. using {@link vox.lattice.Lattice#pointToLattice}), so a point _right_ on the surface of a voxel is not that helpful; instead, two other modes are available:

- In `extruded` mode (the default), the returned point of intersection is moved away from the surface by one unit (in the direction of the negative face normal); this lets you e.g. place the cursor on the surface of the voxel structure:

		[intersect, point] = @canvas.views.Voxels.getIntersection()

- In `burrow` mode, the returned point of intersesction is moved past the surface by one unit, into the interior of the intersected structure (in the direction of the face normal).

		[intersect, point] = @canvas.views.Voxels.getIntersection { burrow: true }

- Finally, if you really just want the point on the surface, you can pass `extrude: false`:

		[intersect, point] = @canvas.views.Voxels.getIntersection { extrude: false }

	Note that this point may give unexpected results with {@link vox.lattice.Lattice#pointToLattice}.

Note that in any of the modes, the other values are available as members of the `intersect` object:

	[intersect, point] = @canvas.views.Voxels.getIntersection()
	intersect.burrowed
	intersect.extruded
	intersect.point


## Picking Strands

To pick strands, use the {@link C3D.views.SST#getIntersection} method. Since the intersected objects are lines, this method does not offer the same burrowing/extrusion options and always returns result points with `{extrude: false}`. Further, with this method the view will give you the intersected {@link C3D.models.SST strand model} and the index of the intersected {@link vox.dna.Base base}, in addition to the position:

	[strand, index, point] = @canvas.views.SST.getIntersection()

	# to get the actual base object
	base = strand.getBase index


## Picking arbitrary objects

If you want to pick some other kind of object, or if you want multiple depth-sorted results, you can use the various lower-level raycasting methods: {@link C3D.Canvas3D#getIntersectionPoints}, {@link C3D.Canvas3D#getIntersectingPoint}, and {@link C3D.Canvas3D#getIntersecting}.
