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

    func equals(other: MooseObject) -> Bool
}

func == <T: MooseObject>(lhs: T, rhs: T) -> Bool {
    return lhs.equals(other: rhs)
}

protocol IndexableObject {
    func getAt(index: Int64) -> MooseObject
    func length() -> Int64
}

class IntegerObj: MooseObject {
    let type: MooseType = .Int
    let value: Int64?

    init(value: Int64?) {
        self.value = value
    }

    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }
}

class FloatObj: MooseObject {
    let type: MooseType = .Float
    let value: Float64?

    init(value: Float64?) {
        self.value = value
    }

    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }
}

class BoolObj: MooseObject {
    let type: MooseType = .Bool
    let value: Bool?

    init(value: Bool?) {
        self.value = value
    }

    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }
}

class StringObj: MooseObject {
    let type: MooseType = .String
    let value: String?

    init(value: String?) {
        self.value = value
    }

    func equals(other: MooseObject) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return value == other.value
    }

    var description: String {
        if let description = value?.description {
            return "\"\(description)\""
        }
        return "nil"
    }
}

class FunctionObj: MooseObject {
    let name: String
    let type: MooseType
    let paramNames: [String]
    let value: BlockStatement

    init(name: String, type: MooseType, paramNames: [String], value: BlockStatement) {
        self.name = name
        self.type = type
        self.paramNames = paramNames
        self.value = value
    }

    func equals(other _: MooseObject) -> Bool {
        // Functions can never be equal
        return false
    }

    var description: String {
        // TODO: type information would be nice here
        return "<func \(name)>"
    }
}

class BuiltInFunctionObj: MooseObject {
    typealias fnType = ([MooseObject]) throws -> MooseObject

    let name: String
    let params: [MooseType]
    let returnType: MooseType
    let type: MooseType

    let function: fnType

    init(name: String, params: [MooseType], returnType: MooseType, function: @escaping fnType) {
        self.name = name
        self.params = params
        self.returnType = returnType
        type = MooseType.Function(params, returnType)
        self.function = function
    }

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

    init(name: String, opPos: OpPos, type: MooseType, paramNames: [String], value: BlockStatement) {
        self.opPos = opPos
        super.init(name: name, type: type, paramNames: paramNames, value: value)
    }

    override var description: String {
        return "<\(opPos) operation \(name): \(type.description)>"
    }
}

class BuiltInOperatorObj: BuiltInFunctionObj {
    let opPos: OpPos

    init(name: String, opPos: OpPos, params: [MooseType], returnType: MooseType, function: @escaping fnType) {
        self.opPos = opPos
        super.init(name: name, params: params, returnType: returnType, function: function)
    }

    override var description: String {
        return "<built-in \(opPos) operation \(name): \(type.description)>"
    }
}

class TupleObj: MooseObject, IndexableObject {
    let type: MooseType
    let value: [MooseObject]?

    init(type: MooseType, value: [MooseObject]?) {
        self.type = type
        self.value = value
    }

    func getAt(index: Int64) -> MooseObject {
        return value![Int(index)]
    }

    func length() -> Int64 {
        return Int64(value?.count ?? 0)
    }

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
        var out = "("
        out += (value?.map { $0.description } ?? []).joined(separator: ", ")
        out += ")"
        return out
    }
}

class ListObj: MooseObject, IndexableObject {
    let type: MooseType
    let value: [MooseObject]?

    init(type: MooseType, value: [MooseObject]?) {
        self.type = type
        self.value = value
    }

    func getAt(index: Int64) -> MooseObject {
        return value![Int(index)]
    }

    func length() -> Int64 {
        return Int64(value?.count ?? 0)
    }

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
        var out = "["
        out += (value?.map { $0.description } ?? []).joined(separator: ", ")
        out += "]"
        return out
    }
}

// TODO: make classes indexable
class ClassObject: MooseObject {
    let env: ClassEnvironment
    let type: MooseType

    init(env: ClassEnvironment) {
        self.env = env
        type = .Class(env.className)
    }

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
        "<class object \(env.className): \(type)>"
    }
}

// Void is an Object because we *need* to return some MooseObject in our
// visitor. Therefore this is a placeholder.
// Users cannot actually access this type, its just there for internals.
class VoidObj: MooseObject {
    let type: MooseType = .Void

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
    let type: MooseType = .Nil
    func equals(other: MooseObject) -> Bool {
        return type == other.type
    }

    var description: String {
        type.description
    }

    func toObject(type: MooseType) throws -> MooseObject {
        switch type {
        case .Int:
            return IntegerObj(value: nil)
        case .Float:
            return FloatObj(value: nil)
        case .Bool:
            return BoolObj(value: nil)
        case .String:
            return StringObj(value: nil)
        case .Nil:
            return NilObj()
        case .Void:
            return VoidObj()
        case .Class:
            throw RuntimeError(message: "Internal Error: Cannot convert nil literal to class")
        case .Tuple:
            return TupleObj(type: type, value: nil)
        case .List:
            throw RuntimeError(message: "Internal Error: Cannot convert nil literal to list")
        case .Function:
            throw RuntimeError(message: "Internal Error: Cannot convert nil literal to funciton")
        }
    }
}
