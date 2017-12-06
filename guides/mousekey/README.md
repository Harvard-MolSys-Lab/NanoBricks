Handling Mouse and Keyboard Input
=================================

NanoBricks provides several convenience tools for handling input from the mouse and keyboard. These will mostly be used within tools, but could be accessed anywhere. 

Generally, Javascript applications recieve mouse and keyboard information only during events; however, in NanoBricks we often want to know about the state of the keyboard or mouse outside an event handler. Even within event handlers, it can be more convenient to query a global mouse/keyboard state than to track down the event object, normalize it using jQuery, and access the appropriate members. 

NanoBricks provides global facilities for getting the mouse and keyboard state, and for listening to specific mouse and keyboard events.

## Mouse Handling

### Listening to mouse events

Most of the time, you'll want to execute some function (e.g. within a tool) whenever the mouse is clicked, pressed down, moved, etc. In this case, just override the appropriate method of {@link C3D.tools.Tool}: {@link C3D.tools.Tool#mousedown mousedown}, {@link C3D.tools.Tool#mouseup mouseup}, {@link C3D.tools.Tool#mousemove mousemove}, {@link C3D.tools.Tool#click click}, and {@link C3D.tools.Tool#dblclick dblclick}.

### Getting global mouse state 

Sometimes, you'll just want to know things like, "is the left mouse button down _right now_?" Or "how far has the mouse moved since it was clicked?" For this, use the {@link C3D.Canvas3D#mouse} member. This is a {@link C3D.Canvas3D.MouseState} object, which can be queried about the state of the mouse at any time---it can tell you which buttons are pressed, the current position, and the distance the mouse has been dragged.

Example: get the distance that the mouse has been dragged:

	dist = @canvas.mouse.downPosition.clone().sub(@canvas.mouse.position).length()


## Keyboard Handling

### Listening to keyboard events

The preferred method of listening for keyboard events is using the {@link C3D.Canvas3D#registerKey} and {@link C3D.tools.Tool#registerKey} API. In the simplest form, you can use it like this:

	@registerKey 'ctrl a', () => @doSomething()

(within a {@link C3D.tools.Tool tool}) to bind `ctrl+a` to the `doSomething` method. This combo will only be active when the tool is {@link C3D.tools.Tool#active active}. More options can be passed as well; for instance:

	@registerKey 'up down up down left right left right', { 
		sequence: true
		handler: () => @doSomething() 
	}

In this case, `doSomething` would be called when the passed keys are pressed in sequence (up then down then up then down and so on).


### Getting global keyboard state

Much like {@link C3D.Canvas3D#mouse}, the {@link C3D.Canvas3D#keys} member has a reference to a {@link C3D.Canvas3D.KeyState} object, which can be queried about the state of the keyboard at any time. You can use this object to check whether specific keys are pressed, get a list of all keys that are pressed, and so on.
