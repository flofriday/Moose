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

// TODO: implement for complex type like: classes, tuples, lists and functions

// TODO: Why is Void an Object? Can you actually create an object of the type void?
class VoidObj: MooseObject {
    let type: MooseType = .Void

    var description: String {
        type.description
    }
}
