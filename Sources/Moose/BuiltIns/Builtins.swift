//
//  Builtins.swift
//
//
//  Created by Johannes Zottele on 28.06.22.
//

import Foundation

class BuiltIns {
    static let builtInFunctions = [
        BuiltInFunctionObj(name: "print", params: [.Int], returnType: .Void, function: printBuiltIn),
        BuiltInFunctionObj(name: "print", params: [.Float], returnType: .Void, function: printBuiltIn),
        BuiltInFunctionObj(name: "print", params: [.Bool], returnType: .Void, function: printBuiltIn),
        BuiltInFunctionObj(name: "print", params: [.String], returnType: .Void, function: printBuiltIn),
    ]
}

extension BuiltIns {
    static let builtInOperators = [
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: integerPlusBuiltIn),
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [.Float, .Float], returnType: .Float, function: floatPlusBuiltIn),
    ]
}

// Buit-in OperatorFunction
extension BuiltIns {
    /// Add two integer together with an infix
    // TODO: currently we use compactMap so we ignore nil value... is this smart? I don't know...
    static func integerPlusBuiltIn(_ args: [MooseObject]) -> MooseObject {
        return IntegerObj(value: args.compactMap {
            ($0 as! IntegerObj).value
        }
        .reduce(0, +))
    }

    /// Add two integer together with an infix
    // TODO: currently we use compactMap so we ignore nil value... is this smart? I don't know...
    static func floatPlusBuiltIn(_ args: [MooseObject]) -> MooseObject {
        return FloatObj(value: args.compactMap {
            ($0 as! FloatObj).value
        }
        .reduce(0, +))
    }
}

// Built-in Functions
extension BuiltIns {
    /// A generic print function that can print any MooseObject
    static func printBuiltIn(params: [MooseObject]) -> MooseObject {
        if let str = params[0] as? StringObj {
            print(str.value ?? "nil")
            return VoidObj()
        }

        print(params[0].description)
        return VoidObj()
    }
}
