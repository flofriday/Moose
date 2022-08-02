//
//  File.swift
//
//
//  Created by Johannes Zottele on 28.06.22.
//

import Foundation

protocol MooseObject: CustomStringConvertible {
    var type: MooseType { get }
}

class IntegerObj: MooseObject {
    let type: MooseType = .Int
    let value: Int?

    init(value: Int?) {
        self.value = value
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }
}

class FloatObj: MooseObject {
    let type: MooseType = .Float
    let value: Float?

    init(value: Float?) {
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

// TODO: implement for complex type like: classes, tuples, lists and functions

// TODO: Why is Void an Object? Can you actually create an object of the type void?
class VoidObj: MooseObject {
    let type: MooseType = .Void

    var description: String {
        type.description
    }
}
