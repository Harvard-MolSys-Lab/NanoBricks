/* 
--------------------------------------------------------------------------
NanoBricks

Copyright 2017 Molecular Systems Lab
Wyss Institute for Biologically-Inspired Engineering
Harvard University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
------------------------------------------------------------------------- 
*/


window.jQuery = window.$ = require('jquery')
UI3D = require('./ui3d')
C3D = require('./c3d');
// require('bootstrap')

// http://stackoverflow.com/a/5158301/4091874
function getParameterByName(name) {
	var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
	return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
}

$(window).ready(function () {
	
	var stats; 

	if (true) {
		stats = new Stats();
		stats.setMode(0); // 0: fps, 1: ms

		// Align top-left
		stats.domElement.style.position = 'absolute';
		stats.domElement.style.right = '0px';
		stats.domElement.style.bottom = '0px';
	}

	UI3D.Plugins.load(function(err) {
		if (err) {
			console.error(err);
		}

		// window.cx = new C3D.Canvas3D()
		// cx.init()
		// cx.setActiveTool('Pointer')
		window.ui = new UI3D.Canvas3D({ stats: stats })
		
		if (!!stats) document.body.appendChild( stats.domElement );
		
	}, { safe: !!getParameterByName('safe') })

});
