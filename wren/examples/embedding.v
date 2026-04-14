// A V port of the "wren/example/embedding/main.c" file
// For more details, visit https://wren.io/embedding/

module main

import wren

@[manualfree]
fn write_fn(vm &wren.VM, const_text &char) {
	str := unsafe { cstring_to_vstring(const_text) }
	println(str)
	unsafe { str.free() }
}

@[manualfree]
fn error_fn(vm &wren.VM, error_type wren.ErrorType, const_module &char, const_line int, const_msg &char) {
	mod := unsafe { cstring_to_vstring(const_module) }
	msg := unsafe { cstring_to_vstring(const_msg) }
	match error_type {
		.compile {
			println('${mod} line ${const_line}: ERROR: ${msg}')
		}
		.stack_trace {
			println('${mod} line ${const_line} in ${msg}')
		}
		.runtime {
			println('Runtime error: ${msg}')
		}
	}
	unsafe { mod.free() }
	unsafe { msg.free() }
}

fn main() {
	mut config := wren.Configuration{}

	wren.init_configuration(&config)

	config.writeFn = write_fn
	config.errorFn = error_fn

	mut vm := wren.new_vm(&config)

	@module := 'main'
	script := 'System.print("I am running in a VM!")'

	result := vm.interpret(@module, script)

	match result {
		.compile_error {
			println('Compile Error')
		}
		.runtime_error {
			println('Runtime Error!')
		}
		.success {
			println('Success!')
		}
	}
	wren.free_vm(vm)
}
