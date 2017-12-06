# Plugins

Plugins can extend NanoBricks with additional functionality (extra tools, lattices, translation schemes, or other functionality). Plugins are simply extra JavaScript files which are loaded by NanoBricks. You can add plugins from any website, or even from your local computer. Once a plugin is added to NanoBricks, it will be loaded every time you open NanoBricks; you can remove plugins that you no longer wish to load. 

## Adding and removing plugins

To add or remove plugins first click the "Plugins" link in the top left corner of NanoBricks. 

### Adding plugins
You can type or paste a URL to a JavaScript file into the text box, then click "Add" to save the plugin. The URL must be a complete URL, starting with `http://` (or `https://`, or `file:///`), and ending with `.js` (for JavaScript). The plugin won't be loaded until you next refresh the page. 

To load a plugin from your local machine, you can add a URL starting with `file:///`, then a path to the file on your computer. An easy way to get these URLs is to drag and drop the file from your computer into the web browser (or use `File > Open`), then copy the URL from the address bar.

### Removing plugins
To remove a plugin, simply click the "Delete" button next to its name. The plugin will not be removed until the next time your refresh the page.

### Safe mode
If a plugin is giving you trouble, or you can't load NanoBricks (e.g. if you see only a blank page when you open NanoBricks), you may want to start NanoBricks in Safe Mode---this will disable all plugins (without deleting them). To open NanoBricks in safe mode, just add `?safe=true` to the end of the NanoBricks URL. You can leave safe mode by deleting this text and refreshing the page. Within safe mode, you can still add and remove plugins but the plugins will not be loaded.  


## Writing plugins

Plugins are simple JavaScript files which should access or modify classes in the `C3D`, `UI3D` or `vox` namespaces. For further details, see the "Writing plugins" and ["Tool Development"](docs:guide/tools) guides in the API documentation.