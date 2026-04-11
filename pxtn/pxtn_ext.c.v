module pxtn

// Compiler include path
#flag -I @VMODROOT/pxtn/c

// Link math library (required by the C sources)
#flag -lm
#flag -DMPXTN_OGGVORBIS

// Compile each C source file
#flag @VMODROOT/pxtn/c/descriptor.c
#flag @VMODROOT/pxtn/c/error.c
#flag @VMODROOT/pxtn/c/freq.c
#flag @VMODROOT/pxtn/c/master.c
#flag @VMODROOT/pxtn/c/evelist.c
#flag @VMODROOT/pxtn/c/oscillator.c
#flag @VMODROOT/pxtn/c/pcm.c
#flag @VMODROOT/pxtn/c/ogg.c
#flag @VMODROOT/pxtn/c/ptn_tbl.c
#flag @VMODROOT/pxtn/c/ptn.c
#flag @VMODROOT/pxtn/c/ptv.c
#flag @VMODROOT/pxtn/c/woice.c
#flag @VMODROOT/pxtn/c/overdrive.c
#flag @VMODROOT/pxtn/c/delay.c
#flag @VMODROOT/pxtn/c/unit.c
#flag @VMODROOT/pxtn/c/service.c
#flag @VMODROOT/pxtn/c/mpxtn.c

// Public header
#include "mpxtn.h"
