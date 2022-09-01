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

        return BoolObj(value: lhs.equals(other: rhs))
    }

    static func notEqualGeneric(_ params: [MooseObject], _ env: Environment) throws -> BoolObj {
        let lhs = params[0]
        let rhs = params[1]

        return BoolObj(value: !lhs.equals(other: rhs))
    }
}
