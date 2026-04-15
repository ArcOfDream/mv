module mv

pub struct WrenSetup {
pub mut:
    // path to the user's main script, interpreted after the engine prelude.
    // top-level code runs immediately; node construction and tree setup go here.
    entry      string
    // application-defined foreign classes, checked after the engine's own
    // class def table in wren_bind_method / wren_bind_class.
    class_defs []WrenClassDef
    // module name -> file path, resolved when Wren hits an import statement
    modules    map[string]string
}