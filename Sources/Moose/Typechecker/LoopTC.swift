//
//  File.swift
//
//
//  Created by Johannes Zottele on 17.08.22.
//

import Foundation

extension Typechecker {
    func visit(_ node: ForEachStatement) throws {
        try node.list.accept(self)

        guard let typ = (node.list.mooseType as? ListType)?.type else {
            throw error(message: "Expression `\(node.list)` in for each loop must be of type List, but is of type \(node.list.mooseType!)", node: node.list)
        }

        guard !scope.has(variable: node.variable.value) else {
            throw error(message: "Variable `\(node.variable)` in for each loop must be new and is not allowed to exist in current scope.", node: node.variable)
        }

        pushNewScope()
        try scope.add(variable: node.variable.value, type: typ, mutable: false)
        try node.body.accept(self)
        try popScope()
        node.returnDeclarations = node.body.returnDeclarations
    }

    func visit(_ node: ForCStyleStatement) throws {
        pushNewScope()
        try node.preStmt?.accept(self)
        try node.condition.accept(self)
        try node.postEachStmt?.accept(self)

        guard node.condition.mooseType is BoolType else {
            throw error(message: "Condition of loop must have type Bool, but `\(node.condition)` has type \(node.condition.mooseType!)", node: node.condition)
        }

        try node.body.accept(self)
        node.returnDeclarations = node.body.returnDeclarations
        try popScope()
    }
}
