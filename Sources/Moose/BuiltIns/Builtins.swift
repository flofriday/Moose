//
//  Builtins.swift
//
//
//  Created by Johannes Zottele on 28.06.22.
//

import Foundation

class BuiltIns {
    static let builtInFunctions = [
        // Mini stdlib
        BuiltInFunctionObj(name: "range", params: [IntType()], returnType: ListType(IntType()), function: rangeBuiltIn),

        // Math functions
        BuiltInFunctionObj(name: "min", params: [IntType(), IntType()], returnType: IntType(), function: minBuiltIn),
        BuiltInFunctionObj(name: "min", params: [FloatType(), FloatType()], returnType: FloatType(), function: minBuiltIn),
        BuiltInFunctionObj(name: "max", params: [IntType(), IntType()], returnType: IntType(), function: maxBuiltIn),
        BuiltInFunctionObj(name: "max", params: [FloatType(), FloatType()], returnType: FloatType(), function: maxBuiltIn),
        BuiltInFunctionObj(name: "abs", params: [IntType()], returnType: IntType(), function: absBuiltIn),
        BuiltInFunctionObj(name: "abs", params: [FloatType()], returnType: FloatType(), function: absBuiltIn),

        // IO Functions
        BuiltInFunctionObj(name: "print", params: [ParamType()], returnType: VoidType(), function: printBuiltIn),
        BuiltInFunctionObj(name: "println", params: [ParamType()], returnType: VoidType(), function: printlnBuiltIn),

        BuiltInFunctionObj(name: "input", params: [], returnType: StringType(), function: inputBuiltIn),
        BuiltInFunctionObj(name: "open", params: [StringType()], returnType: TupleType([StringType(), StringType()]), function: openBuiltIn),

        BuiltInFunctionObj(name: "exit", params: [], returnType: VoidType(), function: exitBuiltIn),
        BuiltInFunctionObj(name: "exit", params: [IntType()], returnType: VoidType(), function: exitBuiltIn),

        // Debug functions
        BuiltInFunctionObj(name: "dbgEnv", params: [], returnType: VoidType(), function: environmentBuiltIn),

        // Casting Functions
        BuiltInFunctionObj(name: "String", params: [ParamType()], returnType: StringType(), function: castToString),
    ]
}

extension BuiltIns {
    static let builtInOperators = [
        // Integer calculations
        BuiltInOperatorObj(name: "-", opPos: .Prefix, params: [IntType()], returnType: IntType(), function: integerNegBuiltIn),
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [IntType(), IntType()], returnType: IntType(), function: integerAddBuiltIn),
        BuiltInOperatorObj(name: "-", opPos: .Infix, params: [IntType(), IntType()], returnType: IntType(), function: integerSubBuiltIn),
        BuiltInOperatorObj(name: "*", opPos: .Infix, params: [IntType(), IntType()], returnType: IntType(), function: integerMulBuiltIn),
        BuiltInOperatorObj(name: "/", opPos: .Infix, params: [IntType(), IntType()], returnType: IntType(), function: integerDivBuiltIn),
        BuiltInOperatorObj(name: "%", opPos: .Infix, params: [IntType(), IntType()], returnType: IntType(), function: integerModuloBuiltIn),

        // Integer comparisons
        BuiltInOperatorObj(name: "<", opPos: .Infix, params: [IntType(), IntType()], returnType: BoolType(), function: integerLessBuiltIn),
        BuiltInOperatorObj(name: "<=", opPos: .Infix, params: [IntType(), IntType()], returnType: BoolType(), function: integerLessEqualBuiltIn),
        BuiltInOperatorObj(name: ">", opPos: .Infix, params: [IntType(), IntType()], returnType: BoolType(), function: integerGreaterBuiltIn),
        BuiltInOperatorObj(name: ">=", opPos: .Infix, params: [IntType(), IntType()], returnType: BoolType(), function: integerGreaterEqualBuiltIn),

        // Float calculations
        BuiltInOperatorObj(name: "-", opPos: .Prefix, params: [FloatType()], returnType: FloatType(), function: floatNegBuiltIn),
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [FloatType(), FloatType()], returnType: FloatType(), function: floatAddBuiltIn),
        BuiltInOperatorObj(name: "-", opPos: .Infix, params: [FloatType(), FloatType()], returnType: FloatType(), function: floatSubBuiltIn),
        BuiltInOperatorObj(name: "*", opPos: .Infix, params: [FloatType(), FloatType()], returnType: FloatType(), function: floatMulBuiltIn),
        BuiltInOperatorObj(name: "/", opPos: .Infix, params: [FloatType(), FloatType()], returnType: FloatType(), function: floatDivBuiltIn),

        // Float comparisons
        BuiltInOperatorObj(name: "<", opPos: .Infix, params: [FloatType(), FloatType()], returnType: BoolType(), function: floatLessBuiltIn),
        BuiltInOperatorObj(name: "<=", opPos: .Infix, params: [FloatType(), FloatType()], returnType: BoolType(), function: floatLessEqualBuiltIn),
        BuiltInOperatorObj(name: ">", opPos: .Infix, params: [FloatType(), FloatType()], returnType: BoolType(), function: floatGreaterBuiltIn),
        BuiltInOperatorObj(name: ">=", opPos: .Infix, params: [FloatType(), FloatType()], returnType: BoolType(), function: floatGreaterEqualBuiltIn),

        // Bool calculations
        BuiltInOperatorObj(name: "&&", opPos: .Infix, params: [BoolType(), BoolType()], returnType: BoolType(), function: boolAndBuiltIn),
        BuiltInOperatorObj(name: "||", opPos: .Infix, params: [BoolType(), BoolType()], returnType: BoolType(), function: boolOrBuiltIn),

        // String calculations
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [StringType(), StringType()], returnType: StringType(), function: stringConcatBuiltIn),

        // Generic Operators
        BuiltInOperatorObj(name: "==", opPos: .Infix, params: [ParamType(), ParamType()], returnType: BoolType(), function: equalGeneric),
        BuiltInOperatorObj(name: "!=", opPos: .Infix, params: [ParamType(), ParamType()], returnType: BoolType(), function: notEqualGeneric),

        BuiltInOperatorObj(name: "?", opPos: .Postfix, params: [ParamType()], returnType: BoolType(), function: notNullTest),
        BuiltInOperatorObj(name: "!", opPos: .Prefix, params: [BoolType()], returnType: BoolType(), function: negateOperator),
    ]
}

// Built-in Functions
// You will notice that we are very liberal with types here and do many force
// casts. This is because all builtin functions have the same type (in Swift)
// However the Moose Typechecker already confirms that they are only called
// with the correct arguments so in the implementation here we can do force
// casts.
//
// All Builtin functions can only accept an array of MooseObject, because they
// all need to fulfill the same interface, however they can return a more strict
// type, therefore I would encourage you to select the most specific type for
// the return and document which argument types you accept with an commentar.
extension BuiltIns {
    /// A helper function to easily create lists
    static func rangeBuiltIn(_ params: [MooseObject], _: Environment) throws -> ListObj {
        try assertNoNil(params)

        let type = ListType(IntType())
        let n = (params[0] as! IntegerObj).value! - 1
        guard n >= 0 else {
            return ListObj(type: type, value: [])
        }
        let l = Array(0 ... n).map { IntegerObj(value: $0) }
        return ListObj(type: type, value: l)
    }

    /// Checks if env has represent function with string as return type
    /// If so, it calls it and returns the String back
    ///
    /// Otherwise return nil
    static func callRepresent(env: Environment) throws -> StringObj? {
        guard env.has(function: Settings.REPRESENT_FUNCTIONNAME, params: []) else {
            return nil
        }

        let repFun = try env.get(function: Settings.REPRESENT_FUNCTIONNAME, params: [])

        if let repFun = repFun as? BuiltInFunctionObj {
            guard repFun.returnType is StringType else { return nil }
        } else if let repFun = repFun as? FunctionObj {
            guard (repFun.type as? FunctionType)?.returnType is StringType else { return nil }
        } else {
            return nil
        }

        let strObj = try Interpreter(environment: env).callFunctionOrOperator(callee: repFun, args: [])
        guard let strObj = strObj as? StringObj else { return nil }
        return strObj
    }

    static func representAny(obj: MooseObject) throws -> String {
        guard !obj.isNil else { return "nil" }
        guard let repObj = try callRepresent(env: obj.env) else {
            return obj.description
        }

        return repObj.value!
    }

    /// A generic print function that can print any MooseObject
    static func printlnBuiltIn(params: [MooseObject], env _: Environment) throws -> VoidObj {
        if let str = params[0] as? StringObj {
            print(str.value!)
            return VoidObj()
        }

        print(try representAny(obj: params[0]))
        return VoidObj()
    }

    /// A generic print function that can print any MooseObject
    static func printBuiltIn(params: [MooseObject], env _: Environment) throws -> VoidObj {
        if let str = params[0] as? StringObj {
            print(str.value!, terminator: "")
            return VoidObj()
        }

        print(try representAny(obj: params[0]), terminator: "")
        return VoidObj()
    }

    /// A function to read a single line from stdin.
    /// The functions always succeed and never returns nil.
    static func inputBuiltIn(_: [MooseObject], _: Environment) -> StringObj {
        return StringObj(value: readLine())
    }

    /// A function to read a file, given a path.
    /// The functions returns a String tuple. The first one is the string of the
    /// file content if the function succeeds, the second one is nil if it
    /// succeeds and otherwise a error message of what went wrong.
    static func openBuiltIn(_ params: [MooseObject], _: Environment) throws -> TupleObj {
        try assertNoNil(params)
        let path = (params[0] as! StringObj).value!

        var value: String?
        var errMsg: String?
        do {
            value = try String(contentsOfFile: path)
        } catch {
            errMsg = error.localizedDescription
        }

        return TupleObj(type: TupleType([StringType(), StringType()]), value: [StringObj(value: value), StringObj(value: errMsg)])
    }

    /// A generic exit function that may take an argument
    static func exitBuiltIn(params: [MooseObject], _: Environment) -> MooseObject {
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

    /// Print the current environment to see what the interpreter thinks is
    /// going on. This in mostly for interpreter development and debugging.
    static func environmentBuiltIn(params _: [MooseObject], _: Environment) -> VoidObj {
        let interpreter = Interpreter.shared
        interpreter.environment.printDebug(header: true)
        return VoidObj()
    }
}

// Buit-in OperatorFunction
extension BuiltIns {
    // Asserts that either Int, Float, Bool or String inputs are not nil
    static func assertNoNil(_ args: [MooseObject]) throws {
        try args.forEach {
            if $0.isNil { throw NilUsagePanic() }
        }
    }

    static func assertNoNil(_ args: MooseObject...) throws {
        try assertNoNil(args)
    }

    // A generic builtin equal operator function that can compare any two
    // MooseObjects even, if they are not of the same type
    static func genericEqualBuiltIn(_ args: [MooseObject], _: Environment) throws -> BoolObj {
        return BoolObj(value: args[0].equals(other: args[1]))
    }

    // A generic builtin not equal operator function that can compare any two
    // MooseObjects even, if they are not of the same type
    static func genericNotEqualBuiltIn(_ args: [MooseObject], _: Environment) throws -> BoolObj {
        return BoolObj(value: !args[0].equals(other: args[1]))
    }

    /// Negate an integer by writing a minus in front of it
    static func integerNegBuiltIn(_ args: [MooseObject], _: Environment) throws -> IntegerObj {
        try assertNoNil(args)

        let value = (args[0] as! IntegerObj).value!
        return IntegerObj(value: value * -1)
    }

    /// Add two integer together with an infix operation
    static func integerAddBuiltIn(_ args: [MooseObject], _: Environment) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a + b)
    }

    /// Subtract two integer together with an infix operation
    static func integerSubBuiltIn(_ args: [MooseObject], _: Environment) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a - b)
    }

    /// Multiply two integer together with an infix operation
    static func integerMulBuiltIn(_ args: [MooseObject], _: Environment) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a * b)
    }

    /// Divide two integers with an infix operation
    static func integerDivBuiltIn(_ args: [MooseObject], _: Environment) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a / b)
    }

    /// Modulo of two integers with an infix operation
    static func integerModuloBuiltIn(_ args: [MooseObject], _: Environment) throws -> IntegerObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return IntegerObj(value: a % b)
    }

    /// A helper to make comparing functions (requiring arguments to be not nil)
    /// a lot easier to write.
    private static func integerComparison(args: [MooseObject], _: Environment, operation: (Int64, Int64) -> Bool) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! IntegerObj).value!
        let b = (args[1] as! IntegerObj).value!
        return BoolObj(value: operation(a, b))
    }

    /// Check if two integers are greater than each other
    static func integerGreaterBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try integerComparison(args: args, env, operation: >)
    }

    /// Check if two integers are greater or equal than each other
    static func integerGreaterEqualBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try integerComparison(args: args, env, operation: >=)
    }

    /// Check if two integers are less than each other
    static func integerLessBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try integerComparison(args: args, env, operation: <)
    }

    /// Check if two integers are less or equal than each other
    static func integerLessEqualBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try integerComparison(args: args, env, operation: <=)
    }

    /// Negate an float by writing a minus in front of it
    static func floatNegBuiltIn(_ args: [MooseObject], _: Environment) throws -> FloatObj {
        try assertNoNil(args)

        let value = (args[0] as! FloatObj).value!
        return FloatObj(value: value * -1)
    }

    /// Add two integer floats with an infix operation
    static func floatAddBuiltIn(_ args: [MooseObject], _: Environment) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a + b)
    }

    /// Sub two integer floats with an infix operation
    static func floatSubBuiltIn(_ args: [MooseObject], _: Environment) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a - b)
    }

    /// Multiply two floats together with an infix operation
    static func floatMulBuiltIn(_ args: [MooseObject], _: Environment) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a * b)
    }

    /// Divide two floats together with an infix operation
    static func floatDivBuiltIn(_ args: [MooseObject], _: Environment) throws -> FloatObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return FloatObj(value: a / b)
    }

    /// A helper to make comparing functions (requiring arguments to be not nil)
    /// a lot easier to write.
    private static func floatComparison(args: [MooseObject], _: Environment, operation: (Float64, Float64) -> Bool) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! FloatObj).value!
        let b = (args[1] as! FloatObj).value!
        return BoolObj(value: operation(a, b))
    }

    /// Check if two integers are greater than each other
    static func floatGreaterBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try floatComparison(args: args, env, operation: >)
    }

    /// Check if two integers are greater or equal than each other
    static func floatGreaterEqualBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try floatComparison(args: args, env, operation: >=)
    }

    /// Check if two integers are less than each other
    static func floatLessBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try floatComparison(args: args, env, operation: <)
    }

    /// Check if two integers are less or equal than each other
    static func floatLessEqualBuiltIn(_ args: [MooseObject], _ env: Environment) throws -> BoolObj {
        try floatComparison(args: args, env, operation: <=)
    }

    // Logical and for bools
    static func boolAndBuiltIn(_ args: [MooseObject], _: Environment) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! BoolObj).value!
        let b = (args[1] as! BoolObj).value!
        return BoolObj(value: a && b)
    }

    // Logical or for bools
    static func boolOrBuiltIn(_ args: [MooseObject], _: Environment) throws -> BoolObj {
        try assertNoNil(args)

        let a = (args[0] as! BoolObj).value!
        let b = (args[1] as! BoolObj).value!
        return BoolObj(value: a || b)
    }

    // Concatenation for strings
    static func stringConcatBuiltIn(_ args: [MooseObject], _: Environment) throws -> StringObj {
        try assertNoNil(args)

        let a = (args[0] as! StringObj).value!
        let b = (args[1] as! StringObj).value!
        return StringObj(value: a + b)
    }

    // min function int and float
    static func minBuiltIn(_ args: [MooseObject], _: Environment) throws -> MooseObject {
        try assertNoNil(args)

        if args[0].type is IntType {
            return (args as! [IntegerObj]).sorted { $0.value! < $1.value! }[0]
        } else {
            return (args as! [FloatObj]).sorted { $0.value! < $1.value! }[0]
        }
    }

    // max function int and float
    static func maxBuiltIn(_ args: [MooseObject], _: Environment) throws -> MooseObject {
        try assertNoNil(args)

        if args[0].type is IntType {
            return (args as! [IntegerObj]).sorted { $0.value! > $1.value! }[0]
        } else {
            return (args as! [FloatObj]).sorted { $0.value! > $1.value! }[0]
        }
    }

    // abs function int and float
    static func absBuiltIn(_ args: [MooseObject], _: Environment) throws -> MooseObject {
        try assertNoNil(args)

        if let i = args[0] as? IntegerObj {
            return IntegerObj(value: Int64(abs(i.value!)))
        } else if let f = args[0] as? FloatObj {
            return FloatObj(value: Float64(abs(f.value!)))
        }

        fatalError("Function \(#function) does not support type \(args[0].type)!")
    }
}
