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
        // Integer calculations
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: integerAddBuiltIn),
        BuiltInOperatorObj(name: "-", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: integerSubBuiltIn),
        BuiltInOperatorObj(name: "*", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: integerMulBuiltIn),
        BuiltInOperatorObj(name: "/", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: integerDivBuiltIn),

        // Integer comparisons
        BuiltInOperatorObj(name: "==", opPos: .Infix, params: [.Int, .Int], returnType: .Bool, function: integerEqualBuiltIn),
        BuiltInOperatorObj(name: "<", opPos: .Infix, params: [.Int, .Int], returnType: .Bool, function: integerLessBuiltIn),
        BuiltInOperatorObj(name: "<=", opPos: .Infix, params: [.Int, .Int], returnType: .Bool, function: integerLessEqualBuiltIn),
        BuiltInOperatorObj(name: ">", opPos: .Infix, params: [.Int, .Int], returnType: .Bool, function: integerGreaterBuiltIn),
        BuiltInOperatorObj(name: ">=", opPos: .Infix, params: [.Int, .Int], returnType: .Bool, function: integerGreaterEqualBuiltIn),

        // Float calculations
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [.Float, .Float], returnType: .Float, function: floatAddBuiltIn),
        BuiltInOperatorObj(name: "-", opPos: .Infix, params: [.Float, .Float], returnType: .Float, function: floatSubBuiltIn),
        BuiltInOperatorObj(name: "*", opPos: .Infix, params: [.Float, .Float], returnType: .Float, function: floatMulBuiltIn),
        BuiltInOperatorObj(name: "/", opPos: .Infix, params: [.Float, .Float], returnType: .Float, function: floatDivBuiltIn),

        // Float comparisons
        BuiltInOperatorObj(name: "==", opPos: .Infix, params: [.Float, .Float], returnType: .Bool, function: floatEqualBuiltIn),
        BuiltInOperatorObj(name: "<", opPos: .Infix, params: [.Float, .Float], returnType: .Bool, function: floatLessBuiltIn),
        BuiltInOperatorObj(name: "<=", opPos: .Infix, params: [.Float, .Float], returnType: .Bool, function: floatLessEqualBuiltIn),
        BuiltInOperatorObj(name: ">", opPos: .Infix, params: [.Float, .Float], returnType: .Bool, function: floatGreaterBuiltIn),
        BuiltInOperatorObj(name: ">=", opPos: .Infix, params: [.Float, .Float], returnType: .Bool, function: floatGreaterEqualBuiltIn),

        // Bool calculations
        BuiltInOperatorObj(name: "&&", opPos: .Infix, params: [.Bool, .Bool], returnType: .Bool, function: boolAndBuiltIn),
        BuiltInOperatorObj(name: "||", opPos: .Infix, params: [.Bool, .Bool], returnType: .Bool, function: boolOrBuiltIn),
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
    static func castToStringBuiltIn(params: [MooseObject]) -> StringObj {
        let input = params[0]
        return StringObj(value: input.description)
    }

    /// A generic cast function that can convert Float and Bool to Integer.
    static func castToIntBuiltIn(params: [MooseObject]) -> IntegerObj {
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
    static func castToFloatBuiltIn(params: [MooseObject]) -> FloatObj {
        let input = params[0] as! IntegerObj
        guard let value = input.value else {
            return FloatObj(value: nil)
        }
        return FloatObj(value: Float64(value))
    }

    /// A cast function that can convert Integer to Bool.
    static func castToBoolBuiltIn(params: [MooseObject]) -> BoolObj {
        let input = params[0] as! IntegerObj
        guard let value = input.value else {
            return BoolObj(value: nil)
        }
        return BoolObj(value: value == 0 ? false : true)
    }

    /// A generic print function that can print any MooseObject
    static func printBuiltIn(params: [MooseObject]) -> VoidObj {
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
                if value > 255 {
                    exitCode = 255
                } else {
                    exitCode = Int32(truncatingIfNeeded: value)
                }
            }
        }

        exit(exitCode)
    }
}

// Buit-in OperatorFunction
extension BuiltIns {
    // Asserts that either Int, Float, Bool or String inputs are not nil
    private static func assertNoNil(_ args: [MooseObject]) throws {
        try args.forEach {
            switch $0 {
            case let int as IntegerObj:
                if int.value == nil {
                    throw NilUsagePanic()
                }
            case let float as FloatObj:
                if float.value == nil {
                    throw NilUsagePanic()
                }
            case let bool as BoolObj:
                if bool.value == nil {
                    throw NilUsagePanic()
                }
            case let str as StringObj:
                if str.value == nil {
                    throw NilUsagePanic()
                }

            default:
                throw RuntimeError(message: "Internal Error in assertNoNil")
            }
        }
    }

    /// Add two integer together with an infix operation
    static func integerAddBuiltIn(_ args: [MooseObject]) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a + b)
    }

    /// Subtract two integer together with an infix operation
    static func integerSubBuiltIn(_ args: [MooseObject]) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a - b)
    }

    /// Multiply two integer together with an infix operation
    static func integerMulBuiltIn(_ args: [MooseObject]) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a * b)
    }

    /// Divide two integers with an infix operation
    static func integerDivBuiltIn(_ args: [MooseObject]) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a / b)
    }

    /// Check if two integers are equal
    static func integerEqualBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        let a = (args[0] as! IntegerObj).value
        let b = (args[1] as! IntegerObj).value
        return BoolObj(value: a == b)
    }

    /// A helper to make comparing functions (requiring arguments to be not nil)
    /// a lot easier to write.
    private static func integerComparison(args: [MooseObject], operation: (Int64, Int64) -> Bool) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return BoolObj(value: operation(a, b))
    }

    /// Check if two integers are greater than each other
    static func integerGreaterBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try integerComparison(args: args, operation: >)
    }

    /// Check if two integers are greater or equal than each other
    static func integerGreaterEqualBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try integerComparison(args: args, operation: >=)
    }

    /// Check if two integers are less than each other
    static func integerLessBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try integerComparison(args: args, operation: <)
    }

    /// Check if two integers are less or equal than each other
    static func integerLessEqualBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try integerComparison(args: args, operation: <=)
    }

    /// Add two integer floats with an infix operation
    static func floatAddBuiltIn(_ args: [MooseObject]) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a + b)
    }

    /// Sub two integer floats with an infix operation
    static func floatSubBuiltIn(_ args: [MooseObject]) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a - b)
    }

    /// Multiply two floats together with an infix operation
    static func floatMulBuiltIn(_ args: [MooseObject]) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a * b)
    }

    /// Divide two floats together with an infix operation
    static func floatDivBuiltIn(_ args: [MooseObject]) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a / b)
    }

    /// Check if two integers are equal
    static func floatEqualBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        let a = (args[0] as! IntegerObj).value
        let b = (args[1] as! IntegerObj).value
        return BoolObj(value: a == b)
    }

    /// A helper to make comparing functions (requiring arguments to be not nil)
    /// a lot easier to write.
    private static func floatComparison(args: [MooseObject], operation: (Float64, Float64) -> Bool) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return BoolObj(value: operation(a, b))
    }

    /// Check if two integers are greater than each other
    static func floatGreaterBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try floatComparison(args: args, operation: >)
    }

    /// Check if two integers are greater or equal than each other
    static func floatGreaterEqualBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try floatComparison(args: args, operation: >=)
    }

    /// Check if two integers are less than each other
    static func floatLessBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try floatComparison(args: args, operation: <)
    }

    /// Check if two integers are less or equal than each other
    static func floatLessEqualBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try floatComparison(args: args, operation: <=)
    }

    // Logical and for bools
    static func boolAndBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! BoolObj).value!
        let b = (args[1] as! BoolObj).value!
        return BoolObj(value: a && b)
    }

    // Logical or for bools
    static func boolOrBuiltIn(_ args: [MooseObject]) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! BoolObj).value!
        let b = (args[1] as! BoolObj).value!
        return BoolObj(value: a || b)
    }
}
