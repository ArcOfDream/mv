# Microvidya
A small game-oriented framework powered by V, SDL2 and GLES2. 

This project started as a learning experience for myself to learn usage of OpenGL, wanting to have something that could compile for small, embedded handheld consoles like an Anbernic RG350. As such, this is something of a hobby project of mine, which I work on on and off when I find some time to work on a feature, one at a time.

This project depends on the [V SDL wrapper](https://github.com/vlang/sdl) and [vqoi](https://github.com/Le0Developer/vqoi)

Currently it compiles fine under Linux, but not on Windows due to some odd mismatched types. Mac as of now remains untested. If you wish to use this library, make sure you have `SDL2` and `SDL2_image` libraries installed.

Sorry if you find some messy code, but feel free to explore. :)
___
## Notice
Currently this library is a work in progress, and has quite a few unfinished features. Below is a rough todo.

- [ ] Renderer
  - [x] Textures
  - [x] Shaders
  - [x] Static batching
  - [x] Transforms
  - [ ] Text rendering (via fontstash)
  - [ ] BMFont support
  - [ ] On-demand texture batching (via cute_spritebatch)
  - [ ] NodeTree based Scene tree
- [ ] Resources
  - [x] Basic loading of images and shaders.
  - [ ] RRES support
- [ ] Collisions
  - [ ] Port [via](https://github.com/prime31/via) collisions
- [ ] Audio
  - [ ] Buses
  - [ ] Basic audio playback
  - [ ] Streaming audio playback
  - [ ] PXTone music (via libmpxtn)
  - [ ] DSP Effects
- [ ] Scripting (via Wren)
  - [ ] Export library functions to be accessible through Wren
  - [ ] Potentially automate generating foreign interfaces at compile time?
___
## License
Unless otherwise stated, this code is licensed under the MIT license.