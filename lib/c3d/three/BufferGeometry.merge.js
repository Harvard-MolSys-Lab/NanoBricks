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


module.exports = function(THREE) {

THREE.BufferGeometry.prototype.mergeMany = function(geometries, matrices) {

	var attributes = this.attributes;
	var attrInfo = {}
	var vertexCounts = [];
	var vertexCount = 0;
	var geometry;
	var matrix;
	var attribute;
	var attributeArray;
	var geometryAttributeArray;
	var geometryVertices;

	// collect all attributes from all geometries, count total vertices
	for ( var i = 0; i < geometries.length; i++ ) {

		geometry = geometries[i];
		for ( var attr in geometry.attributes ) {

			if ( ! (attr in attrInfo) ) {

				attrInfo[attr] = {  
					type : geometry.attributes[attr].array.constructor,
					itemSize : geometry.attributes[attr].itemSize
				}

			}

		}
		vertexCounts[i] = geometry.attributes['position'].array.length / 3;
		vertexCount += vertexCounts[i];

	}


	// build new BufferAttributes
	for ( var attr in attrInfo ) {

		attribute = attrInfo[attr];
		this.addAttribute( attr, new THREE.BufferAttribute( 
			new attribute.type( vertexCount * attribute.itemSize ), 
			attribute.itemSize ) );

	}

	// iterate over each geometry, merging attributes
	var vertexIndex = 0;

	for ( var i = 0; i < geometries.length; i++ ) {

		geometry = geometries[i];
		matrix = matrices[i];
		geometryVertices = vertexCounts[i];

		// for each attribute of geometry
		for ( var attr in geometry.attributes ) {

			attribute = attributes[attr];
			attributeArray = attribute.array;
			geometryAttributeArray = geometry.attributes[attr].array;

			// copy geometry's attribute values into array
			for ( var j = vertexIndex * attribute.itemSize, k = 0, l = geometryAttributeArray.length; k < l; j++, k++ ) {

				attributeArray[j] = geometryAttributeArray[k];

			}

			// apply matrix transformation as appropriate
			if ( attr == 'position' || attr == 'normal' ) {

				matrix.applyToVector3Array( attributeArray, vertexIndex * 3, geometryVertices * 3 );

			}

		}

		vertexIndex += geometryVertices;

	}	

}

};