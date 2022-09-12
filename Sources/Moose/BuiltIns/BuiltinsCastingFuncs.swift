//
//  File.swift
//
//
//  Created by Johannes Zottele on 01.09.22.
//

import Foundation

extension BuiltIns {
    static func castToString(_ params: [MooseObject], _ env: Environment) throws -> StringObj {
        if let str = params[0] as? StringObj { return StringObj(value: str.value) }
        return StringObj(value: try representAny(obj: params[0]))
    }
}
