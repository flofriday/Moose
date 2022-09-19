// This is a signal we use in the typechecker to signal that this statement is
// beyond recoverable and we should stop checking it and continue with the next
// one.
// We use this when the typechecker is very confused from the users code and
// there is just no point in trying to reason about the provided code.
class StopTypeCheckingSignal: Error {}
