//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation

extension Typechecker {
    func visit(_ node: List) throws {
        // if no expressions in list, type of list is Nil
        guard !node.expressions.isEmpty else {
            node.mooseType = NilType()
            return
        }

        let listType = try node.expressions.reduce(nil) { (acc: MooseType?, curr) in
            try curr.accept(self)
            guard let acc = acc else {
                return curr.mooseType
            }
            guard acc == curr.mooseType else {
                throw error(message: "`\(curr.description)` is of type `\(curr.mooseType!.description)`, but previous list entry is of type `\(acc.description)`.\nTip: Lists have to be homogen.", node: node)
            }
            return acc
        }

        guard let listType = listType as? ParamType else {
            throw error(message: "Type of list `\(listType?.description ?? "list")` is not a valid type for Lists.", node: node)
        }

        node.mooseType = ListType(listType)
    }

    func visit(_ node: IndexExpression) throws {
        try node.indexable.accept(self)

        guard let listtype = (node.indexable.mooseType as? ListType)?.type else {
            throw error(message: "`\(node.indexable.description)` is of type `\(node.indexable.mooseType!)`, but index access requires a List.", node: node.indexable)
        }

        try node.index.accept(self)
        guard node.index.mooseType is IntType else {
            throw error(message: "Index expression `\(node.index.description)` must be an `Int` but is of type `\(node.index.mooseType!)`", node: node.index)
        }

        node.mooseType = listtype
    }
}
