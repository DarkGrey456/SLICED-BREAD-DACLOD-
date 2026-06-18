# SLICED BREAD


Very high performance alternative to both clipmapping and chunked LOD. I would 
call it DACLOD, Data Aligned Chunked LOD

## Description
This is a very fast terrain viewer 

## Features
* Load a 4k heightmap
* Viewport dependant level of detail
* Collisions working
* The images and the meshes are aligned to power of 2 levels, so all the grid chunks fit better into GPU memory


## Installation
Not working, just run the demo scene if you want
## Tool Setup
> #### Example Map
### Dependencies
In project 

## Current Issues
* weirdness of visible chunks when first loaded before player moves
* the loading time is slow if collision is enabled (in the script)
* hard coded to specific image size, not tested on larger or alternative maps
* occluders don't seem to help

## Credits
For the code I needed for the collision model and AABB calculation. 
https://github.com/SpaghettiCodeMasterThe/Godot-Quadtree-Terrain

## License
MIT. I hope this helps somebody in their Godot journey!
