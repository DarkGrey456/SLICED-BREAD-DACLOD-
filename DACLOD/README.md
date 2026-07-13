# SLICED BREAD


Very high performance alternative to both clipmapping and chunked LOD. I would 
call it DACLOD, Data Aligned Chunked LOD

## Description
This is a very fast terrain viewer 

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

* hard coded to specific image size, not tested on larger or alternative maps
* collisions models are off target with both compute shader versions and gdscript versions
* the compute shader collision model has missing strips not sure why
  


## Credits
https://github.com/SpaghettiCodeMasterThe/Godot-Quadtree-Terrain

Also the hTerrain addon.

And the SimpleTerrain addon.

## License
MIT. I hope this helps somebody in their Godot journey!
