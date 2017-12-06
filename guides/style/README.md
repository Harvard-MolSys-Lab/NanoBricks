# NanoBricks Style Guide

This is the style guide for CoffeeScript in the NanoBricks project. It has been slightly modified from the original community style guide, found here: https://github.com/polarmobile/coffeescript-style-guide . 

## Code layout

### Tabs or Spaces?

Use **tabs only** for code. Do not use spaces for indentation. However, spaces **should** be used within comments for ASCII art. 

### Maximum Line Length

Limit all lines to a maximum of 79 characters.

### Blank Lines

Separate top-level function and class definitions with a single blank line.

Separate method definitions inside of a class with a single blank line.

Use a single blank line within the bodies of methods or functions in cases where this improves readability (e.g., for the purpose of delineating logical sections).

### Trailing Whitespace

Do not include trailing whitespace on any lines. Include a blank line at the end of a file.

### Optional Commas

Avoid the use of commas before newlines when properties or elements of an Object or Array are listed on separate lines.

```coffeescript
# Yes
foo = [
	'some'
	'string'
	'values'
]
bar:
	label: 'test'
	value: 87

# No
foo = [
	'some',
	'string',
	'values'
]
bar:
	label: 'test',
	value: 87
```

### Encoding

UTF-8 is the preferred source file encoding.

## Module Imports

If using a module system (CommonJS Modules, AMD, etc.), `require` statements should be placed on separate lines.

```coffeescript
require 'lib/setup'
Backbone = require 'backbone'
```
These statements should be grouped in the following order:

1. Standard library imports _(if a standard library exists)_
2. Third party library imports
3. Local imports _(imports specific to this application or library)_

## Whitespace in Expressions and Statements

Avoid extraneous whitespace in the following situations:

- Immediately inside parentheses, brackets or braces

	```coffeescript
		 ($ 'body') # Yes
		 ( $ 'body' ) # No
	```

- Immediately before a comma

	```coffeescript
		 console.log x, y # Yes
		 console.log x , y # No
	```

Additional recommendations:

- Always surround these binary operators with a **single space** on either side

		- assignment: `=`

				- _Note that this also applies when indicating default parameter value(s) in a function declaration_

				```coffeescript
				test: (param = null) -> # Yes
				test: (param=null) -> # No
				```

		- augmented assignment: `+=`, `-=`, etc.
		- comparisons: `==`, `<`, `>`, `<=`, `>=`, `unless`, etc.
		- arithmetic operators: `+`, `-`, `*`, `/`, etc.

		- _(Do not use more than one space around these operators)_

			```coffeescript
				 # Yes
				 x = 1
				 y = 1
				 fooBar = 3

				 # No
				 x			= 1
				 y			= 1
				 fooBar = 3
			```

## Comments

If modifying code that is described by an existing comment, update the comment such that it accurately reflects the new code. (Ideally, improve the code to obviate the need for the comment, and delete the comment entirely.)

For **inline** comments, the first word of the comment should **not** be capitalized, unless the first word is an identifier that begins with a capital letter. **Multiline** comments should be written in proper sentence case. 

If a comment is short, the period at the end can be omitted.

### Block Comments

Block comments apply to the block of code that follows them.

Each line of a block comment starts with a `#` and a single space, and should be indented at the same level of the code that it describes. **Do not use pass-through (`###`) comments for block comments.**

Paragraphs inside of block comments are separated by a line containing a single `#`.

```coffeescript
	# This is a block comment. Note that if this were a real block
	# comment, we would actually be describing the proceeding code.
	#
	# This is the second paragraph of the same block comment. Note
	# that this paragraph was separated from the previous paragraph
	# by a line containing a single comment character.

	init()
	start()
	stop()
```

### JSDoc/Pass-through Comments

Use [JSDuck](https://github.com/senchalabs/jsduck) comments to document classes, methods, and functions:

```coffeescript
###*
 * Adds `bar` to `baz`.
 * @param {Number} bar First number to add
 * @param {Number} baz
 * More complicated number which requires a multiline explanation for whatever
 * reason. 
 * 
 * @return {Number} Sum of baz and bar
###
foo = (bar, baz) ->
	bar + baz
```

- Use `###*` (note the trailing asterisk) to begin and `###` to end the comment. _This style must be followed exactly, or the comment will not be parsed by JSDuck.
	-	In Javascript, use `/**` to begin and `*/` to end the comment. 
- Do not use pass-through comments (`###`) for anything else.
- **Use spaces for indentation within the doc comments**.
- Use ASCII art diagrams to clarify the meaning of various parameters (e.g. for showing where a particular domain is located on a strand). Always indent the diagrams by **four spaces** so that they show up as code snippets in JSDuck-generated docs.


#### Guidelines for JSDuck Documentation

See the [JSDuck documentation](https://github.com/senchalabs/jsduck/wiki/Guide) for details on how these comments are parsed.

- General:
	- Contents are parsed as Markdown; don't include HTML unless it's necessary.
	- Prefer to include as much information (e.g. types, parameters, return values, etc.) using the structured JSDuck syntax, rather than custom Markdown.
	- Be as specific as possible when describing types; use `/` to separate multiple possible types for polymorphic values.
	- For parameters/return values/properties, either document on the same line as the `@param`/`@return`/`@property` tag or a new line, but don't start on the same line and continue on the following line:

		```coffeescript
		# yes
		###*
		 * @property {Array} models Cache of models for this controller
		###
		###*
		 * @property {Array} models 
		 Cache of models for this controller
		###


		# no
		###*
		 * @property {Array} models Cache of models 
		 for this controller
		###
		```

- Methods:
	- Include at least a one-line summary of each method; methods without any comment will not show up in the docs. 
	- Prefer documenting private methods (use the `@private` tag) rather than leaving them undocumented, since those seem to be the most confusing ones. If you don't write any docs, at least include an empty comment (with the `@private` tag) so the method shows up.
	- Provide usage examples, especially for user-facing methods (see e.g. the vox.dna.utils methods).
	- You don't need to document overridden methods unless they do something markedly different. 
- Properties:
	- Include at least the name and type of each (public) property; include a description only if it's helpful or non-obvious.
- Configurations:
	- Use the [`@cfg` directive](https://github.com/senchalabs/jsduck/wiki/@cfg) to document Backbone fields.

### Inline Comments

Inline comments are placed on the line immediately above the statement that they are describing. If the inline comment is sufficiently short, it can be placed on the same line as the statement (separated by a single space from the end of the statement).

All inline comments should start with a `#` and a single space.

The use of inline comments should be limited, because their existence is typically a sign of a code smell.

Do not use inline comments when they state the obvious:

```coffeescript
	# No
	x = x + 1 # Increment x
```

However, inline comments can be useful in certain scenarios:

```coffeescript
	# Yes
	x = x + 1 # Compensate for border
```

## Naming Conventions

Use `camelCase` (with a leading lowercase character) to name all variables, methods, and object properties.

Use `CamelCase` (with a leading uppercase character) to name all classes. _(This style is also commonly referred to as `PascalCase`, `CamelCaps`, or `CapWords`, among [other alternatives][camel-case-variations].)_

_(The **official** CoffeeScript convention is camelcase, because this simplifies interoperability with JavaScript. For more on this decision, see [here][coffeescript-issue-425].)_

For constants, use all uppercase with underscores:

```coffeescript
CONSTANT_LIKE_THIS
```

Methods and variables that are intended to be "private" should begin with a leading underscore:

```coffeescript
_privateMethod: ->
```

## Functions

_(These guidelines also apply to the methods of a class.)_

When declaring a function that takes arguments, always use a single space after the closing parenthesis of the arguments list:

```coffeescript
foo = (arg1, arg2) -> # Yes
foo = (arg1, arg2)-> # No
```

Do not use parentheses when declaring functions that take no arguments:

```coffeescript
bar = -> # Yes
bar = () -> # No
```

In cases where method calls are being chained and the code does not fit on a single line, each call should be placed on a separate line and indented by one level with a leading `.`.

```coffeescript
[1..3]
	.map((x) -> x * x)
	.concat([10..12])
	.filter((x) -> x < 11)
	.reduce((x, y) -> x + y)
```

When calling functions, choose to omit or include parentheses in such a way that optimizes for readability. Keeping in mind that "readability" can be subjective, the following examples demonstrate cases where parentheses have been omitted or included in a manner that the community deems to be optimal:

```coffeescript
baz 12

brush.ellipse x: 10, y: 20 # Braces can also be omitted or included for readability

foo(4).bar(8)

obj.value(10, 20) / obj.value(20, 10)

print inspect value

new Tag(new Value(a, b), new Arg(c))
```

You will sometimes see parentheses used to group functions (instead of being used to group function parameters). Examples of using this style (hereafter referred to as the "function grouping style"):

```coffeescript
($ '#selektor').addClass 'klass'

(foo 4).bar 8
```

This is in contrast to:

```coffeescript
$('#selektor').addClass 'klass'

foo(4).bar 8
```

No not use the function grouping style.

## Strings

Use string interpolation instead of string concatenation:

```coffeescript
"this is an #{adjective} string" # Yes
"this is an " + adjective + " string" # No
```

Prefer single quoted strings (`''`) instead of double quoted (`""`) strings, unless features like string interpolation are being used for the given string.

## Conditionals

Favor `unless` over `if` for negative conditions.

Instead of using `unless...else`, use `if...else`:

```coffeescript
	# Yes
	if true
		...
	else
		...

	# No
	unless false
		...
	else
		...
```

Multi-line if/else clauses should only use indentation if necessary (e.g. if the line is too long):

```coffeescript
	# Allowed
	if ...
		...
	else
		...

	# Preferred
	if true then ...
	else ...
```

## Looping and Comprehensions

Take advantage of comprehensions whenever possible:

```coffeescript
	# Yes
	result = (item.name for item in array)

	# No
	results = []
	for item in array
		results.push item.name
```

To filter:

```coffeescript
result = (item for item in array when item.name is "test")
```

To iterate over the keys and values of objects:

```coffeescript
object = one: 1, two: 2
alert("#{key} = #{value}") for key, value of object
```

## Extending Native Objects

Do not modify native objects.

For example, do not modify `Array.prototype` to introduce `Array#forEach`.

## Exceptions

Do not suppress exceptions.

## Annotations

Use annotations when necessary to describe a specific action that must be taken against the indicated block of code.

Write the annotation on the line immediately above the code that the annotation is describing.

The annotation keyword should be followed by a colon and a space, and a descriptive note.

```coffeescript
	# FIXME: The client's current state should *not* affect payload processing.
	resetClientState()
	processPayload()
```

If multiple lines are required by the description, indent subsequent lines with two spaces:

```coffeescript
	# TODO: Ensure that the value returned by this call falls within a certain
	#	 range, or throw an exception.
	analyze()
```

Annotation types:

- `TODO`: describe missing functionality that should be added at a later date
- `FIXME`: describe broken code that must be fixed
- `OPTIMIZE`: describe code that is inefficient and may become a bottleneck
- `HACK`: describe the use of a questionable (or ingenious) coding practice
- `REVIEW`: describe code that should be reviewed to confirm implementation

## Miscellaneous

`and` is preferred over `&&`.

`or` is preferred over `||`.

`is` is preferred over `==`.

`not` is preferred over `!`.

`or=` should be used when possible:

```coffeescript
temp or= {} # Yes
temp = temp || {} # No
```

Prefer shorthand notation (`::`) for accessing an object's prototype:

```coffeescript
Array::slice # Yes
Array.prototype.slice # No
```

Prefer `@property` over `this.property`.

```coffeescript
return @property # Yes
return this.property # No
```

Prefer the use of standalone `@` over `this` as well.

```coffeescript
return this # No
return @ # Yes
```

Avoid `return` where not required, unless the explicit return increases clarity.

Use splats (`...`) when working with functions that accept variable numbers of arguments:

```coffeescript
console.log args... # Yes

(a, b, c, rest...) -> # Yes
```

[coffeescript]: http://jashkenas.github.com/coffee-script/
[coffeescript-issue-425]: https://github.com/jashkenas/coffee-script/issues/425
[spine-js]: http://spinejs.com/
[spine-js-code-review]: https://gist.github.com/1005723
[pep8]: http://www.python.org/dev/peps/pep-0008/
[ruby-style-guide]: https://github.com/bbatsov/ruby-style-guide
[google-js-styleguide]: http://google-styleguide.googlecode.com/svn/trunk/javascriptguide.xml
[common-coffeescript-idioms]: http://arcturo.github.com/library/coffeescript/04_idioms.html
[coffeescript-specific-style-guide]: http://awardwinningfjords.com/2011/05/13/coffeescript-specific-style-guide.html
[coffeescript-faq]: https://github.com/jashkenas/coffee-script/wiki/FAQ
[camel-case-variations]: http://en.wikipedia.org/wiki/CamelCase#Variations_and_synonyms