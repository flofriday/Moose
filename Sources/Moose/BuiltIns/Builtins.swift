//
//  Builtins.swift
//
//
//  Created by Johannes Zottele on 28.06.22.
//

import Foundation

class BuiltIns {
    static let builtInFunctions = [
        // TODO: It should be possible to cast/parse strings to ints and floats.
        // However that can fail so we need to have a way to communicate failure.
        // The easiest would be to return a error tuple similar to golang.

        BuiltInFunctionObj(name: "Int", params: [.Float], returnType: .Int, function: castToIntBuiltIn),
        BuiltInFunctionObj(name: "Int", params: [.Bool], returnType: .Int, function: castToIntBuiltIn),

        BuiltInFunctionObj(name: "Float", params: [.Int], returnType: .Float, function: castToFloatBuiltIn),

        BuiltInFunctionObj(name: "Bool", params: [.Int], returnType: .Bool, function: castToBoolBuiltIn),

        BuiltInFunctionObj(name: "String", params: [.Int], returnType: .String, function: castToStringBuiltIn),
        BuiltInFunctionObj(name: "String", params: [.Float], returnType: .String, function: castToStringBuiltIn),
        BuiltInFunctionObj(name: "String", params: [.Bool], returnType: .String, function: castToStringBuiltIn),

        BuiltInFunctionObj(name: "print", params: [.Int], returnType: .Void, function: printBuiltIn),
        BuiltInFunctionObj(name: "print", params: [.Float], returnType: .Void, function: printBuiltIn),
        BuiltInFunctionObj(name: "print", params: [.Bool], returnType: .Void, function: printBuiltIn),
        BuiltInFunctionObj(name: "print", params: [.String], returnType: .Void, function: printBuiltIn),

        BuiltInFunctionObj(name: "exit", params: [], returnType: .Void, function: exitBuiltIn),
        BuiltInFunctionObj(name: "exit", params: [.Int], returnType: .Void, function: exitBuiltIn),
    ]
}

extension BuiltIns {
    static let builtInOperators = [
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: integerPlusBuiltIn),
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [.Float, .Float], returnType: .Float, function: floatPlusBuiltIn),
    ]
}

// Built-in Functions
// You will notice that we are very liberal with types here and do many force
// casts. This is because all builtin functions have the same type (in Swift)
// However the Moose Typechecker already confirms that they are only called
// with the correct arguments so in the implementation here we can do force
// casts.
extension BuiltIns {
    /// A generic cast function that can convert Integer, Float and Bool to String.
    static func castToStringBuiltIn(params: [MooseObject]) -> MooseObject {
        let input = params[0]
        return StringObj(value: input.description)
    }

    /// A generic cast function that can convert Float and Bool to Integer.
    static func castToIntBuiltIn(params: [MooseObject]) -> MooseObject {
        let input = params[0]
        switch input {
        case let bool as BoolObj:
            guard let value = bool.value else {
                return IntegerObj(value: nil)
            }
            return IntegerObj(value: value ? 1 : 0)
        case let float as FloatObj:
            guard let value = float.value else {
                return IntegerObj(value: nil)
            }
            return IntegerObj(value: Int64(value))
        default:
            // This cannot happen
            return IntegerObj(value: nil)
        }
    }

    /// A cast function that can convert Integer to Float.
    static func castToFloatBuiltIn(params: [MooseObject]) -> MooseObject {
        let input = params[0] as! IntegerObj
        guard let value = input.value else {
            return FloatObj(value: nil)
        }
        return FloatObj(value: Float64(value))
    }

    /// A cast function that can convert Integer to Bool.
    static func castToBoolBuiltIn(params: [MooseObject]) -> MooseObject {
        let input = params[0] as! IntegerObj
        guard let value = input.value else {
            return BoolObj(value: nil)
        }
        return BoolObj(value: value == 0 ? false : true)
    }

    /// A generic print function that can print any MooseObject
    static func printBuiltIn(params: [MooseObject]) -> MooseObject {
        if let str = params[0] as? StringObj {
            print(str.value ?? "nil")
            return VoidObj()
        }

        print(params[0].description)
        return VoidObj()
    }

    /// A generic exit function that may take an argument
    static func exitBuiltIn(params: [MooseObject]) -> MooseObject {
        var exitCode: Int32 = 0

        if params.count == 1 {
            if let value = (params[0] as! IntegerObj).value {
                exitCode = Int32(truncatingIfNeeded: value)
            }
        }

        exit(exitCode)
    }
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
