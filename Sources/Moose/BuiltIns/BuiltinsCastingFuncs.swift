//
//  File.swift
//
//
//  Created by Johannes Zottele on 01.09.22.
//

import Foundation

extension BuiltIns {
    static func castToString(_ params: [MooseObject], _ env: Environment) throws -> StringObj {
        return StringObj(value: params[0].description)
    }
}
