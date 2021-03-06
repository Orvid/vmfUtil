vmfUtil
=======

This is a utility for doing various things with a Valve Map File. 

# Modes

### Clean
This is the default mode, and was the primary reason vmfUtil was created. It can:
* Round brushes to be comprised of whole-unit numbers.
* Tranform flat displacement maps back into normal brushes, reducing final map size
  as well as the time it takes to compile the map.
* Unformly texture all tool faces, which can result in *minor* improvements to both
  compile time and the final map size.
* Automatically add all visleaf and viscluster brushes to their own visgroup.
* WIP: Merge redundant brushes

### Visleaf
This mode is intended to be used as part of the regular compile process of a map. It
locates all of the visleaf textured brushes, and creates a func_viscluster to occupy
the same space. When combined with the Portals mode, it effectively lets you manually
define the visleafs on a map.

### Portals
###### This is currently BROKEN ######
This mode is intended to be used as part of the regular compile process of a map. It
reads the portal file generated by `vbsp` and aggressively attempts to merge portals
between visclusters. When combined with the Visleaf mode, it effectively lets you
manually define the visleafs on a map.

### Manifest
This mode is intended for those looking to get various information about their map, 
including:
* Which textures are being used and how many times it's being used.
* Which brush faces are not aligned to the grid. This is currently hard-coded to
  be 16 units.

### Writeback
This mode is intended primarily for development purposes. It does nothing but reads
the map file in, and writes it back out. It is used to ensure that no data is lost
when round-tripping a map file.
