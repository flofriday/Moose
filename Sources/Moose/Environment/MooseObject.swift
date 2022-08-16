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
}

class IntegerObj: MooseObject {
    let type: MooseType = .Int
    let value: Int64?

    init(value: Int64?) {
        self.value = value
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

class TupleObj: MooseObject {
    let type: MooseType
    let value: [MooseObject]?

    init(type: MooseType, value: [MooseObject]?) {
        self.type = type
        self.value = value
    }

    var description: String {
        var out = "("
        out += (value?.map { $0.description } ?? []).joined(separator: ", ")
        out += ")"
        return out
    }
}

// TODO: implement for complex type like: classes, tuples and lists

// Void is an Object because we *need* to return some MooseObject in our
// visitor. Therefore this is a placeholder.
// Users cannot actually access this type, its just there for internals.
class VoidObj: MooseObject {
    let type: MooseType = .Void

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
