//
//  MooseObject.swift
//
//
//  Created by Johannes Zottele on 28.06.22.
//

import Foundation

protocol MooseObject: CustomStringConvertible {
    var type: MooseType { get }
    var description: String { get }
    var env: BuiltInClassEnvironment { get }

    var isNil: Bool { get }
    func equals(other: MooseObject) -> Bool
}

extension MooseObject {
    func cast<T: MooseObject>() throws -> T {
        guard let obj = self as? T else {
            throw EnvironmentError(message: "Could not object to \(type).")
        }
        return obj
    }

    func cast<T: MooseObject>(to type: T.Type) throws -> T {
        guard let obj = self as? T else {
            throw EnvironmentError(message: "Could not object to \(type).")
        }
        return obj
    }
}

func == <T: MooseObject>(lhs: T, rhs: T) -> Bool {
    return lhs.equals(other: rhs)
}

protocol HashableObject: Hashable, MooseObject {}

protocol IndexableObject: MooseObject {
    func getAt(index: Int64) -> MooseObject
    func length() -> Int64
}

protocol IndexWriteableObject: IndexableObject {
    func setAt(index: Int64, value: MooseObject)
}

protocol NumericObj: HashableObject {
    associatedtype T where T: Comparable
    var value: T? { get }
}

class IntegerObj: NumericObj {
    let type: MooseType = IntType()
    let value: Int64?
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Integer_Env)

    init(value: Int64?) {
        self.value = value
        env.value = self
    }

    var isNil: Bool { return value == nil }
    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        hasher.combine(value)
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }
}

class FloatObj: NumericObj {
    let type: MooseType = FloatType()
    let value: Float64?
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Float_Env)

    init(value: Float64?) {
        self.value = value
        env.value = self
    }

    var isNil: Bool { return value == nil }
    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        hasher.combine(value)
    }
}

class BoolObj: MooseObject, HashableObject {
    let type: MooseType = BoolType()
    let value: Bool?
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Bool_Env)

    init(value: Bool?) {
        self.value = value
        env.value = self
    }

    var isNil: Bool { return value == nil }
    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        hasher.combine(value)
    }
}

class StringObj: MooseObject, HashableObject {
    let type: MooseType = StringType()
    let value: String?
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_String_Env)

    init(value: String?) {
        self.value = value
        env.value = self
    }

    var isNil: Bool { return value == nil }
    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    var description: String {
        if let description = value?.description {
            return """
            "\(description)"
            """
        }
        return "nil"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        hasher.combine(value)
    }
}

class FunctionObj: MooseObject {
    let name: String
    let type: MooseType
    let paramNames: [String]
    let value: BlockStatement
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Function_Env)
    var closure: Environment

    var isNil: Bool { return false }
    init(name: String, type: MooseType, paramNames: [String], value: BlockStatement, closure: Environment) {
        self.name = name
        self.type = type
        self.paramNames = paramNames
        self.value = value
        self.closure = closure
        env.value = self
    }

    /// This constructor copies a given FunctionObj object
    ///
    /// This is required when initializing a MooseClass since
    /// the closure has to be updated to the specific object
    init(copy: FunctionObj) {
        self.name = copy.name
        self.type = copy.type
        self.paramNames = copy.paramNames
        self.value = copy.value
        self.closure = copy.closure
        env.value = self
    }

    func equals(other _: MooseObject) -> Bool {
        // Functions can never be equal
        return false
    }

    var description: String {
        return "<func \(name): \(type.description)>"
    }
}

class BuiltInFunctionObj: MooseObject {
    typealias fnType = ([MooseObject], Environment) throws -> MooseObject

    let name: String
    let params: [ParamType]
    let returnType: MooseType
    let type: MooseType
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_BuiltInFunction_Env)

    let function: fnType

    init(name: String, params: [ParamType], returnType: MooseType, function: @escaping fnType) {
        self.name = name
        self.params = params
        self.returnType = returnType
        self.type = FunctionType(params: params, returnType: returnType)
        self.function = function
        env.value = self
    }

    var isNil: Bool { false }
    func equals(other _: MooseObject) -> Bool {
        // Functions can never be equal
        return false
    }

    var description: String {
        return "<built-in func \(name): \(type.description)>"
    }
}

class OperatorObj: FunctionObj {
    let opPos: OpPos

    init(name: String, opPos: OpPos, type: MooseType, paramNames: [String], value: BlockStatement, closure: Environment) {
        self.opPos = opPos
        super.init(name: name, type: type, paramNames: paramNames, value: value, closure: closure)
        env.value = self
    }

    override var description: String {
        return "<\(opPos) operation \(name): \(type.description)>"
    }
}

class BuiltInOperatorObj: BuiltInFunctionObj {
    let opPos: OpPos

    init(name: String, opPos: OpPos, params: [ParamType], returnType: MooseType, function: @escaping fnType) {
        self.opPos = opPos
        super.init(name: name, params: params, returnType: returnType, function: function)
//        env = .init(BuiltIns.builtIn_BuiltInOperator_Env
        env.value = self
    }

    override var description: String {
        return "<built-in \(opPos) operation \(name): \(type.description)>"
    }
}

class TupleObj: MooseObject, IndexableObject, IndexWriteableObject, HashableObject {
    let type: MooseType
    var value: [MooseObject]?
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Tuple_Env)

    init(type: MooseType, value: [MooseObject]?) {
        self.type = type
        self.value = value
        env.value = self
    }

    func getAt(index: Int64) -> MooseObject {
        return value![Int(index)]
    }

    func setAt(index: Int64, value: MooseObject) {
        self.value![Int(index)] = value
    }

    func length() -> Int64 {
        return Int64(value?.count ?? 0)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        value?.forEach { ($0 as! HashableObject).hash(into: &hasher) }
    }

    var isNil: Bool { value == nil }
    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        // If both values are nil they are equal
        if value == nil, other.value == nil {
            return true
        }

        // Check if only one of them is nil
        guard let value = value, let otherValue = other.value else {
            return false
        }

        guard value.count == otherValue.count else {
            return false
        }

        for (o1, o2) in zip(value, otherValue) {
            guard o1.equals(other: o2) else {
                return false
            }
        }

        return true
    }

    var description: String {
        guard let value = value else {
            return "nil"
        }
        var out = "("
        out += value.map { $0.description }.joined(separator: ", ")
        out += ")"
        return out
    }
}

class ListObj: MooseObject, IndexableObject, IndexWriteableObject, HashableObject {
    let type: MooseType
    var value: [MooseObject]?
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_List_Env)

    init(type: MooseType, value: [MooseObject]?) {
        self.type = type
        self.value = value
        env.value = self
    }

    func getAt(index: Int64) -> MooseObject {
        return value![Int(index)]
    }

    func setAt(index: Int64, value: MooseObject) {
        self.value![Int(index)] = value
    }

    func length() -> Int64 {
        return Int64(value?.count ?? 0)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        value?.forEach { ($0 as! HashableObject).hash(into: &hasher) }
    }

    var isNil: Bool { value == nil }
    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        // If both values are nil they are equal
        if value == nil, other.value == nil {
            return true
        }

        // Check if only one of them is nil
        guard let value = value, let otherValue = other.value else {
            return false
        }

        guard value.count == otherValue.count else {
            return false
        }

        for (o1, o2) in zip(value, otherValue) {
            guard o1.equals(other: o2) else {
                return false
            }
        }

        return true
    }

    var description: String {
        guard let value = value else {
            return "nil"
        }

        var out = "["
        out += value.map { $0.description }.joined(separator: ", ")
        out += "]"
        return out
    }
}

class DictObj: MooseObject, HashableObject {
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Dict_Env)
    let type: MooseType

    // this implmentation is crap af, but since MooseObject does not confirm Hashable we cannot
    // use the MooseObject as key...
    var pairs: [(key: MooseObject, value: MooseObject)]?

    init(type: MooseType, pairs: [(MooseObject, MooseObject)]?) {
        self.type = type
        env.value = self

        guard let pairs = pairs else { return }
        self.pairs = []
        pairs.forEach {
            setAt(key: $0.0, val: $0.1)
        }
    }

    var description: String {
        let pairs = pairs?.map { "\($0.key):\($0.value)" }
        guard let pairs = pairs else { return "nil" }
        return "{\(pairs.joined(separator: ", "))}"
    }

    // TODO: right implementation
    var isNil: Bool {
        return pairs == nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        // smh it is not possible to force cast value and key to Hashable object in the same iteration
        // so we have to do it worse
        pairs?.forEach { ($0.value as! HashableObject).hash(into: &hasher) }
        pairs?.forEach { ($0.key as! HashableObject).hash(into: &hasher) }
    }

    private var dictType: DictType {
        return (type as! DictType)
    }

    func getAt(key: MooseObject) -> MooseObject {
        pairs?.first(where: { $0.key.equals(other: key) })?.value ?? NilObj()
    }

    func setAt(key: MooseObject, val: MooseObject) {
        let index = pairs?.firstIndex(where: { $0.key.equals(other: key) })
        guard let index = index else {
            pairs?.append((key, val))
            return
        }
        pairs?[index].value = val
    }

    func equals(other: MooseObject) -> Bool {
        guard let other = other as? DictObj else { return false }
        guard other.isNil == other.isNil else { return false }
        guard let pairs = pairs else { return true }

        guard
            (TypeScope.rate(subtype: other.dictType, ofSuper: dictType, classExtends: env.global().doesEnvironmentExtend) != nil) ||
            (TypeScope.rate(subtype: dictType, ofSuper: other.dictType, classExtends: env.global().doesEnvironmentExtend) != nil)
        else {
            return false
        }

        guard pairs.count == other.pairs?.count else { return false }

        for (key, value) in pairs {
            let otherVal = other.getAt(key: key)
            guard !(otherVal is NilObj), otherVal.equals(other: value) else { return false }
        }
        return true
    }
}

// TODO: make classes indexable
class ClassObject: MooseObject, HashableObject {
    let classEnv: ClassEnvironment?
    var env: BuiltInClassEnvironment {
        guard let classEnv = classEnv else {
            return BuiltInClassEnvironment(env: BaseEnvironment(enclosing: nil), value: self)
        }
        return BuiltInClassEnvironment(env: classEnv, value: self)
    }

    let type: MooseType

    init(env: ClassEnvironment?, name: String) {
        self.classEnv = env
        self.type = ClassType(name)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(type.description)
        env.getAllVariables().forEach {
            ($0 as! HashableObject).hash(into: &hasher)
        }
    }

    var isNil: Bool { classEnv == nil }
    func equals(other: MooseObject) -> Bool {
        // Check they have the same type
        guard type == other.type else {
            return false
        }

        guard let other = other as? Self else {
            return false
        }

        // At this point we already know that both are from the same class but
        // we don't know if they have the same values. Therefore we need to get
        // all variables form both classes.
        let variables = env.getAllVariables()
        let otherVariables = other.env.getAllVariables()

        guard variables.count == otherVariables.count else {
            return false
        }

        for (key, value) in variables {
            guard let otherValue = otherVariables[key] else {
                // TODO: I guess this can never happen 🤷‍♂️
                return false
            }

            guard value.equals(other: otherValue) else {
                return false
            }
        }

        return true
    }

    var description: String {
        "<class object: \(type)>"
    }
}

// Void is an Object because we *need* to return some MooseObject in our
// visitor. Therefore this is a placeholder.
// Users cannot actually access this type, its just there for internals.
class VoidObj: MooseObject {
    let type: MooseType = VoidType()
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Void_Env)

    init() {
        env.value = self
    }

    var isNil: Bool { false }
    func equals(other: MooseObject) -> Bool {
        return type == other.type
    }

    var description: String {
        type.description
    }
}

// This doesn't seem to make sense but it is needed for nil Literals.
// Nil Literals a kinda cursed, so when you write a nil literal we don't know
// the type of them (as to contrast to every other literal).
// So we also need to create an extra object for Nil literals and then convert
// them to the needed object once we know what type they should have.
//
// This however introduces a whole list of other weired behaivor like, with
// function overloading. If there is `a(x: Int)` and `a(x: String)` and
// you call `a(nil)` we don't actually know which function you meant,
// so we require you to cast that explicitly.
class NilObj: MooseObject {
    let type: MooseType = NilType()
    var env: BuiltInClassEnvironment = .init(env: BuiltIns.builtIn_Nil_Env)

    init() {
        env.value = self
    }

    var isNil: Bool { true }
    func equals(other: MooseObject) -> Bool {
        return type == other.type
    }

    var description: String {
        type.description
    }

    func toObject(type: MooseType) throws -> MooseObject {
        switch type {
        case is IntType:
            return IntegerObj(value: nil)
        case is FloatType:
            return FloatObj(value: nil)
        case is BoolType:
            return BoolObj(value: nil)
        case is StringType:
            return StringObj(value: nil)
        case is NilType:
            return NilObj()
        case is VoidType:
            return VoidObj()
        case let c as ClassType:
            return ClassObject(env: nil, name: c.name)
        case is TupleType:
            return TupleObj(type: type, value: nil)
        case is ListType:
            return ListObj(type: type, value: nil)
        case is DictType:
            return DictObj(type: type, pairs: nil)
        case is FunctionType, is AnyType, is ParamType:
            fallthrough
        default:
            throw RuntimeError(message: "Internal Error: Cannot convert nil literal to funciton")
        }
    }
}
