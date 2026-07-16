# SLICED BREAD


Very high performance alternative to both clipmapping and chunked LOD. I would 
call it DACLOD, Data Aligned Chunked LOD

## Description
This is a very fast terrain viewer . Current version is experimental. The shader attempts to snap the vertices of neighbouring LODS. The concept
is very simple, the VERTEX position is used to determine if the vertex is at an edge. I gave alternating vertices a red color value in Blender, then
re-exported. These red vertices are not present in next level of detail below, so they can be snapped to the position on the edge between the neighbour edge
vertices. The actual effect isn't currently working - there may be a problem with the fine level displacement calculation.

## Features
* Load a 4k heightmap
* Viewport dependant level of detail
* occluders and AABB's for heightmap displacement meshes 
* Collisions working
* The images and the meshes are aligned to power of 2 levels, so all the grid chunks fit better into GPU memory


## Installation
Not working, just run the demo scene if you want
## Tool Setup
> #### Example Map
### Dependencies
In project 

## Current Issues

* hard coded to specific image size, not tested on larger or alternative maps.
* collisions models are occasionally slightly off target with compute shader collision generation.
* compute shader collisions cause a frame rate drop when the collision mesh is added to the scene.
* collision models are very off target with gdscript versions.

  
## Credits
https://github.com/SpaghettiCodeMasterThe/Godot-Quadtree-Terrain

Also the hTerrain addon.

And the SimpleTerrain addon.

## License
MIT. I hope this helps somebody in their Godot journey!
