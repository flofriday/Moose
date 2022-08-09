//
//  Created by flofriday on 08.08.2022
//

// This is the implementation of the environments that manage the life of
// variables, functions, classes etc.
//
// Note about this implementation: This implementation is very liberal, and
// doesn't check many errors. For example we don't validate types here.
// We can do this because the typechecker will always be run before this so we
// can assume here that the programs we see are well typed. And even if they
// weren't it wouldn't be our concern but a bug in the typechecker.
class Environment {
    let enclosing: Environment?
    private var variables: [String: MooseObject] = [:]
    private var funcs: [String: [MooseObject]] = [:]

    init(enclosing: Environment?) {
        self.enclosing = enclosing
    }
}

// The variable handling
extension Environment {
    /// Update a variable, if it is not found in this Evironment or any
    /// enclosing one, a new variable will be created.
    /// Returns true if the variable was found or defined.
    func update(variable: String, value: MooseObject, allowDefine: Bool = true) -> Bool {
        // Update if in current env
        if variables[variable] != nil {
            variables.updateValue(value, forKey: variable)
            return true
        }

        // Scan in enclosing envs
        if let enclosing = enclosing {
            let found = enclosing.update(variable: variable, value: value, allowDefine: false)
            if found {
                return true
            }
        }

        // Update if we are allowed to define new variables
        guard allowDefine else {
            return false
        }
        variables.updateValue(value, forKey: variable)
        return true
    }

    /// Return the Mooseobject a variable is referencing to
    func get(variable: String) throws -> MooseObject {
        if let obj = variables[variable] {
            return obj
        }

        if let enclosing = enclosing {
            return try enclosing.get(variable: variable)
        } else {
            throw EnvironmentError(message: "Variable '\(variable)' not found.")
        }
    }
}

// Define all function operations
extension Environment {
    private func isFuncBy(params: [MooseType], other: MooseType) -> Bool {
        if case .Function(params, _) = other {
            return true
        }
        return false
    }

    func set(function: String, value: MooseObject) {
        if funcs[function] == nil {
            funcs[function] = []
        }

        funcs[function]!.append(value)
    }

    func get(function: String, params: [MooseType]) throws -> MooseObject {
        if let obj = funcs[function]?.first(where: { isFuncBy(params: params, other: $0.type) }) {
            return obj
        }
        guard let enclosing = enclosing else {
            throw EnvironmentError(message: "Function '\(function)' not found.")
        }
        return try enclosing.get(function: function, params: params)
    }
}

// Some helper functions
extension Environment {
    func isGlobal() -> Bool {
        return enclosing == nil
    }
}

// Debug functions to get a better look into what the current environment is
// doing
extension Environment {
    func printDebug(header: Bool = true) {
        if header {
            print("=== Environment Debug Output (most inner scope last) ===")
        }

        if let enclosing = enclosing {
            enclosing.printDebug(header: false)
        }

        if isGlobal() {
            print("--- Environment (global) ---")
        } else {
            print("--- Environment ---")
        }
        print("Variables: ")
        for (variable, value) in variables {
            print("\t\(variable): \(value.type.description) = \(value.description)")
        }
        print("Functions: ")
        for (function, values) in funcs {
            for value in values {
                print("\t\(function) = \(value.description)")
            }
        }
    }
}
