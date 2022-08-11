//
//  File.swift
//
//
//  Created by Johannes Zottele on 11.08.22.
//

import Foundation

extension Typechecker {
    func visit(_ node: OperationStatement) throws {
        let wasFunction = isFunction
        isFunction = true

        guard scope.isGlobal() else {
            throw error(message: "Operator definition is only allowed in global scope.", node: node)
        }

        pushNewScope()
        for param in node.params {
            try scope.add(variable: param.name.value, type: param.declaredType, mutable: false)
        }

        try node.body.accept(self)

        // get real return type
        var realReturnValue: MooseType = .Void
        if let (typ, eachBranch) = node.body.returnDeclarations {
            // if functions defined returnType is not Void and not all branches return, function body need explizit return at end
            guard node.returnType == .Void || eachBranch else {
                throw error(message: "Return missing in operator body.\nTipp: Add explicit return with value of type '\(node.returnType)' to end of operator body", node: node.body.statements.last ?? node.body)
            }
            realReturnValue = typ
        }

        // compare declared and real returnType
        guard realReturnValue == node.returnType else {
            // TODO: We highlight the wrong thing here
            throw error(message: "Return type of operator is \(realReturnValue), not \(node.returnType) as declared in signature", token: node.token)
        }

        // TODO: assure it is in scope

        try popScope()
        isFunction = wasFunction
    }

    func visit(_ node: InfixExpression) throws {
        do {
            node.mooseType = try checkOperationsType(op: node.op, operands: [node.left, node.right], token: node.token)
        } catch let err as ScopeError {
            throw error(message: "Couldn't determine return type of infix operator: \(err.message)", node: node)
        }
    }

    func visit(_ node: PrefixExpression) throws {
        do {
            node.mooseType = try checkOperationsType(op: node.op, operands: [node.right], token: node.token)
        } catch let err as ScopeError {
            throw error(message: "Couldn't determine return type of prefix operator: \(err.message)", node: node)
        }
    }

    func visit(_ node: PostfixExpression) throws {
        do {
            node.mooseType = try checkOperationsType(op: node.op, operands: [node.left], token: node.token)
        } catch let err as ScopeError {
            throw error(message: "Couldn't determine return type of postfix operator: \(err.message)", node: node)
        }
    }

    private func checkOperationsType(op: String, operands: [Expression], token: Token) throws -> MooseType {
        guard case let .Operator(pos: opPos, assign: assign) = token.type else {
            throw error(message: "INTERNAL ERROR: token type should be .Operator, but got \(token.type) instead.", token: token)
        }

        // if it is an assign operation, check if most left operand is identifier
        if assign {
            guard let ident = operands[0] as? Identifier, scope.has(variable: ident.value) else {
                throw error(message: "Assign operations can only be made on variables that already exist. `\(operands[0])` must be declared seperatly.", node: operands[0])
            }
        }

        try operands.forEach { try $0.accept(self) }
        return try scope.returnType(op: op, opPos: opPos, params: operands.compactMap { $0.mooseType })
    }
}
