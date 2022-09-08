//
// Created by flofriday on 21.06.22.
//

import Foundation

// indirect enum MooseType: Equatable {
//    case Int
//    case Float
//    case Bool
//    case String
//    case Nil // only used in typechecker, no actual type
//    case Void // represents non existing type value. Only usable for function results
//    case Class(String) // The classname  is the associated type
//    case Tuple([MooseType])
//    case List(MooseType)
//    case Function([MooseType], MooseType) // Associated values are arguments and return value
// }

class MooseType: Equatable, CustomStringConvertible {
    var description: String { "Not a Type" }

    func superOf(type other: MooseType) -> Bool { true }

    static func == (lhs: MooseType, rhs: MooseType) -> Bool { lhs.superOf(type: rhs) && rhs.superOf(type: lhs) }
}

class AnyType: MooseType {
    var asClass: ClassType? { nil }

    /// This function replaces all generic types by their actual types
    func inferredClass() throws -> ClassTypeScope { fatalError("INTERNAL ERROR: AnyType does not exist as class!") }
    override var description: String { "Any" }
    override func superOf(type other: MooseType) -> Bool { other is AnyType }
}

/// This type is allowed as type in parameters
class ParamType: AnyType {
    override var asClass: ClassType? { nil }

    override var description: String { "ParamType" }

    override func inferredClass() throws -> ClassTypeScope { fatalError("INTERNAL ERROR: ParamType does not exist as class!") }
    override func superOf(type other: MooseType) -> Bool { other is ParamType }
}

class IntType: ParamType {
    override var asClass: ClassType? { ClassType("Int") }
    override var description: String { "Int" }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool { other is IntType }
}

class StringType: ParamType {
    override var asClass: ClassType? { ClassType("String") }
    override var description: String { "String" }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool { other is StringType }
}

class FloatType: ParamType {
    override var asClass: ClassType? { ClassType("Float") }
    override var description: String { "Float" }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool { other is FloatType }
}

class BoolType: ParamType {
    override var asClass: ClassType? { ClassType("Bool") }
    override var description: String { "Bool" }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool { other is BoolType }
}

class ClassType: ParamType {
    let name: String

    override var asClass: ClassType? { self }
    override var description: String { name }

    init(_ name: String) {
        self.name = name
    }

    override func inferredClass() throws -> ClassTypeScope {
        guard let scope = TypeScope.global.getScope(clas: name) else {
            throw ScopeError(message: "Class \(name) does not exist.")
        }
        return scope
    }

    override func superOf(type other: MooseType) -> Bool {
        guard let other = other as? ClassType else { return false }
        return name == other.name
    }
}

class TupleType: ParamType {
    let entries: [ParamType]

    init(_ entries: [ParamType]) {
        self.entries = entries
    }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool {
        guard let other = other as? TupleType else { return false }
        return entries.count == other.entries.count &&
            zip(entries, other.entries).reduce(true) { acc, t in acc && t.0.superOf(type: t.1) }
    }

    override var asClass: ClassType? { ClassType("Tuple") }
    override var description: String { "(\(entries.map { $0.description }.joined(separator: ", ")))" }
}

class ListType: ParamType {
    let type: ParamType

    init(_ type: ParamType) {
        self.type = type
    }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool {
        guard let other = other as? ListType else { return false }
        return type.superOf(type: other.type)
    }

    override var asClass: ClassType? { ClassType("List") }
    override var description: String { "[\(type)]" }
}

class DictType: ParamType {
    let keyType: ParamType
    let valueType: ParamType

    init(_ key: ParamType, _ value: ParamType) {
        keyType = key
        valueType = value
    }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool {
        guard let other = other as? DictType else { return false }
        return keyType.superOf(type: other.keyType) && valueType.superOf(type: other.valueType)
    }

    override var asClass: ClassType? { ClassType("Dict") }
    override var description: String { "{\(keyType):\(valueType)}" }
}

class FunctionType: ParamType {
    let params: [ParamType]
    let returnType: MooseType

    init(params: [ParamType], returnType: MooseType) {
        self.params = params
        self.returnType = returnType
    }

    override func inferredClass() throws -> ClassTypeScope {
        try BuiltIns.getGenericEnv(type: self)
    }

    override func superOf(type other: MooseType) -> Bool {
        guard let other = other as? FunctionType else { return false }
        return params.count == other.params.count &&
            zip(params, other.params).reduce(true) { acc, t in acc && t.0.superOf(type: t.1) } &&
            returnType.superOf(type: other.returnType)
    }

    override var asClass: ClassType? { nil }
    override var description: String { "(\(params.map { $0.description }.joined(separator: ", "))) > \(returnType)" }
}

class NilType: AnyType {
    override func inferredClass() throws -> ClassTypeScope {
        throw ScopeError(message: "Nil is not an object.")
    }

    override var description: String { "Nil" }
    override func superOf(type other: MooseType) -> Bool { other is NilType }
}

class VoidType: MooseType {
    override var description: String { "Void" }
    override func superOf(type other: MooseType) -> Bool { other is VoidType }
}

extension MooseType {
    static func toType(_ name: String) -> MooseType {
        switch name {
        case "String":
            return StringType()
        case "Int":
            return IntType()
        case "Float":
            return FloatType()
        case "Bool":
            return BoolType()
        case "Void":
            return VoidType() // should not happen since this is already a token after lexer
        case "Nil":
            return NilType() // should not happen since this is already a token after lexer
        default:
            return ClassType(name)
        }
    }
}

// extension MooseType {
//    var asClass: MooseType? {
//        switch self {
//        case .Class:
//            return self
//        case .Int:
//            return .Class("Int")
//        case .Float:
//            return .Class("Float")
//        case .Bool:
//            return .Class("Bool")
//        case .Tuple:
//            return .Class("Tuple")
//        case .List:
//            return .Class("List")
//        default:
//            return nil
//        }
//    }
// }

// extension MooseType: CustomStringConvertible {
//    var description: String {
//        switch self {
//        case .Int:
//            return "Int"
//        case .Float:
//            return "Float"
//        case .String:
//            return "String"
//        case .Bool:
//            return "Bool"
//        case .Nil:
//            return "Nil"
//        case .Void:
//            return "Void"
//        case let .Class(i):
//            return i
//        case let .Tuple(ids):
//            return "(\(ids.map { $0.description }.joined(separator: ", ")))"
//        case let .Function(params, returnType):
//            return "(\(params.map { $0.description }.joined(separator: ", "))) > \(returnType.description)"
//        case let .List(i):
//            return "[\(i.description)]"
//        }
//    }
// }
