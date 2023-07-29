# Microvidya
A small game-oriented framework powered by V, SDL2 and GLES2. 

This project started as a learning experience for myself to learn usage of OpenGL, wanting to have something that could compile for small, embedded handheld consoles like an Anbernic RG350. As such, this is something of a hobby project of mine, which I work on on and off when I find some time to work on a feature, one at a time.

This project depends on the [V SDL wrapper](https://github.com/vlang/sdl) and [vqoi](https://github.com/Le0Developer/vqoi)

Currently it compiles fine under Linux, but not on Windows due to some odd mismatched types. Mac as of now remains untested. If you wish to use this library, make sure you have `SDL2` and `SDL2_image` libraries installed.

Sorry if you find some messy code, but feel free to explore. :)
___
## Resources & Thanks
I probably would still have no idea what I was doing if it wasn't for the people before me who had done similar endeavours. If you would also try your hand at learning OpenGL, I highly recommend the following:

- VoxelRift's video on a [quick and easy OpenGL renderer](https://youtu.be/NPnQF4yABwg)
- Cherno's series on YouTube about [OpenGL](https://www.youtube.com/playlist?list=PLlrATfBNZ98foTJPJ_Ev03o2oq3-GGOS2)
- [learnopengl.com](https://learnopengl.com/)

But also thanks to these people who put work on their own fantastic things:
- Prime31, who made work on [via](https://github.com/prime31/via)
- All the contributors who made a nice V wrapper of the [SDL library](https://github.com/vlang/sdl)
- Raysan5, who created the [RRES library](https://github.com/raysan5/rres)
- RandyGaul, who made [pretty cute headers](https://github.com/RandyGaul/cute_headers)
- Everyone involved with the [V programming language](https://github.com/vlang/v)

No doubt I will probably be updating this list as time goes on. 
___
## Notice
Currently this library is a work in progress, and has quite a few unfinished features. Below is a rough todo.

- [ ] Renderer
  - [x] Textures
  - [x] Shaders
  - [x] Static batching
  - [x] Transforms
  - [x] Text rendering (via fontstash)
  - [ ] BMFont support
  - [ ] Framebuffers
  - [ ] Immediate-mode UI (via microui)
  - [ ] On-demand texture batching (via cute_spritebatch)
  - [ ] NodeTree based Scene graph
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