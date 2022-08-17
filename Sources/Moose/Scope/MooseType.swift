//
// Created by flofriday on 21.06.22.
//

import Foundation

indirect enum MooseType: Equatable {
    case Int
    case Float
    case Bool
    case String
    case Nil // only used in typechecker, no actual type
    case Void // represents non existing type value. Only usable for function results
    case Class(String) // The classname  is the associated type
    case Tuple([MooseType])
    case List(MooseType)
    case Function([MooseType], MooseType) // Associated values are arguments and return value
}

extension MooseType {
    static func toClass(_ name: String) -> MooseType {
        switch name {
        case "String":
            return .String
        case "Int":
            return .Int
        case "Float":
            return .Float
        case "Bool":
            return .Bool
        case "Void":
            return .Void // should not happen since this is already a token after lexer
        case "Nil":
            return .Nil // should not happen since this is already a token after lexer
        default:
            return .Class(name)
        }
    }
}

extension MooseType: CustomStringConvertible {
    var description: String {
        switch self {
        case .Int:
            return "Int"
        case .Float:
            return "Float"
        case .String:
            return "String"
        case .Bool:
            return "Bool"
        case .Nil:
            return "Nil"
        case .Void:
            return "Void"
        case let .Class(i):
            return i
        case let .Tuple(ids):
            return "(\(ids.map { $0.description }.joined(separator: ", ")))"
        case let .Function(params, returnType):
            return "(\(params.map { $0.description }.joined(separator: ", "))) > \(returnType.description)"
        case let .List(i):
            return "[\(i.description)]"
        }
    }
}
