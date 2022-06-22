//
// Created by flofriday on 21.06.22.
//

import Foundation

indirect enum MooseType: Equatable {
    case Int
    case Float
    case String
    case Bool
    case Tuple ([MooseType])
    case List (MooseType)
    case Function ([MooseType], MooseType?) // Associated values are arguments and return value
    case Class (String) // The classname is the associated type

    static func from(_ value: ValueType) -> MooseType {
        // TODO: add more complex types
        if value.description == "String" {
            return .String
        } else if value.description == "Int" {
            return .Int
        } else if value.description == "Float" {
            return .Float
        } else if value.description == "Bool" {
            return .Bool
        } else {
            return .Class(value.description)
        }
    }
}
