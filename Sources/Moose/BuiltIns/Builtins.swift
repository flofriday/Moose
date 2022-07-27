//
//  File.swift
//
//
//  Created by Johannes Zottele on 28.06.22.
//

import Foundation

class BuiltIns {
    static let builtInFunctions = [
        BuiltInFunction(name: "print", params: [.String], returnType: .Void, function: printBuiltIn),
    ]
}

extension BuiltIns {
    static let builtInOperators = [
        BuiltInOperator(name: "+", opPos: .Infix, params: [.Int, .Int], returnType: .Int, function: { _ in VoidObj() })
    ]
}

extension BuiltIns {
    class BuiltInFunction {
        typealias fnType = ([MooseObject]) -> MooseObject

        let name: String
        let params: [MooseType]
        let returnType: MooseType

        let function: fnType

        init(name: String, params: [MooseType], returnType: MooseType, function: @escaping fnType) {
            self.name = name
            self.params = params
            self.returnType = returnType
            self.function = function
        }
    }

    class BuiltInOperator: BuiltInFunction {
        let opPos: OpPos

        init(name: String, opPos: OpPos, params: [MooseType], returnType: MooseType, function: @escaping fnType) {
            self.opPos = opPos
            super.init(name: name, params: params, returnType: returnType, function: function)
        }
    }
}

extension BuiltIns {
    // OperatorFunction

    // TODO: currently we use compactMap so we ignore nil value... is this smart? I don't know...
    static func integerPlus(_ args: [IntegerObj]) -> MooseObject {
        return IntegerObj(value: args.compactMap {
                    $0.value
                }
                .reduce(0, +))
    }
}

func printBuiltIn(params: [MooseObject]) -> MooseObject {
    print(params[0].description)
    return VoidObj()
}