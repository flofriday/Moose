//
//  File.swift
//
//
//  Created by Johannes Zottele on 17.08.22.
//

import Foundation

/// Integer Environment Creation
extension BuiltIns {
    static let builtIn_Integer_Env: BaseEnvironment = createIntegerEnv()

    private static func createIntegerEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// Float Environment Creation
extension BuiltIns {
    static let builtIn_Float_Env: BaseEnvironment = createFloatEnv()

    private static func createFloatEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// Bool Environment Creation
extension BuiltIns {
    static let builtIn_Bool_Env: BaseEnvironment = createBoolEnv()

    private static func createBoolEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// String Environment Creation
extension BuiltIns {
    static let builtIn_String_Env: BaseEnvironment = createStringEnv()

    private static func createStringEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// Function Environment Creation
extension BuiltIns {
    static let builtIn_Function_Env: BaseEnvironment = createFunctionEnv()

    private static func createFunctionEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// BuiltInFunction Environment Creation
extension BuiltIns {
    static let builtIn_BuiltInFunction_Env: BaseEnvironment = createBuiltInFunctionEnv()

    private static func createBuiltInFunctionEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// Opterator Environment Creation
extension BuiltIns {
    static let builtIn_Operator_Env: BaseEnvironment = createOperatorEnv()

    private static func createOperatorEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// BuiltInOperator Environment Creation
extension BuiltIns {
    static let builtIn_BuiltInOperator_Env: BaseEnvironment = createBuiltInOperatorEnv()

    private static func createBuiltInOperatorEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// Tuple Environment Creation
extension BuiltIns {
    static let builtIn_Tuple_Env: BaseEnvironment = createTupleEnv()

    private static func createTupleEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// List Environment Creation
extension BuiltIns {
    static let builtIn_List_Env: BaseEnvironment = createListEnv()

    private static func createListEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        env.set(function: "length", value: BuiltInFunctionObj(name: "length", params: [], returnType: IntType(), function: listLengthImpl))
        return env
    }

    private static func listLengthImpl(params _: [MooseObject], _ env: Environment) throws -> MooseObject {
        let list: ListObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        return IntegerObj(value: Int64(list.length()))
    }
}

/// Void Environment Creation
extension BuiltIns {
    static let builtIn_Void_Env: BaseEnvironment = createVoidEnv()

    private static func createVoidEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// Nil Environment Creation
extension BuiltIns {
    static let builtIn_Nil_Env: BaseEnvironment = createNilEnv()

    private static func createNilEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        return env
    }
}

/// This struct wraps the environment of a builtin class
/// and its own mooseObject
///
/// It is a struct so we can change the value without coping the class all the time and use a single environment for all builtin
/// class objects.
struct BuiltInClassEnvironment: Environment {
    let env: BaseEnvironment
    var value: MooseObject!

    func update(variable: String, value: MooseObject, allowDefine: Bool) -> Bool {
        env.update(variable: variable, value: value, allowDefine: allowDefine)
    }

    func updateInCurrentEnv(variable: String, value: MooseObject, allowDefine: Bool) -> Bool {
        env.updateInCurrentEnv(variable: variable, value: value, allowDefine: allowDefine)
    }

    func get(variable: String) throws -> MooseObject {
        try env.get(variable: variable)
    }

    func getAllVariables() -> [String: MooseObject] {
        env.getAllVariables()
    }

    func set(function: String, value: MooseObject) {
        env.set(function: function, value: value)
    }

    func get(function: String, params: [MooseType]) throws -> MooseObject {
        try env.get(function: function, params: params)
    }

    func set(op: String, value: MooseObject) {
        env.set(op: op, value: value)
    }

    func get(op: String, pos: OpPos, params: [MooseType]) throws -> MooseObject {
        try env.get(op: op, pos: pos, params: params)
    }

    func set(clas: String, env: ClassEnvironment) {
        env.set(clas: clas, env: env)
    }

    func get(clas: String) throws -> ClassEnvironment {
        try env.get(clas: clas)
    }

    func nearestClass() throws -> ClassEnvironment {
        try env.nearestClass()
    }

    func isGlobal() -> Bool {
        env.isGlobal()
    }

    var enclosing: Environment? {
        return env.enclosing
    }

    func printDebug(header _: Bool) {
        env.printDebug()
    }
}
