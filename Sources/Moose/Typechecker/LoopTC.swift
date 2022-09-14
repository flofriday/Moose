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
            throw error(header: "Type Mismatch", message: "Expression `\(node.list)` in for each loop must be of type List, but is of type \(node.list.mooseType!)", node: node.list)
        }

        guard node.variable.isAssignable else {
            throw error(header: "Variable Error", message: "For each loop can only have identifiers on left side of `in`.", node: node.variable)
        }
        let (valid, vars) = validLoopVar(variable: node.variable)
        guard valid else {
            throw error(header: "Variable Error", message: "For each loop can only have identifiers on left side of `in`.", node: node.variable)
        }

        for v in vars {
            guard !scope.has(variable: v.value) else {
                throw error(header: "Variable Error", message: "Variable `\(v)` in for each loop must be new and is not allowed to exist in current scope.", node: node.variable)
            }
        }

        let location = Location(node.variable.location, node.list.location)
        let assignStmt = AssignStatement(token: node.token, location: location, assignable: node.variable, value: node.list, mutable: false, type: nil)

        pushNewScope()
        try assign(valueType: typ, to: node.variable, with: nil, on: assignStmt)
        let prevLoop = isLoop
        isLoop = true
        try node.body.accept(self)
        isLoop = prevLoop
        try popScope()
        node.returnDeclarations = node.body.returnDeclarations
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
        pushNewScope()
        try node.preStmt?.accept(self)
        try node.condition.accept(self)
        try node.postEachStmt?.accept(self)

        guard node.condition.mooseType is BoolType else {
            throw error(header: "Type Mismatch", message: "Condition of loop must have type Bool, but `\(node.condition)` has type \(node.condition.mooseType!)", node: node.condition)
        }

        let prevLoop = isLoop
        isLoop = true
        try node.body.accept(self)
        isLoop = prevLoop

        node.returnDeclarations = node.body.returnDeclarations
        try popScope()
    }

    func visit(_ node: Break) throws {
        guard isLoop else { throw error(header: "Illegal Break", message: "`break` is only allowed inside a loop body.", node: node) }
    }

    func visit(_ node: Continue) throws {
        guard isLoop else { throw error(header: "Illegal Continue", message: "`continue` is only allowed inside a loop body.", node: node) }
    }
}
