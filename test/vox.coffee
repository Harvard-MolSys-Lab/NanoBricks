expect = require('chai').expect

vox = require '../lib/vox.coffee'
THREE = require 'three'


epsilon = (x, e=0.00001) ->
	return [x-e, x+e]

describe 'vox.lit', () ->
	describe 'cmp', () ->
		it 'should compare lexicographically', () ->
			expect( vox.lit.cmp( [5, 0, 0], [4, 0, 0] ) ).is.equal 1
			expect( vox.lit.cmp( [4, 0, 0], [5, 0, 0] ) ).is.equal -1

			expect( vox.lit.cmp( [5, 1, 0], [5, 0, 0] ) ).is.equal 1
			expect( vox.lit.cmp( [5, 0, 0], [5, 1, 0] ) ).is.equal -1


			expect( vox.lit.cmp( [5, 1, 1], [5, 1, 0] ) ).is.equal 1
			expect( vox.lit.cmp( [5, 1, 0], [5, 1, 1] ) ).is.equal -1

	describe 'eq', () ->
		it 'should compare properly', ->
			expect( vox.lit.eq( [5, 10, 4], [5, 10, 4] ) ).is.equal true
			expect( vox.lit.eq( [5, 10, 4], [6, 10, 4] ) ).is.equal false
			expect( vox.lit.eq( [5, 11, 4], [5, 10, 4] ) ).is.equal false
			expect( vox.lit.eq( [5, 10, 6], [5, 10, 4] ) ).is.equal false

	describe 'less', () ->
		it 'should compare properly', ->
			expect( vox.lit.less( [5, 10, 4], [5, 10, 4] ) ).is.equal false
			expect( vox.lit.less( [5, 10, 4], [6, 10, 4] ) ).is.equal true
			expect( vox.lit.less( [5, 11, 4], [5, 10, 4] ) ).is.equal false
			expect( vox.lit.less( [5, 10, 6], [5, 10, 4] ) ).is.equal false

	describe 'greater', () ->
		it 'should compare properly', ->
			expect( vox.lit.greater( [5, 10, 4], [5, 10, 4] ) ).is.equal false
			expect( vox.lit.greater( [5, 10, 4], [6, 10, 4] ) ).is.equal false
			expect( vox.lit.greater( [5, 11, 4], [5, 10, 4] ) ).is.equal true
			expect( vox.lit.greater( [5, 10, 6], [5, 10, 4] ) ).is.equal true



describe 'vox.lattice.Cubic', () ->

	describe 'constructor', () ->
		it 'should setup cell correctly', () ->
			cell = 10
			lattice = new vox.lattice.Cubic(10,10,10,{
				cell: [cell, cell, cell],
				offsets: [0,0,0]
			})

			expect( lattice.cell ).is.deep.equal( [cell, cell, cell] )

		it 'should setup offests correctly', () ->
			cell = 10
			lattice = new vox.lattice.Cubic(10,10,10,{
				cell: cell,
				offsets: [0,0,0]
			})

			expect( lattice.offsets ).is.deep.equal( [0, 0, 0] )

	describe 'pointToLattice', () ->
		it 'should compute correctly without offsets', () ->
			cell = 10
			lattice = new vox.lattice.Cubic(10,10,10,{
				cell: [cell, cell, cell],
				offsets: [0,0,0]
			})

			expect( lattice.pointToLattice(0,0,0) ).is.deep.equal( [0,0,0] )
			expect( lattice.pointToLattice(1,1,1) ).is.deep.equal( [0,0,0] )
			expect( lattice.pointToLattice(2,2,2) ).is.deep.equal( [0,0,0] )
			expect( lattice.pointToLattice(9,9,9) ).is.deep.equal( [0,0,0] )
			expect( lattice.pointToLattice(10,10,10) ).is.deep.equal( [1,1,1] )

		it 'should compute correctly with offsets', () ->
			lattice = new vox.lattice.Cubic(10,10,10,{
				cell: [10, 10, 10],
				offsets: [5,5,5]
			})

			expect( lattice.pointToLattice(10,10,10) ).is.deep.equal( [1,1,1] )
			
		it 'should undo latticeToPoint', () ->
			lattice = new vox.lattice.Cubic(10,10,10,{
				cell: [10, 10, 10],
				offsets: [5,5,5]
			})
			latticePoint = [5,5,5]

			expect( lattice.pointToLattice(lattice.latticeToPoint(latticePoint...)...) ).is.deep.equal( latticePoint )

	describe 'latticeToPoint', () ->

		it 'should undo pointToLattice for a centered point', () ->
			lattice = new vox.lattice.Cubic(10,10,10,{
				cell: [10, 10, 10],
				offsets: [5,5,5]
			})
			point = [10,10,10]

			expect( lattice.latticeToPoint(lattice.pointToLattice(point...)...) ).is.deep.equal( point )

	describe 'snap', () ->
		it 'should snap point to center of correct cell', () ->
			lattice = new vox.lattice.Cubic(10,10,10,{
				cell: [10, 10, 10],
				offsets: [0,0,0]
				offsets: [5,5,5]
			})
			point = [10,10,10]

			expect( lattice.snap(0,0,0) ).is.deep.equal( [0,0,0] )
			expect( lattice.snap(1,1,1) ).is.deep.equal( [0,0,0] )
			expect( lattice.snap(10,10,10) ).is.deep.equal( [10,10,10] )




describe 'vox.lattice.CentralSpline', () ->

	describe 'closest', () ->
		it 'should find the closest point to the spline', ->
			lattice = new vox.lattice.CentralSpline(2,2,2,{
				cell: [10,10,10],
				spline: [new THREE.Vector3(0,0,0), new THREE.Vector3(0,0,10), new THREE.Vector3(0,0,20)]
			})

			expect(lattice.closest(0,0, 5)).is.within(epsilon(0.275)...)
			expect(lattice.closest(0,0,10)).is.within(epsilon(0.500)...)
			expect(lattice.closest(0,0,15)).is.within(epsilon(0.725)...)
			expect(lattice.closest(0,0,20)).is.within(epsilon(    1)...)		


describe 'vox.compilers.utils', () ->
	describe 'res', ->

		it 'should wrap properly for one-component crystal', ->
			utils = vox.compilers.utils {}, {}, { crystal: [[2,4]] }

			# x:
			#  -1 0 1 | 2 3 4 | 5 6
			#  -------|-------|----
			#   2 3 4 | 2 3 4 | 2 3


			expect(utils.res(2,0,0)).is.deep.equal [2,0,0]
			expect(utils.res(1,0,0)).is.deep.equal [4,0,0]
			expect(utils.res(0,0,0)).is.deep.equal [3,0,0]
			expect(utils.res(-1,0,0)).is.deep.equal [2,0,0]

			expect(utils.res(5,0,0)).is.deep.equal [2,0,0]
			expect(utils.res(6,0,0)).is.deep.equal [3,0,0]

		it 'should wrap properly for two-component crystal', ->

			# x:
			#  -1 0 1 | 2 3 4 | 5 6
			#  -------|-------|----
			#   2 3 4 | 2 3 4 | 2 3
			#   
			# y:
			#  -2 -1 | 0 1 2 3 4 5 | 6 7
			#  ------|-------------|-----
			#   4  5   0 1 2 3 4 5 | 0 1

			utils = vox.compilers.utils {}, {}, { crystal: [[2,4], [0,5]] }

			expect(utils.res(2,2,0)).is.deep.equal [2,2,0]
			expect(utils.res(1,2,0)).is.deep.equal [4,2,0]
			expect(utils.res(2,-1,0)).is.deep.equal [2,5,0]
			expect(utils.res(1,-1,0)).is.deep.equal [4,5,0]
		
