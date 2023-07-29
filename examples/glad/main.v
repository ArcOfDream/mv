module main

import mv.thirdparty.glad.gles2 as gl
import sdl

fn main() {
	gl.load_gles2(sdl.gl_get_proc_address)
	println('hello')
}
