# Strands in NanoBricks

This document describes the {@link C3D.models.SST models} and data structures ({@link vox.dna.Strand}, {@link vox.dna.Base}) that represent strands and bases in the NanoBricks software.

## General representation of strands

Each strand is represented by an either an {@link vox.dna.Strand object} or a {@link C3D.models.SST model}. These objects have one important attribute---the `routing`---which describes the order and position of each base on the strand within the lattice. There are numerous other optional attributes---a name identifying the strand, a sequence, a color, some description of the strand's crossover architecture (e.g. {@link vox.dna.Strand#dir}, {@link vox.dna.Strand#plane}) for the sake of writing {@link vox.compilers translation schemes}, a plate and/or well name (to map the strand to an existing sample volume in the lab), and possibly others. The NanoBricks architecture thus allows arbitrary "metadata" to be associated with the strand---you could add additional attributes identifying a strand as having particular chemical modifications, or deliniate important sub-structures by adding attributes to strands, etc. 

## Strand models vs. Strand objects

It's important to note that there are two separate representations of strands within NanoBricks---as models (instances of {@link C3D.models.SST}) and as plain old JavaScript objects (described by the interface {@link vox.dna.Strand}). Within the {@link vox} module (e.g. in translation schemes, utility methods, etc.), strands are always assumed to be plain old JavaScript objects obeying the {@link vox.dna.Strand} interface (with at least a `routing` property). Within the {@link C3D} module, strands are always represented as {@link C3D.models.SST models}, like everything else. In this case, `routing` (and other data) is an {@link Backbone.Model#get attribute}, rather than a property. This distinction exists because the `vox` module has no knowledge of `C3D` and can define its utility methods independently of any `C3D` classes, but {@link C3D.models.Models C3D models} must be able to serialize/deserialize themselves, {@link C3D.models.Model#get get} and {@link C3D.models.Model#set set} attributes, and so on.

To convert a {@link vox.dna.Strand strand object} into a {@link C3D.models.SST strand model}, simply pass the object to the object to the SST constructor:

    # given some `strandObject`
    strandModel = new C3D.models.SST strandObject

To go the other way (from model to object), you can clone the `attributes` array of the model:

    # given some `strandModel`
    strandObject = _.clone strandModel.attributes

### Strand routing

The most important attribute of a strand is called the "routing". The routing describes the position of each base within the {@link C3D.Canvas3D#lattice} (that is, how the strand itself is "routed" throughout the lattice). The routing attribute is an array of {@link vox.dna.Base} objects, in 5' to 3' order. Each base---like the strands---can have arbitrary attributes: a sequence, chemical modifications, etc. Most importantly, the base *must* have two attributes: 

* {@link vox.dna.Base#pos} --- an Array containing the four-component lattice position of the base. Off-lattice bases are given `-1` for their last component (e.g. `[1, 3, 4, -1]` would indicate a base that was off the lattice, but tied to helix `1, 3` on the `4`th domain.)
* {@link vox.dna.Base#dir} --- a number, `-1` or `1`, indicating whether the base is oriented 5' to 3' (`1`) or 3' to 5' (`-1`) with respect to the +Z axis. Two bases which are Watson-Crick paired would have the same `pos` but opposite signed `dir`s.

To modify a strand, one thus needs to modify the routing. This is done by simply adding or removing {@link vox.dna.Base base objects} from the routing array. Note that there is no _class_ {@link vox.dna.Base}---this just defines an interface for plain old JavaScript objects. 

> **Important**: When modifying the routing of a {@link C3D.models.SST strand model}, take care to use the {@link C3D.models.SST#set set method} appropriately so that changes are fired as expected. Specifically, if you {@link C3D.models.SST#get get} the routing array, change it, then {@link C3D.models.SST#set set} the routing to the _same_ array, _changes will not be fired_. This is because, even for mutable data structures like Arrays, Backbone does simple equality comparison (`==`) between the old and new value of an attribute in order to determine whether the attribute has changed. The following will **not** work:
> 
>   r = strand.get('routing')
>   r.push { 'pos': [4, 3, 7, 5] }
>   strand.set('routing', r) 
>   # bad: will not fire change events, because r == strand.get('routing')
> 
> It is therefore necessary to create a shallow copy of the routing (e.g. using {@link _#clone}) before calling {@link C3D.models.Model#set set} again:
>   
>   r = _.clone strand.get('routing')
>   r.push { 'pos': [4, 3, 7, 5] }
>   strand.set('routing', r) 
>   # good: will fire change events, because r != strand.get('routing')

There are several convenience functions for modifying a routing array---see {@link vox.dna.utils}. Most of these functions are also presented as methods of {@link C3D.models.SST strand models} which take care of {@link C3D.models.SST#get getting}, cloning, and {@link C3D.models.SST#set setting} the routing array for you.

## Sequences

It's worth noting that sequence data can be associated with either the strand _or_ the base. This is because the user may choose to assign sequences using one of several methods (see {@link C3D.models.ss})---randomly, using a sequence designer, etc. These methods populate the {@link C3D.models.SST#sequence sequence attribute} of the strand model. However, we may want to lock particular bases to a certain base---e.g. force certain bases of a strand to form a poly-T protector. To do this, we can set the {@link vox.dna.Base#seq} property of those bases to a certain letter. When assembling the {@link C3D.models.SST#sequence sequence} string for a strand, the sequence designer will respect these "forced" bases.

## Differences from caDNAno

There is an important conceptual difference between caDNAno's representation of strands and NanoBricks'. In NanoBricks, each strand is represented as an explict object, allowing arbitrary metadata to be attached to the strand. The strand's routing is explicitly attached to the strand, allowing the strand to be routed arbitrarily throughout the lattice. caDNAno by contrast maintains a big array of _helices_ rather than strands (though they're confusingly called  {@link vox.dna.CaDNAno#vstrands vstrands} in the file format). Each of these helices describes the connectivity of each base in that helix. Specifically, for each base in the helix, an entry gives the position of the 5' neighbor and the 3' neighbor of that base. There is no explicit representation of each strand---the strand is more like a doubly-linked list of bases (with each base indicating its neighbors).

There are advantages and disadvantages to each model. caDNAno's model makes it trivial to add and remove crossovers, or to conect strands together---one only needs to modify the entries of the two bases that are being connected (or disconnected). Since the strand is implicit, there's no need to modify a routing---all the information about strands is stored in the {@link vox.dna.CaDNAno#vstrands} array. However, this makes it very difficult to track information about _particular_ strands (e.g. a name, well, etc.) or bases (e.g. a forced sequence), or even to enumerate over all the strands in the design. caDNAno's model has a further limitation, which is that information about the directionality of strands is entirely implicit. Each strand is classified as either a scaffold or a staple strand, and based on this designation and the strand's helical position, the strand is assumed to run either 5' to 3' or 3' to 5' with respect to the Z-axis. This makes it impossible to represent certain types of connections (for instance, hairpins) where a strand binds to itself (or binds to another strand that doesn't clearly obey the strand/scaffold distinction). See {@link vox.dna.CaDNAno.Helix#num} for a further discussion of this convention.


