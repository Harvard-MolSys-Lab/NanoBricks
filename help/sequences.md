Generating sequences
====================

Sequences can be assigned to strands in NanoBricks by clicking the "Sequence" button in the main toolbar to open the Sequence window. 

Sequences are assigned in two steps: *generate* and *thread*:

- In the *generate* step, a sequence is generated for each voxel in the lattice and stored in a "sequence block"
- In the *thread* step, those sequences are "threaded" onto the strand, based on which voxels the strand passes through; strands that pass through voxels in opposite directions get complementary sequences.

There are 3 different sequence generation modes:

- In *Random* mode, sequences are generated with a pseudo-random number generator (PRNG)
- In *Linear* mode, the sequence block is loaded from a file or a string, then sequences are threaded onto the strand
- In *Excel* mode, sequences for existing strands are loaded from an Excel spreadsheet, then threaded _into_ the sequence block (that is, sequences for voxels in the block are assigned based on the existing strands). Sequences can then be assigned to new strands by threading from the sequence block.