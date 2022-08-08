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
        BuiltInOperatorObj(name: "+", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: { _ in VoidObj() }),
    ]
}

// OperatorFunction
extension BuiltIns {
    // TODO: currently we use compactMap so we ignore nil value... is this smart? I don't know...
    static func integerPlus(_ args: [IntegerObj]) -> MooseObject {
        return IntegerObj(value: args.compactMap {
            $0.value
        }
        .reduce(0, +))
    }
}

/// A generic print function that can print any MooseObject
func printBuiltIn(params: [MooseObject]) -> MooseObject {
    if let str = params[0] as? StringObj {
        print(str.value ?? "nil")
        return VoidObj()
    }

    print(params[0].description)
    return VoidObj()
}
