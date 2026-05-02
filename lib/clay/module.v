module clay

// Compile and link the shim (contains CLAY_IMPLEMENTATION).
// TCC needs the source file directly; GCC/Clang link it as an object.
#flag @VMODROOT/lib/clay/clay_shim.c
#flag -I @VMODROOT/lib/clay

#include "clay_shim.h"
