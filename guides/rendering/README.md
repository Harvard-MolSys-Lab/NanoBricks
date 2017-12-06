# Efficient Rendering in NanoBricks

This guide describes steps taken in NanoBricks to efficiently render hundreds of thousands of voxels and strands using JavaScript and WebGL. 

## Background

NanoBricks relies on Three.js to provide an abstraction over the underlying WebGL APIs. Most/all code you write will use Three.js, rather than accessing WebGL APIs directly, but it's important to understand how this code relates to the lower-level APIs in order to understand where bottlenecks occur and how to write performant code.

### The WebGL Rendering Pipeline

[WebGL](https://www.khronos.org/webgl/) is an API that lets you do calculations using the GPU for graphics. These calculations are performed by small programs called **shaders**,  written in a special language (called **GLSL**). The APIs provided by WebGL are derived from and related to the [OpenGL ES](https://www.khronos.org/opengles/) standard, so you may see references to documentation for OpenGL or OpenGL ES when reading about WebGL 

At a high level, the goal is to transform some arrays of input data (called **buffers**) into a buffer corresponding to pixels on the screen. The entire process that does this is the **WebGL Rendering Pipeline**, and it occurs in several steps:

1. Data in buffers is collected and sent to the GPU. This data comes in two forms: **attribute buffers** contain data _per vertex unit_---for instance, vertex positions (in 3D space), vertex normal vectors, vertex colors, etc. might be stored and passed to the GPU as attributes. **Uniforms** are variables that contain data that are the same for all vertices---for instance, lighting information, a transformation matrix for the current camera, a clock, etc. may all be passed as uniforms. 
2. The JavaScript program makes some number of **draw calls**---calls to the functions [glDrawElements](https://www.khronos.org/opengles/sdk/docs/man/xhtml/glDrawElements.xml) and/or [glDrawArrays](https://www.khronos.org/opengles/sdk/docs/man/xhtml/glDrawArrays.xml)---each draw call requests that a certain pair of shaders (the vertex shader and the fragment shader, see below) be loaded, compiled (if necessary), and run on the GPU with some set of attributes and uniforms.  
3. For each draw call, the following happens: 
    1. a **vertex shader** runs, transforming each attribute row into zero or one vertex positions in 2D space. The vertex shader recieves the uniforms and any attribute values for the particular vertex unit, and must produce a vertex position (set the `gl_Position` variable) as output, else [discard](https://www.opengl.org/sdk/docs/tutorials/ClockworkCoders/discard.php) the vertex. Optionally, the vertex shader may set some number of **varying** variables---these are variables which vary continuously across the screen, and whose values will be made available to the fragment shader (see below)
    2. The output of the vertex shader is **rasterized**, producing an array of pixels on the screen; each pixel recieves a value for each `varying`, interpolated from surrounding vertices 
    3. The **fragment shader** runs once for each pixel on the screen, consuming the `varying`s and generating color data for that pixel, as well as depth information.
4. Finally, the output from all fragment shaders is assembled into the **frame buffer** (using the specified blending mode); the resulting frame buffer is displayed on the screen. 

Normally, Three.js handles most of this for you; a single call to `THREE.WebGLRenderer#render` will copy all the necessary attribute data to the GPU, run the necessary shaders, and display the output to the screen. Behind the scenes, each `THREE.Material` corresponds to a different pair of shader programs and each `THREE.Geometry` and `THREE.BufferGeometry` yields a set of attribute buffers, and each `THREE.Mesh`, `THREE.Line`, and `THREE.PointCloud` object results in a draw call that passes the associated `Geometry`/`BufferGeometry` to a shader program defined by the `Material`.

### Bottlenecks in WebGL Rendering

- Copying attribute data around: it's slow to copy data---either in JavaScript or from the GPU to the GPU. Practically this is manifested in two places:
    + Copying attribute data to the GPU is just slow, so you should do it as infrequently as possible. The GPU has a fairly large cache of its own, so once you've moved attribute data to the GPU, it can be accessed fairly quickly by the shaer; however, there's a limited bus size to allow data transfer from the CPU to the GPU. This is why Three.js has the `THREE.BufferAttribute#needsUpdate` flag---when you set this flag to `true`, it instructs the `THREE.WebGLRenderer` to re-copy the attribute data to the GPU on the next `render` call (otherwise, even if the buffer data is changed, it will not be automatically re-copied).
    + Using `THREE.Geometry` instead of `THREE.BufferGeometry`: `THREE.Geometry` is an old API for storing geometry data that uses a lot of JavaScript objects (`THREE.Vector3`s) to store vertex positions, normal vectors, etc. This is nice because it gives a friendly API to work with; you can get the 3-element position of any vertex in the geometry, easily do calculations on it, etc. It's not so nice though because Three has to (1) perform lots of JavaScript object allocations (for all those `THREE.Vector3` objects), and (2) copy lots of stuff from those `THREE.Vector3` objects into into JavaScript `TypedArray`s
- Number of draw calls: each draw call requires loading, and setting up the vertex and fragment shaders (the "WebGL program"); this is a substantial overhead compared to executing the shaders for a single vertex or fragment. This means that if you have lots of vertices, it's preferable to group them into one `THREE.Geometry` (or `THREE.BufferGeometry`), since this can be modeled with a single draw call.
- Context switches: this is something of an exception to the above rule---if you _must_ make multiple draw calls, it's preferable to make several draw calls of the same program (e.g. using the same vertex/fragment shader pair), rather than making several draw calls with different programs, or interleaving draw calls that use different programs. 
- Number of vertices drawn: at the end of the day, the more vertices you draw, the more calculations that the GPU has to do. 

[1]: https://hacks.mozilla.org/2013/04/the-concepts-of-webgl/
[2]: https://dev.opera.com/articles/introduction-to-webgl-part-1/
[3]: http://msdn.microsoft.com/en-us/library/ie/dn385807(v=vs.85).aspx
[4]: http://duriansoftware.com/joe/An-intro-to-modern-OpenGL.-Chapter-1:-The-Graphics-Pipeline.html

## Efficiently drawing voxels

When drawing voxels, we want group voxels into the smallest number of draw calls possible, and we want to use as few vertices as we can to draw the structure. However, when a voxel changes, we want to have to send as little new geometry to the GPU as possible. Due to limitations in Three.js, any change to an attribute buffer requires the entire buffer to be re-sent to the GPU. This means that changing any vertices requires re-sending the entire geometry to the GPU. Here's what we do to balance these concerns:

- Use `THREE.BufferGeometry`: all voxels are modeled as parts of a `BufferGeometry`, to reduce the number of CPU-bound calculations and memory allocations that need to happen when changing vertices.
- Chunked rendering: rather than rendering each voxel as a separate mesh (requiring a separate draw call), voxels are grouped by the {@link C3D.views.Voxels voxels view} into {@link C3D.views.Voxels.Chunk chunks}---groups of voxels that are rendered as a single geometry. This means that when a voxel is added or removed or changed, only the attribute buffer(s) for that chunk need to be refreshed to the GPU. 
- Adaptive culling and remeshing: Even combining all voxels into a smallish number of geometries doesn't totally alleviate the performance problem, because there's just tons of vertices---especially on the interior of the structure. Rendering these is usually a waste, since they can't be seen by the user. In Minecraft and similar voxel-based applications, the voxel geometry changes relatively infrequently, and it's not necessary to see the insides of a voxel structure---so it's possible to efficiently generate a minimum number of vertices to show the outside of a structure, while culling vertices and faces that are on the interior of the structure and therefore hidden. See Meshing in a Minecraft Game [Part 1](http://0fps.net/2012/06/30/meshing-in-a-minecraft-game/) and [Part 2](http://0fps.net/2012/07/07/meshing-minecraft-part-2/) for a description of how this is done and some example code. 

    The problem with this approach for NanoBricks is that:

    1. Voxels on the interior of the structure often need to be rendered, because the user can inspect and modify the interior of the structure using the arrow keys and the X-ray mode
    2. Voxels on the surface of the structure are frequently shown and hidden when the user mouses over them with the cursor. 
    3. Voxels do not necessarily have a uniform geometry in NanoBricks---getting the geometry of a voxel requires a call to the {@link vox.lattice.Lattice#cellGeometry lattice}. Assembling a new geometry containing a given set of lattices is therefore relatively expensive and CPU-bound (since all lattice calculations have to happen on the CPU).

    We therefore adopt the following scheme: 

    - Culling: All voxels that have 2 or more neighbors in each direction are culled from the geometry by default---this results in a geometry which only includes voxels on the surface of the structure. This geometry is rendered using a custom shader which recognizes special attributes giving the color (`voxelColor`), opacity (`voxelOpacity`), and visibility  (`voxelVisible`) of each voxel. This allows voxels within the current geometry to be hidden, shown, color changed, etc. very quickly---without rebuilding the whole geometry---by changing the values of those attributes.
    - Remeshing: If voxels are added or removed such that previously-culled voxels are now exposed, a new mesh is generated which includes all visible voxels.
    - Adaptive remeshing: If this remeshing process happens to many times for a given chunk, the chunk will assume it is an active area of editing and will create a mesh containing all voxels in the chunk. Any voxels not present in the model will be hidden using attributes.
- Debounced re-rendering: In order to avoid these expensive culling and remeshing operations from being triggered for _every_ change to a model---especially when many models change together (e.g. when using the Power Edit tool, or when moving voxels)---we batch changes to each chunk. That is, we wait for all changes to complete before starting to re-render the chunk. This is implemented by adding a task to re-render the chunk to the _draw queue_ (see below) every time a model in that chunk changes. Each of these tasks is assigned an ID associated with the chunk---the draw queue ignores multiple tasks added with the same ID. All tasks will wait until the next time [the call stack is cleared and the next animation frame is called](https://developer.mozilla.org/en-US/docs/Web/API/window/requestAnimationFrame). This means that each chunk can wait to respond to all changes until right before the next frame is ready to be rendered, and it can remesh at most once for all voxels in the chunk.

## Efficiently drawing strands

Drawing strands has similar challenges to drawing voxels, and we approach them similarly. Strands are rendered in chunks, using `THREE.BufferGeometry`---just like voxels. Unlike voxels, changing strand routings unavoidably results in addition or deletion of vertices, which means remeshing is always necessary when the routing changes. Further, since strands are not solid like voxels, strands at the center of the structure cannot generally be culled.

## Maintaining responsivness with the drawing queue

The {@link C3D.Canvas3D#drawQueue drawing queue} keeps track of all operations that need to happen before the next frame is rendered. Actions can be added to the drawing queue by calling {@link C3D.Canvas3D#beforeNextDraw}. Each action is given an ID---actions with the same ID are considered to be the same, so if an action is added to the drawing queue with the same name as an action already on the queue, the new action is ignored. This allows repeated calls to the same function to be [debounced](http://drupalmotion.com/article/debounce-and-throttle-visual-explanation)---for instance, a particular chunk's remesh function will be called at most once per frame (rather than being called for each voxel that changes).

The drawing queue is cleared in the {@link C3D.Canvas3D#frame} function, which blocks repainting of the browser, making the interface non-responsive while this function is running. Since functions added to the draw queue are generally computationally intensive, clearing the draw queue can sometimes take several seconds, making the interface non-responsive for that time.

To avoid this problem, the draw queue maintains a timer which tracks how long has been elapsed since the last frame. The draw queue will clear as many items as possible before a certain duration ({@link C3D.Canvas3D@maxDrawTime}), then allow the frame to be rendered. Further items will be cleared before the next frame. Note that this is not a hard guarantee of a particular framerate, since some drawing queue operations may take longer than the {@link C3D.Canvas3D@maxDrawTime maxDrawTime}.
