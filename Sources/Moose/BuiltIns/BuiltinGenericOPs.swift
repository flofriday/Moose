//
//  File.swift
//
//
//  Created by Johannes Zottele on 01.09.22.
//

import Foundation

extension BuiltIns {
    static func equalGeneric(_ params: [MooseObject], _ env: Environment) throws -> BoolObj {
        let lhs = params[0]
        let rhs = params[1]
        if lhs.isNil, rhs.isNil { return BoolObj(value: true) }
        return BoolObj(value: lhs.equals(other: rhs))
    }

    static func notEqualGeneric(_ params: [MooseObject], _ env: Environment) throws -> BoolObj {
        let lhs = params[0]
        let rhs = params[1]

        if rhs.isNil, lhs.isNil { return BoolObj(value: false) }
        return BoolObj(value: !lhs.equals(other: rhs))
    }

    static func notNullTest(_ params: [MooseObject], _ env: Environment) throws -> BoolObj {
        return BoolObj(value: !params[0].isNil)
    }

    static func negateOperator(_ params: [MooseObject], _ env: Environment) throws -> BoolObj {
        guard let b = (params[0] as! BoolObj).value else {
            throw RuntimeError(message: "Nullpointer exception while negating value...")
        }
        return BoolObj(value: !b)
    }
}
