# RRES for V

### Status
As of now the wrapper compiles, but there's work to be done identifying which enums go into which struct.

RRES requires you to work your own implementation for loading the chunks into individual resources, a good example of which is provided via rres_raylib.h

Microvidya will likely use the built-in modules for decompression and decyphering, and vqoi for decompressing QOI resources.