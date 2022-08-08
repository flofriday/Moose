class Environment {
    let enclosing: Environment?
    var variables: [String: MooseObject] = [:]

    init(enclosing: Environment?) {
        self.enclosing = enclosing
    }

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

    func printDebug(header: Bool = true) {
        if header {
            print("=== Environment Debug Output (most inner scope last) ===")
        }

        if let enclosing = enclosing {
            enclosing.printDebug(header: false)
        }

        print("--- Environment ---")
        print("Variables: ")
        for (variable, value) in variables {
            print("\t\"\(variable)\": \(value.description)")
        }
    }
}
