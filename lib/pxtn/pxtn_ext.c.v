module pxtn

// Compiler include path
#flag -I @VMODROOT/lib/pxtn/c

// Link math library (required by the C sources)
#flag -lm
#flag -DMPXTN_OGGVORBIS

// Compile each C source file
#flag @VMODROOT/lib/pxtn/c/descriptor.c
#flag @VMODROOT/lib/pxtn/c/error.c
#flag @VMODROOT/lib/pxtn/c/freq.c
#flag @VMODROOT/lib/pxtn/c/master.c
#flag @VMODROOT/lib/pxtn/c/evelist.c
#flag @VMODROOT/lib/pxtn/c/oscillator.c
#flag @VMODROOT/lib/pxtn/c/pcm.c
#flag @VMODROOT/lib/pxtn/c/ogg.c
#flag @VMODROOT/lib/pxtn/c/ptn_tbl.c
#flag @VMODROOT/lib/pxtn/c/ptn.c
#flag @VMODROOT/lib/pxtn/c/ptv.c
#flag @VMODROOT/lib/pxtn/c/woice.c
#flag @VMODROOT/lib/pxtn/c/overdrive.c
#flag @VMODROOT/lib/pxtn/c/delay.c
#flag @VMODROOT/lib/pxtn/c/unit.c
#flag @VMODROOT/lib/pxtn/c/service.c
#flag @VMODROOT/lib/pxtn/c/mpxtn.c

// Public header
#include "mpxtn.h"
