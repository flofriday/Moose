//
//  File.swift
//
//
//  Created by Johannes Zottele on 17.08.22.
//

import Foundation

extension Typechecker {
    func visit(_ node: ForEachStatement) throws {
        isLoop = true
        try node.list.accept(self)

        guard let typ = (node.list.mooseType as? ListType)?.type else {
            throw error(message: "Expression `\(node.list)` in for each loop must be of type List, but is of type \(node.list.mooseType!)", node: node.list)
        }

        guard node.variable.isAssignable else {
            throw error(message: "For each loop can only have identifiers on left side of `in`.", node: node.variable)
        }
        let (valid, vars) = validLoopVar(variable: node.variable)
        guard valid else {
            throw error(message: "For each loop can only have identifiers on left side of `in`.", node: node.variable)
        }

        for v in vars {
            guard !scope.has(variable: v.value) else {
                throw error(message: "Variable `\(v)` in for each loop must be new and is not allowed to exist in current scope.", node: node.variable)
            }
        }

        let location = node.variable.location.mergeLocations(node.list.location)
        let assignStmt = AssignStatement(token: node.token, location: location, assignable: node.variable, value: node.list, mutable: false, type: nil)

        pushNewScope()
        try assign(valueType: typ, to: node.variable, with: nil, on: assignStmt)
        try node.body.accept(self)
        try popScope()
        node.returnDeclarations = node.body.returnDeclarations
        isLoop = false
    }

    private func validLoopVar(variable: Assignable) -> (valid: Bool, vars: [Identifier]) {
        if let variable = variable as? Identifier { return (true, [variable]) }
        guard let tuple = variable as? Tuple else { return (false, []) }
        return tuple.expressions.reduce((true, [])) { (acc: (Bool, [Identifier]), curr: Expression) -> (Bool, [Identifier]) in
            let n = validLoopVar(variable: curr as! Assignable)
            return (acc.0 && n.valid, acc.1 + n.vars)
        }
    }

    func visit(_ node: ForCStyleStatement) throws {
        isLoop = true
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
        isLoop = false
    }

    func visit(_ node: Break) throws {
        guard isLoop else { throw error(message: "`break` is only allowed inside a loop body.", node: node) }
    }

    func visit(_ node: Continue) throws {
        guard isLoop else { throw error(message: "`continue` is only allowed inside a loop body.", node: node) }
    }
}
