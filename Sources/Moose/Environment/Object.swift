//
//  File.swift
//
//
//  Created by Johannes Zottele on 28.06.22.
//

import Foundation

protocol Object: CustomStringConvertible {
    var type: MooseType { get }
}

class IntegerObj: Object {
    let type: MooseType = .Int
    let value: Int?

    init(value: Int?) {
        self.value = value
    }

    var description: String {
        "\(value?.description ?? "nil")"
    }
}

class VoidObj: Object {
    let type: MooseType = .Void

    var description: String { type.description }
}
