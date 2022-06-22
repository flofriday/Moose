//
// Created by flofriday on 21.06.22.
//

import Foundation

indirect enum MooseType: Equatable {
    case Int
    case String
    case Bool
    case Tuple([MooseType])
    case List(MooseType)
    case Function([MooseType], MooseType) // Associated values are arguments and return value
    case Class(String) // The classname  is the associated type
    case Nil // only used in typechecker, no actual type
    case Void // represents non existing type value. Only usable for function results

    // TODO: add more types
    /// If valuetype is not implemented it returns nil
    static func from(_ value: ValueType) throws -> MooseType {
        if case .Identifier(ident: let id) = value {
            switch id.value {
            case "String":
                return .String
            case "Int":
                return .String
            case "Bool":
                return .String
            default:
                return .Class(id.value)
            }
        } else if case .Function(params: let params, returnType: let retType) = value {
            let par = try params.map { try from($0) }
//            var ret: MooseType?
//            if case .Void = retType {
//                ret = try from(retType)
//            }
            let ret = try from(retType)
            return Function(par, ret)
        } else if case .Tuple(types: let ts) = value {
            return .Tuple(try ts.map { try from($0) })
        } else {
            throw TypeConvertionError(msg: "Could not convert ValueType '\(value)' to MooseType.")
        }
    }
}

extension MooseType: CustomStringConvertible {
    var description: String {
        switch self {
        case .Int:
            return "Int"
        case .String:
            return "String"
        case .Bool:
            return "Bool"
        case .Nil:
            return "Nil"
        case .Void:
            return "()"
        case .Class(let i):
            return i
        case .Tuple(let ids):
            return "(\(ids.map { $0.description }.joined(separator: ", ")))"
        case .Function(let params, let returnType):
            return "(\(params.map { $0.description }.joined(separator: ", "))) > \(returnType.description)"
        case .List(let i):
            return "[\(i.description)]"
        }
    }
}
