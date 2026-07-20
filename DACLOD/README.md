# SLICED BREAD


Very high performance alternative to both clipmapping and chunked LOD. I would 
call it DACLOD, Data Aligned Chunked LOD. There is also a wandering GPU clipmap implementation using square grids. 

## Description
This is a very fast terrain viewer . Current version uses Terrain chunk "skirts" or hems that extrude vertically downwards by about 2 units at the boundary of the chunk. These are then shaded differently as a special condition in the vertex and fragment shaders to fake the normals and compute the texture coordinates to blend them with the ground. The normal vector contribution is also darkened slightly.

NOTE: DO NOT USE THE TRIPLANAR SHADER OR vertex_displace_world.gdshader - they are broken.

the working shader is vertex_displace_world_skirts_notriplanar.gdshader
and that should be installed in the gridtesst.tscn scene file.

## Features
* Load a 4k heightmap
* Viewport dependant level of detail
* occluders and AABB's for heightmap displacement meshes 
* Collisions working
* The images are aligned to power of 2 levels, so all the grid chunks fit better into GPU memory


## Installation
 demo scene 
## Tool Setup
> #### Example Map
### Dependencies
In project 

## Current Issues

* hard coded to specific image size, not tested on larger or alternative maps.
* compute shader collisions cause a frame rate drop when the collision mesh is added to the scene.
  
## Credits
https://github.com/SpaghettiCodeMasterThe/Godot-Quadtree-Terrain

Also the hTerrain addon.

And the SimpleTerrain addon.

And last but not least the members of the official Godot forums.

## License
MIT. I hope this helps somebody in their Godot journey!
