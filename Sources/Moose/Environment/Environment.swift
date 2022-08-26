//
//  Created by flofriday on 08.08.2022
//

protocol Environment {
    func update(variable: String, value: MooseObject, allowDefine: Bool) -> Bool
    func updateInCurrentEnv(variable: String, value: MooseObject, allowDefine: Bool) -> Bool
    func get(variable: String) throws -> MooseObject
    func getAllVariables() -> [String: MooseObject]

    func set(function: String, value: MooseObject)
    func get(function: String, params: [MooseType]) throws -> MooseObject

    func set(op: String, value: MooseObject)
    func get(op: String, pos: OpPos, params: [MooseType]) throws -> MooseObject

    func set(clas: String, env: ClassEnvironment)
    func get(clas: String) throws -> ClassEnvironment
    func nearestClass() throws -> ClassEnvironment

    func isGlobal() -> Bool
    func global() -> Environment
    var enclosing: Environment? { get }

    var closed: Bool { get set }

    func printDebug(header: Bool)
}

extension Environment {
    func cast<T: Environment>(to type: T.Type) throws -> T {
        guard let env = self as? T else {
            throw EnvironmentError(message: "Could not cast environment to \(type).")
        }
        return env
    }
}

// This is the implementation of the environments that manage the life of
// variables, functions, classes etc.
//
// Note about this implementation: This implementation is very liberal, and
// doesn't check many errors. For example we don't validate types here.
// We can do this because the typechecker will always be run before this so we
// can assume here that the programs we see are well typed. And even if they
// weren't it wouldn't be our concern but a bug in the typechecker.
class BaseEnvironment: Environment {
    var enclosing: Environment?
    var closed: Bool = false
    var variables: [String: MooseObject] = [:]
    var funcs: [String: [MooseObject]] = [:]
    var ops: [String: [MooseObject]] = [:]

    var classDefinitions: [String: ClassEnvironment] = [:]

    init(enclosing: Environment?) {
        self.enclosing = enclosing
    }

    init(copy: BaseEnvironment) {
        variables = copy.variables
        funcs = copy.funcs
        ops = copy.ops
        classDefinitions = copy.classDefinitions
        enclosing = copy.enclosing
    }
}

// The variable handling
extension BaseEnvironment {
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
        if let enclosing = enclosing, !closed {
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

    func updateInCurrentEnv(variable: String, value: MooseObject, allowDefine: Bool = true) -> Bool {
        // Update if in current env
        if variables[variable] != nil {
            variables.updateValue(value, forKey: variable)
            return true
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

        if let enclosing = enclosing, !closed {
            return try enclosing.get(variable: variable)
        } else {
            throw EnvironmentError(message: "Variable '\(variable)' not found.")
        }
    }

    func getInCurrentEnv(variable: String) throws -> MooseObject {
        if let obj = variables[variable] {
            return obj
        }

        throw EnvironmentError(message: "Variable '\(variable)' not found.")
    }

    // Return all variables.
    func getAllVariables() -> [String: MooseObject] {
        return variables
    }
}

// Define all function operations
extension BaseEnvironment {
    private func isFuncBy(params: [MooseType], other: MooseType) -> Bool {
        guard
            let storedParams = (other as? FunctionType)?.params
        else {
            return false
        }

        return TypeScope.leftSuperOfRight(supers: storedParams, subtypes: params)
    }

    func set(function: String, value: MooseObject) {
        if funcs[function] == nil {
            funcs[function] = []
        }

        funcs[function]!.append(value)
    }

    func get(function: String, params: [MooseType]) throws -> MooseObject {
        if let objs = funcs[function]?
            .filter({ isFuncBy(params: params, other: $0.type) })
        {
            if objs.count > 1 {
                throw ScopeError(message: "Multiple possible functions of `\(function)` with params (\(params.map { $0.description }.joined(separator: ","))). You have to give more context to the function call.")
            }
            if objs.count == 1 {
                return objs.first!
            }
        }

        guard let enclosing = enclosing, !closed else {
            throw EnvironmentError(message: "Function '\(function)' not found.")
        }
        return try enclosing.get(function: function, params: params)
    }

    func getInCurrentEnv(function: String, params: [MooseType]) throws -> MooseObject {
        if let objs = funcs[function]?
            .filter({ isFuncBy(params: params, other: $0.type) })
        {
            if objs.count > 1 {
                throw ScopeError(message: "Multiple possible functions of `\(function)` with params (\(params.map { $0.description }.joined(separator: ","))). You have to give more context to the function call.")
            }
            if objs.count == 1 {
                return objs.first!
            }
        }
        throw EnvironmentError(message: "Function '\(function)' not found.")
    }
}

// Define all function operations
extension BaseEnvironment {
    private func isOpBy(pos: OpPos, params: [MooseType], other: MooseObject) -> Bool {
        if let obj = other as? BuiltInOperatorObj {
            return obj.opPos == pos && obj.params == params
        }

        if let obj = other as? OperatorObj, obj.opPos == pos {
            return true
        }
        return false
    }

    func set(op: String, value: MooseObject) {
        if ops[op] == nil {
            ops[op] = []
        }

        ops[op]!.append(value)
    }

    func get(op: String, pos: OpPos, params: [MooseType]) throws -> MooseObject {
        if let obj = ops[op]?.first(where: { isOpBy(pos: pos, params: params, other: $0) }) {
            return obj
        }
        guard let enclosing = enclosing, !closed else {
            throw EnvironmentError(message: "Operation '\(op)' not found.")
        }
        return try enclosing.get(op: op, pos: pos, params: params)
    }
}

// Define all function for classes
extension BaseEnvironment {
    func set(clas: String, env: ClassEnvironment) {
        classDefinitions[clas] = env
    }

    func get(clas: String) throws -> ClassEnvironment {
        guard let env = classDefinitions[clas] else {
            throw EnvironmentError(message: "Class `\(clas)` not found.")
        }

        return env
    }

    func nearestClass() throws -> ClassEnvironment {
        guard let env = self as? ClassEnvironment else {
            guard let enclosing = enclosing, !closed else {
                throw EnvironmentError(message: "Not inside a class object.")
            }
            return try enclosing.nearestClass()
        }
        return env
    }
}

// Some helper functions
extension BaseEnvironment {
    func isGlobal() -> Bool {
        return enclosing == nil && !closed
    }

    // Return the global environment
    func global() -> Environment {
        guard let enclosing = enclosing, !closed else {
            return self
        }

        return enclosing.global()
    }

    /// Defines the type of builtin class scope
    ///
    /// Note that it will not transfer any operators (of course)
    func asClassTypeScope(_ name: String, props: [(name: String, type: MooseType, mutable: Bool)] = []) throws -> ClassTypeScope {
        let scope = ClassTypeScope(enclosing: nil, name: name, properties: props)

        let funcs = try funcs.flatMap { try $0.value.map { fn -> BuiltInFunctionObj in
            guard let builtInFn = fn as? BuiltInFunctionObj else {
                throw EnvironmentError(message: "Try to map non builtIn function. Only builtIn Functions are allowed here.")
            }
            return builtInFn
        }
        }

        for fn in funcs {
            try scope.add(function: fn.name, params: fn.params, returnType: fn.returnType)
        }
        return scope
    }
}

// Debug functions to get a better look into what the current environment is
// doing
extension BaseEnvironment {
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
        print("closed: \(closed)")
        print("Variables: ")
        for (variable, value) in variables {
            print("\t\(variable): \(value.type.description) = \(value.description)")
        }
        if variables.isEmpty {
            print("\t<empty>")
        }

        print("Functions: ")
        for (function, values) in funcs {
            for value in values {
                print("\t\(function) = \(value.description)")
            }
        }
        if funcs.isEmpty {
            print("\t<empty>")
        }

        print("Operators: ")
        for (op, values) in ops {
            for value in values {
                print("\t\(op) = \(value.description)")
            }
        }
        if ops.isEmpty {
            print("\t<empty>")
        }

        print("Classes: ")
        for (_, value) in classDefinitions {
            print("\t\(value.className)")
        }
        if classDefinitions.isEmpty {
            print("\t<empty>")
        }
        print()
    }
}

class ClassEnvironment: BaseEnvironment {
    let propertyNames: [String]
    let className: String
    var superClass: ClassEnvironment?

    init(enclosing: Environment?, className: String, propertyNames: [String]) {
        self.propertyNames = propertyNames
        self.className = className
        super.init(enclosing: enclosing)
    }

    init(copy: ClassEnvironment) {
        propertyNames = copy.propertyNames
        className = copy.className
        super.init(copy: copy)
    }

    /// So the methods need to work in this environment, which is bound to a
    /// specific object and not to a class. So here, we need to inject ourself
    /// into each method.
    func bindMethods() {
        for meths in funcs {
            for meth in meths.value {
                (meth as! FunctionObj).closure = self
            }
        }
    }
}
