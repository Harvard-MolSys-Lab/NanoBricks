# NanoBricks File handling

NanoBricks saves data in a JSON-based file format---`.nbk` files. This guide describes the structure of these files, how they are generated and how they are saved. Fundamentally, `.nbk` files contain a serialized representation of a {@link C3D.Canvas3D}. Saving and loading files is thus a matter of serialzing (to JSON) the contents of the {@link C3D.Canvas3D}, then parsing and vivifying that representation.

## Serialization and Vivification

Objects are _serialized_ by the function {@link underscore#toJSON}, defined by C3D, which accepts an object and returns a "serialized" version of it, which must be a plain JavaScript `Object`, `Array`, or primitive (`String`, `Number`, `Date`). The resulting object can be converted to a string using `JSON.stringify`. By default, {@link underscore#toJSON} deep clones any plain JavaScript `Object`s and `Array`s, and calls the `toJSON` method of any passed objects that implement it. Subclases of {@link C3D.Base} (including {@link C3D.models.Model}) define a {@link C3D.Base#toJSON toJSON} method that serializes their {@link Backbone.Model#attributes attributes hash}, for instance.

The opposite of serialization is _vivification_, where a plain JavaScript `Object` (e.g. loaded from a JSON file) into an instance of some class. This is done by {@link underscore#vivify}, which inspects the `_class` attribute of passed objects and tries to resolve that string to a constructor function within the global object. For instance, the following object:

	{ 
		"_class": "C3D.models.Voxel",
		"latticePosition": [7, 4, 10],
		"color": 0xff0000
	}

would be vivified to an instance of {@link C3D.models.Voxel}.

Saving a {@link C3D.Canvas3D} as a `.nbk` file is thus a matter of _serializing_ the canvas (using {@link underscore#toJSON}) and converting the result to a `String` and downloading it to the user's browser. Loading a `.nbk` file requires vivifying members of a serialized object. This process is described in detail below.

## Saving files

Saving a file (from an active {@link C3D.Canvas3D} to a user download) happens in several steps:

- {@link UI3D.Canvas3D#saveNB} is called in response to a user interface event
- {@link UI3D.Canvas3D#saveNB} calls {@link C3D.Canvas3D#save}
- {@link C3D.Canvas3D#save} serializes all members in its {@link C3D.Canvas3D#serializable list of serializable properties}, by calling {@link underscore#toJSON} on them. By default, this means serializing {@link C3D.Canvas3D#data} to an array of models. Other properties (such as the {@link C3D.Canvas3D#lattice lattice}) may also be serialized.
- {@link UI3D.Canvas3D#saveNB} converts the serialized canvas to a string with `JSON.stringify`
- {@link UI3D.Canvas3D#saveNB} calls {@link UI3D.Canvas3D#saveFile} to download the file to the user's machine.

## Loading files

Loading a file to generate a new {@link C3D.Canvas3D} happens in several steps as well:

- {@link UI3D.Canvas3D#loadNB} is passed the `.nbk` file as text in response to a user interface event
- {@link UI3D.Canvas3D#loadNB} parses the JSON file to a JavaScript object
- {@link UI3D.Canvas3D#loadNB} calls {@link C3D.Canvas3D#load}. {@link C3D.Canvas3D#load} examines the `version` member of the file and determines whether to apply any {@link C3D.Legacy#adapters adapter function(s)}.
- {@link C3D.Canvas3D#load} instantiates a new {@link C3D.Canvas3D}, passing the updated file object as the first argument.
- The resulting C3D.Canvas3D deserializes and vivifies (calling {@link _#vivify} on the serialized object) all properties _except_ {@link C3D.Canvas3D#data data}. Models in {@link C3D.Canvas3D#data data} are not loaded until _after_ all {@link C3D.Canvas3D#ctrls controllers}, {@link C3D.Canvas3D#views views}, and {@link C3D.Canvas3D#tools tools} are instantiated and initialized.

## `nbk` file format

NanoBricks `.nbk` files consist of a single JavaScript object that must at least have the following members:

- `version` {String} : [semver](http://semver.org/)-compatible indication of the NanoBricks version which saved the file.
- `data` {{@link C3D.models.Model}[]} : array of {@link C3D.models.Model model}s which would live in within {@link C3D.Canvas3D#data}. Each object must at least have the following members:
	- `_class_` {String} : fully-qualified name of the class to which this object should resolve when {@link _#vivify vivified}. The vivifier will lookup the specified class constructor, then pass this object as the only argument to the constructor.
- `lattice` {Object} : serialized version of a {@link vox.lattice.Lattice}.