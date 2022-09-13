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
        env.set(function: "abs", value: BuiltInFunctionObj(name: "abs", params: [], returnType: IntType(), function: absIntegerMethod))
        env.set(function: "toBool", value: BuiltInFunctionObj(name: "toBool", params: [], returnType: BoolType(), function: intToBoolBuiltIn))
        env.set(function: "toFloat", value: BuiltInFunctionObj(name: "toFloat", params: [], returnType: FloatType(), function: intToFloatBuiltIn))
        env.set(function: "toString", value: BuiltInFunctionObj(name: "toString", params: [], returnType: StringType(), function: intToStrBuiltIn))
        return env
    }

    static func getGenericEnv(type: IntType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let ndict = ClassTypeScope(copy: old)

        return ndict
    }

    private static func absIntegerMethod(params _: [MooseObject], _ env: Environment) throws -> MooseObject {
        let int: IntegerObj = try classEnvToObj(env)
        return try absBuiltIn([int], env)
    }

    private static func intToBoolBuiltIn(params _: [MooseObject], _ env: Environment) throws -> BoolObj {
        let int: IntegerObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = int.value else {
            return BoolObj(value: nil)
        }

        return BoolObj(value: value == 0 ? false : true)
    }

    private static func intToFloatBuiltIn(params _: [MooseObject], _ env: Environment) throws -> FloatObj {
        let int: IntegerObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = int.value else {
            return FloatObj(value: nil)
        }

        return FloatObj(value: Float64(value))
    }

    private static func intToStrBuiltIn(params _: [MooseObject], _ env: Environment) throws -> StringObj {
        let int: IntegerObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = int.value else {
            return StringObj(value: nil)
        }

        return StringObj(value: String(value))
    }
}

/// Float Environment Creation
extension BuiltIns {
    static let builtIn_Float_Env: BaseEnvironment = createFloatEnv()

    private static func createFloatEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        env.set(function: "abs", value: BuiltInFunctionObj(name: "abs", params: [], returnType: FloatType(), function: absFloatMethod))
        env.set(function: "toInt", value: BuiltInFunctionObj(name: "toInt", params: [], returnType: IntType(), function: floatToIntBuiltIn))
        env.set(function: "toString", value: BuiltInFunctionObj(name: "toString", params: [], returnType: StringType(), function: floatToStrBuiltIn))
        return env
    }

    static func getGenericEnv(type: FloatType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let ndict = ClassTypeScope(copy: old)

        return ndict
    }

    private static func absFloatMethod(params _: [MooseObject], _ env: Environment) throws -> MooseObject {
        let float: FloatObj = try classEnvToObj(env)
        return try absBuiltIn([float], env)
    }

    private static func floatToIntBuiltIn(params _: [MooseObject], _ env: Environment) throws -> IntegerObj {
        let float: FloatObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = float.value else {
            return IntegerObj(value: nil)
        }

        return IntegerObj(value: Int64(value))
    }

    private static func floatToStrBuiltIn(params _: [MooseObject], _ env: Environment) throws -> StringObj {
        let float: FloatObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = float.value else {
            return StringObj(value: nil)
        }

        return StringObj(value: String(value))
    }
}

/// Bool Environment Creation
extension BuiltIns {
    static let builtIn_Bool_Env: BaseEnvironment = createBoolEnv()

    private static func createBoolEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        env.set(function: "toInt", value: BuiltInFunctionObj(name: "toInt", params: [], returnType: IntType(), function: boolToIntBuiltIn))
        env.set(function: "toFloat", value: BuiltInFunctionObj(name: "toFloat", params: [], returnType: FloatType(), function: boolToFloatBuiltIn))
        env.set(function: "toString", value: BuiltInFunctionObj(name: "toString", params: [], returnType: StringType(), function: boolToStrBuiltIn))
        return env
    }

    static func getGenericEnv(type: BoolType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let ndict = ClassTypeScope(copy: old)

        return ndict
    }

    private static func boolToIntBuiltIn(params _: [MooseObject], _ env: Environment) throws -> IntegerObj {
        let bool: BoolObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = bool.value else {
            return IntegerObj(value: nil)
        }

        return IntegerObj(value: value ? 1 : 0)
    }

    private static func boolToFloatBuiltIn(params _: [MooseObject], _ env: Environment) throws -> FloatObj {
        let bool: BoolObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = bool.value else {
            return FloatObj(value: nil)
        }

        return FloatObj(value: value ? 1.0 : 0.0)
    }

    private static func boolToStrBuiltIn(params _: [MooseObject], _ env: Environment) throws -> StringObj {
        let bool: BoolObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        guard let value = bool.value else {
            return StringObj(value: nil)
        }

        return StringObj(value: value ? "true" : "false")
    }
}

/// String Environment Creation
extension BuiltIns {
    static let builtIn_String_Env: BaseEnvironment = createStringEnv()

    private static func createStringEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        env.set(function: "length", value: BuiltInFunctionObj(name: "length", params: [], returnType: StringType(), function: lengthString))
        env.set(function: Settings.GET_ITEM_FUNCTIONNAME, value: BuiltInFunctionObj(name: Settings.GET_ITEM_FUNCTIONNAME, params: [IntType()], returnType: StringType(), function: getItemString))
        env.set(function: "parseInt", value: BuiltInFunctionObj(name: "parseInt", params: [], returnType: TupleType([IntType(), StringType()]), function: strToIntBuiltIn))
        env.set(function: "parseFloat", value: BuiltInFunctionObj(name: "parseFloat", params: [], returnType: TupleType([FloatType(), StringType()]), function: strToFloatBuiltIn))
        env.set(function: "parseBool", value: BuiltInFunctionObj(name: "parseBool", params: [], returnType: TupleType([BoolType(), StringType()]), function: strToBoolBuiltIn))
        return env
    }

    static func getGenericEnv(type: StringType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let ndict = ClassTypeScope(copy: old)

        return ndict
    }

    private static func lengthString(params _: [MooseObject], env: Environment) throws -> MooseObject {
        let obj: StringObj = try classEnvToObj(env)
        try assertNoNil(obj)

        return IntegerObj(value: Int64(obj.value!.count))
    }

    private static func getItemString(params: [MooseObject], env: Environment) throws -> MooseObject {
        let key = params[0] as! IntegerObj
        try assertNoNil(params)

        let obj: StringObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let value = obj.value!
        guard value.count > key.value! else {
            throw RuntimeError(message: "Array Access Error: String has a length of \(value.count) but you want to access \(key.value!).")
        }

        let index = Int(key.value!)
        let char = value[index]
        return StringObj(value: String(char))
    }

    private static func strToIntBuiltIn(params _: [MooseObject], _ env: Environment) throws -> TupleObj {
        let bool: StringObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let type = TupleType([FloatType(), StringType()])

        guard let input = bool.value else {
            return TupleObj(type: type, value: [IntegerObj(value: nil), StringObj(value: nil)])
        }

        var errMsg: String?
        let value = Int64(input)
        if value == nil {
            errMsg = "Cannot parse '\(input)' to an Int."
        }

        return TupleObj(type: type, value: [IntegerObj(value: value), StringObj(value: errMsg)])
    }

    private static func strToFloatBuiltIn(params _: [MooseObject], _ env: Environment) throws -> TupleObj {
        let bool: StringObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let type = TupleType([FloatType(), StringType()])

        guard let input = bool.value else {
            return TupleObj(type: type, value: [FloatObj(value: nil), StringObj(value: nil)])
        }

        var errMsg: String?
        let value = Float64(input)
        if value == nil {
            errMsg = "Cannot parse '\(input)' to an Float."
        }

        return TupleObj(type: type, value: [FloatObj(value: value), StringObj(value: errMsg)])
    }

    private static func strToBoolBuiltIn(params _: [MooseObject], _ env: Environment) throws -> TupleObj {
        let bool: StringObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let type = TupleType([BoolType(), StringType()])

        guard let input = bool.value else {
            return TupleObj(type: type, value: [BoolObj(value: nil), StringObj(value: nil)])
        }

        var errMsg: String?
        let value = Bool(input)
        if value == nil {
            errMsg = "Cannot parse '\(input)' to an Bool."
        }

        return TupleObj(type: type, value: [BoolObj(value: value), StringObj(value: errMsg)])
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

    static func getGenericEnv(type: FunctionType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let ndict = ClassTypeScope(copy: old)

        return ndict
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
        env.set(function: "represent", value: BuiltInFunctionObj(name: "represent", params: [], returnType: StringType(), function: representTuple))
        return env
    }

    static func getGenericEnv(type: TupleType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let inferred = ClassTypeScope(copy: old)

        // add access properties
        for (i, t) in type.entries.enumerated() {
            try inferred.add(variable: "\(i)", type: t, mutable: true)
        }

        return inferred
    }

    private static func representTuple(params _: [MooseObject], env: Environment) throws -> StringObj {
        let obj: TupleObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let valStrs = try obj.value!.map {
            try representAny(obj: $0)
        }.joined(separator: ", ")

        return StringObj(value: "(\(valStrs))")
    }
}

/// List Environment Creation
extension BuiltIns {
    static let builtIn_List_Env: BaseEnvironment = createListEnv()

    private static func createListEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        env.set(function: "length", value: BuiltInFunctionObj(name: "length", params: [], returnType: IntType(), function: listLengthImpl))
        env.set(function: "append", value: BuiltInFunctionObj(name: "append", params: [ParamType()], returnType: VoidType(), function: appendList))
        env.set(function: "append", value: BuiltInFunctionObj(name: "append", params: [ListType(ParamType())], returnType: VoidType(), function: appendList))
        env.set(function: "reverse", value: BuiltInFunctionObj(name: "reverse", params: [], returnType: VoidType(), function: reverseList))
        env.set(function: "reversed", value: BuiltInFunctionObj(name: "reversed", params: [], returnType: ParamType(), function: reversedList))
        env.set(function: "enumerated", value: BuiltInFunctionObj(name: "enumerated", params: [], returnType: ParamType(), function: enumeratedList))
        env.set(function: "represent", value: BuiltInFunctionObj(name: "represent", params: [], returnType: StringType(), function: representList))
        env.set(function: Settings.GET_ITEM_FUNCTIONNAME, value: BuiltInFunctionObj(name: Settings.GET_ITEM_FUNCTIONNAME, params: [IntType()], returnType: ParamType(), function: getItemList))
        env.set(function: Settings.SET_ITEM_FUNCTIONNAME, value: BuiltInFunctionObj(name: Settings.SET_ITEM_FUNCTIONNAME, params: [IntType(), ParamType()], returnType: VoidType(), function: setItemList))

        env.set(function: "min", value: BuiltInFunctionObj(name: "min", params: [], returnType: NumericType(), function: minList))
        env.set(function: "max", value: BuiltInFunctionObj(name: "max", params: [], returnType: NumericType(), function: maxList))
        return env
    }

    static func getGenericEnv(type: ListType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let ndict = ClassTypeScope(copy: old)

        try ndict.replace(function: "append", with: [ParamType()], by: FunctionType(params: [type.type], returnType: VoidType()))
        try ndict.replace(function: "append", with: [ListType(ParamType())], by: FunctionType(params: [ListType(type.type)], returnType: VoidType()))
        try ndict.replace(function: "reversed", with: [], by: FunctionType(params: [], returnType: type))
        try ndict.replace(function: "enumerated", with: [], by: FunctionType(params: [], returnType: ListType(TupleType([IntType(), type.type]))))
        try ndict.replace(function: Settings.GET_ITEM_FUNCTIONNAME, with: [IntType()], by: FunctionType(params: [IntType()], returnType: type.type))
        try ndict.replace(function: Settings.SET_ITEM_FUNCTIONNAME, with: [IntType(), ParamType()], by: FunctionType(params: [IntType(), type.type], returnType: VoidType()))

        try ndict.replace(function: "min", with: [], by: FunctionType(params: [], returnType: type.type))
        try ndict.replace(function: "max", with: [], by: FunctionType(params: [], returnType: type.type))

        return ndict
    }

    private static func listLengthImpl(params _: [MooseObject], _ env: Environment) throws -> MooseObject {
        let list: ListObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        return IntegerObj(value: Int64(list.length()))
    }

    private static func appendList(params: [MooseObject], env: Environment) throws -> MooseObject {
        let obj: ListObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value
            .cast()

        try assertNoNil(obj)

        if let list = params[0] as? ListObj {
            try assertNoNil(list)
            obj.value!.append(contentsOf: list.value!)
        } else {
            obj.value!.append(params[0])
        }

        return VoidObj()
    }

    private static func reverseList(params _: [MooseObject], env: Environment) throws -> VoidObj {
        let obj: ListObj = try classEnvToObj(env)
        try assertNoNil(obj)
        obj.value?.reverse()
        return VoidObj()
    }

    private static func reversedList(params _: [MooseObject], env: Environment) throws -> ListObj {
        let obj: ListObj = try classEnvToObj(env)
        try assertNoNil(obj)

        let newList: [MooseObject]? = obj.value?.reversed()
        return ListObj(type: obj.type, value: newList)
    }

    private static func enumeratedList(params _: [MooseObject], env: Environment) throws -> MooseObject {
        let obj: ListObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value
            .cast()

        try assertNoNil(obj)
        let tupleType = TupleType([IntType(), (obj.type as! ListType).type])
        let enumList = obj.value!.enumerated().map { TupleObj(type: tupleType, value: [IntegerObj(value: Int64($0.offset)), $0.element]) }
        return ListObj(type: ListType(tupleType), value: enumList)
    }

    private static func getItemList(params: [MooseObject], env: Environment) throws -> MooseObject {
        let key = params[0] as! IntegerObj
        try assertNoNil(params)

        let obj: ListObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        // if arr[-1] than return last item
        let index = key.value! < 0 ? obj.length() + key.value! : key.value!

        guard obj.length() > index, index >= 0 else {
            throw OutOfBoundsPanic(length: obj.length(), attemptedIndex: index)
        }

        return obj.getAt(index: index)
    }

    private static func setItemList(params: [MooseObject], env: Environment) throws -> VoidObj {
        let key = (params[0] as! IntegerObj)
        try assertNoNil([key])

        let obj: ListObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let index = key.value! < 0 ? obj.length() + key.value! : key.value!
        guard obj.length() > index, index >= 0 else {
            throw OutOfBoundsPanic(length: obj.length(), attemptedIndex: index)
        }

        obj.setAt(index: key.value!, value: params[1])
        return VoidObj()
    }

    private static func representList(params _: [MooseObject], env: Environment) throws -> StringObj {
        let obj: ListObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let valStrs = try obj.value!.map {
            try representAny(obj: $0)
        }.joined(separator: ", ")

        return StringObj(value: "[\(valStrs)]")
    }

    private static func minList(params: [MooseObject], env: Environment) throws -> MooseObject {
        try assertNoNil(params)
        let obj: ListObj = try classEnvToObj(env)
        return try minBuiltIn(obj.value!, env)
    }

    private static func maxList(params: [MooseObject], env: Environment) throws -> MooseObject {
        try assertNoNil(params)
        let obj: ListObj = try classEnvToObj(env)
        return try maxBuiltIn(obj.value!, env)
    }
}

/// Dict Environment Creation
extension BuiltIns {
    static let builtIn_Dict_Env: BaseEnvironment = createDictEnv()

    private static func createDictEnv() -> BaseEnvironment {
        let env = BaseEnvironment(enclosing: nil)
        env.set(function: "represent", value: BuiltInFunctionObj(name: "represent", params: [], returnType: StringType(), function: representDict))
        env.set(function: "length", value: BuiltInFunctionObj(name: "length", params: [], returnType: IntType(), function: lengthDict))
        env.set(function: "flat", value: BuiltInFunctionObj(name: "flat", params: [], returnType: ParamType(), function: flatDict))
        env.set(function: Settings.GET_ITEM_FUNCTIONNAME, value: BuiltInFunctionObj(name: Settings.GET_ITEM_FUNCTIONNAME, params: [ParamType()], returnType: ParamType(), function: getItemDict))
        env.set(function: Settings.SET_ITEM_FUNCTIONNAME, value: BuiltInFunctionObj(name: Settings.SET_ITEM_FUNCTIONNAME, params: [ParamType(), ParamType()], returnType: VoidType(), function: setItemDict))

        return env
    }

    static func getGenericEnv(type: DictType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        let ndict = ClassTypeScope(copy: old)

        // generic indexing
        try ndict.replace(function: "flat", with: [], by: FunctionType(params: [], returnType: ListType(TupleType([type.keyType, type.valueType]))))
        try ndict.replace(function: Settings.GET_ITEM_FUNCTIONNAME, with: [ParamType()], by: FunctionType(params: [type.keyType], returnType: type.valueType))
        try ndict.replace(function: Settings.SET_ITEM_FUNCTIONNAME, with: [ParamType(), ParamType()], by: FunctionType(params: [type.keyType, type.valueType], returnType: VoidType()))

        return ndict
    }

    private static func lengthDict(params _: [MooseObject], env: Environment) throws -> IntegerObj {
        let obj: DictObj = try classEnvToObj(env)
        try assertNoNil(obj)
        return IntegerObj(value: Int64(obj.pairs!.count))
    }

    private static func flatDict(params _: [MooseObject], env: Environment) throws -> ListObj {
        let obj: DictObj = try classEnvToObj(env)
        try assertNoNil(obj)

        let dictType = obj.type as! DictType

        let tupleType = TupleType([dictType.keyType, dictType.valueType])
        let list = obj.pairs!.map { TupleObj(type: tupleType, value: [$0.key, $0.value]) }
        return ListObj(type: ListType(tupleType), value: list)
    }

    private static func representDict(params _: [MooseObject], env: Environment) throws -> MooseObject {
        let obj: DictObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        let valStrs = try obj.pairs!.map {
            "\(try representAny(obj: $0.key)): \(try representAny(obj: $0.value))"
        }.joined(separator: ", ")

        return StringObj(value: "{\(valStrs)}")
    }

    private static func getItemDict(params: [MooseObject], env: Environment) throws -> MooseObject {
        let key = params[0]
        let obj: DictObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        return obj.getAt(key: key)
    }

    private static func setItemDict(params: [MooseObject], env: Environment) throws -> VoidObj {
        let key = params[0]
        try assertNoNil([key])

        let obj: DictObj = try env
            .cast(to: BuiltInClassEnvironment.self)
            .value.cast()

        obj.setAt(key: key, val: params[1])
        return VoidObj()
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

    static func getGenericEnv(type: NilType) throws -> ClassTypeScope {
        guard let className = type.asClass?.name, let old = TypeScope.global.getScope(clas: className) else {
            fatalError("INTERNAL ERROR: Requested Builtin type \(type.asClass?.name ?? "Unknown") from global scope, but it does not exist.")
        }
        return old
    }

    static func classEnvToObj<T>(_ env: Environment) throws -> T where T: MooseObject {
        return try env.cast(to: BuiltInClassEnvironment.self)
            .value.cast()
    }
}

/// This class wraps the environment of a builtin class
/// and its own mooseObject
///
/// We use this, so we can create new value instances without coping the whole environment
class BuiltInClassEnvironment: Environment {
    let env: BaseEnvironment
    var value: MooseObject!

    init(env: BaseEnvironment) {
        self.env = env
    }

    init(env: BaseEnvironment, value: MooseObject) {
        self.env = env
        self.value = value
    }

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

    func has(function: String, params: [MooseType]) -> Bool {
        env.has(function: function, params: params)
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

    func global() -> Environment {
        env.global()
    }

    var enclosing: Environment? {
        return env.enclosing
    }

    func printDebug(header _: Bool) {
        env.printDebug()
    }
}

///// This is a special environment, since it has to incept variable calls
///// because it has builtin class properties
class BuiltinTupleEnv: BuiltInClassEnvironment {
    private var this: TupleObj { value as! TupleObj }

    private func propIndex(variable: String) -> Int? {
        let props = (0 ..< this.value!.count).map { "\($0)" }
        return props.firstIndex(of: variable)
    }

    override func update(variable: String, value: MooseObject, allowDefine: Bool) -> Bool {
        if let valIndex = propIndex(variable: variable) {
            this.value![valIndex] = value
            return true
        }

        return super.update(variable: variable, value: value, allowDefine: allowDefine)
    }

    override func updateInCurrentEnv(variable: String, value: MooseObject, allowDefine: Bool) -> Bool {
        if let valIndex = propIndex(variable: variable) {
            this.value![valIndex] = value
            return true
        }

        return super.updateInCurrentEnv(variable: variable, value: value, allowDefine: allowDefine)
    }

    override func get(variable: String) throws -> MooseObject {
        if let valIndex = propIndex(variable: variable) {
            return this.value![valIndex]
        }

        return try super.get(variable: variable)
    }

    override func getAllVariables() -> [String: MooseObject] {
        var vars = super.getAllVariables()
        for (i, v) in this.value!.enumerated() {
            vars["\(i)"] = v
        }
        return vars
    }
}
