// This is internally used by the interpreter, since early returns shortcut the
// rest of a block, we implement them with throwing exceptions.
struct ReturnSignal: Error {
    let value: MooseObject
}
