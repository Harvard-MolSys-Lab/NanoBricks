# CoffeeScript

NanoBricks uses the **[CoffeeScript](http://coffeescript.org/)** programming language
for scripting; in many places within NanoBricks, you can write little snippets of 
CoffeeScript to automate repetitive tasks. Coffeescript looks a lot like Python
or Ruby, but runs in your browser. Check out http://coffeescript.org/ for lots 
more detail.


### Operators

Standard mathematical operators are available:

- Arithmetic: `+`, `-`, `*`, `/`, `%` (Modulo/remainder), `**` (Exponentiation), `//` (Integer division/floor), `%%` (Mathematical modulo)
- Comparison and Logic: `<`, `>`, `<=`, `>=`, `is` (`==`), `isnt` (`!=`), `and`, `or`, `not` `in`

Note that `true`/`yes`/`on` are the same, and `false`/`no`/`off` are the same.


### Lists

Make lists with square brackets `[]`:
		
	my_list = [item1, item2, item3]

Easily make ranges using `...` (exclusive)

	range = [0...5] # = [0, 1, 2, 3, 4]

or `..` (inclusive)
	
	range = [0..5] # = [0, 1, 2, 3, 4, 5]

Test for list or range membership with `in`:

	2 in [0..5] # true
	4 in [0, 2, 6, 16] # false

Normal arithmetic operators (`+`, `-`, `is`, etc.) don't work on lists; instead, NanoBricks provides some small functions which you can use for easy element-wise arithmetic.

- Arithmetic: `add`, `sub`tract, `mul`iply, `div`ide (take two arrays, return new array). Example:
	
		add [1, 2, 3], [5, 6, 7] # [6, 8, 10]
		div [2, 4, 8], [2, 2, 2] # [1, 2, 3]

- Comparison and logic: `equals` (`eq`), `less`, `greater`, `leq`, `geq`, and `sum` (take two arrays, return scalar). Example:

		eq [1, 2, 3], [5, 6, 7] # false
		less [1, 2, 3], [1, 2, 4] # true

For more complicated operations, you can use a comprehension:
	
	a = [4, 6, 13]
	b = [1, 6, 2]
	(Math.sqrt a[i] ** b[i]) for x,i in a

### Loops

Loop forever with `loop`.
		
Loop over a collection or range with `for`...`in`:

<pre>
for i in [0..5]
	<var>action</var>
</pre>	

You can get a list of results as well:

	items = (i+1 for i in [0..5]) # [1, 2, 3, 4, 5, 6]

Filter the list with `when`:

	items = (i+1 for i in [0..5] when i isnt 3) # [1, 2, 3, 5, 6]


### Objects

Make objects with curly braces: `{}`:

	my_object = { foo: 'bar', baz: 'bat'}
	my_object.foo = 'new value'

Or implicitly, using indentation:

	my_object = 
		foo: 'bar'
		baz: 'bat'

Test for object membership using `of`:

	'foo' of { foo: 1, bar: 2 } # true


### Conditions

Write conditions using `if` and `else`; indent the actions:

<pre>
if <var>condition 1</var>
 	<var>action 1</var>
else if <var>condition 2</var>
 	<var>action 2</var>
else
 	<var>action 3</var>
</pre>

Use `then` to write actions inline with conditions: <code>if <var>conditon</var> then <var>action 1</var> else <var>action 2</var></code>

`unless` is the opposite of `if`: <code>unless <var>conditon</var> then <var>action 1</var> else <var>action 2</var></code>

You can also use conditionals as expressions:
		
	color = if x > 5 then 0xff0000 else 0x000000


### Functions

Call functions by writing the name, then the arguments:

	my_func arg1, arg2
	
You can use parenthesis to call functions with no arguments, or to make things clearer:

	my_func()
	my_func_1 my_func_2(arg1,arg2)
	

You can pass a list of arguments using the splat (`...`):
	
	list_of_args = [arg1, arg2, arg3]
	my_func list_of_args... # the same as my_func arg1, arg2, arg3

Define functions with an arrow `->`. Use indentation for a multi-line body. The last value will be returned:

<pre>
my_func = (arg1, arg2) ->
	...
	<var> return expression</var>
</pre>

<pre>my_short_function = (arg1, arg2) -> <var>return expression</var></pre>


You can still use the `return` keyword if you want to return prematurely. 

