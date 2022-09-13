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
            throw error(header: "Illegal Operator Definition", message: "Operator definition is only allowed in global scope.", node: node)
        }

        pushNewScope()
        for param in node.params {
            try scope.add(variable: param.name.value, type: param.declaredType, mutable: false)
        }

        try node.body.accept(self)

        // get real return type
        var realReturnValue: MooseType = VoidType()
        if let (typ, eachBranch) = node.body.returnDeclarations {
            // if functions defined returnType is not Void and not all branches return, function body need explizit return at end
            guard node.returnType is VoidType || eachBranch else {
                throw error(header: "Return Missing", message: "Return missing in operator body.\nTipp: Add explicit return with value of type '\(node.returnType)' to end of operator body", node: node.body.statements.last ?? node.body)
            }
            realReturnValue = typ
        }

        // compare declared and real returnType
        guard realReturnValue == node.returnType else {
            // TODO: We highlight the wrong thing here
            throw error(header: "Type Mismatch", message: "Return type of operator is \(realReturnValue), not \(node.returnType) as declared in signature", node: node)
        }

        // TODO: assure it is in scope

        try popScope()
        isFunction = wasFunction
    }

    func visit(_ node: InfixExpression) throws {
        do {
            let wasClosed = scope.closed
            scope.closed = false
            defer { scope.closed = wasClosed }

            node.mooseType = try checkOperationsType(op: node.op, operands: [node.left, node.right], token: node.token)
        } catch let err as ScopeError {
            // TODO: we schouldn't embed the scope error in the error message
            throw error(header: "Unclear Type", message: "Couldn't determine return type of infix operator: \(err.message)", node: node)
        }
    }

    func visit(_ node: PrefixExpression) throws {
        do {
            let wasClosed = scope.closed
            scope.closed = false
            defer { scope.closed = wasClosed }
            node.mooseType = try checkOperationsType(op: node.op, operands: [node.right], token: node.token)
        } catch let err as ScopeError {
            // TODO: we schouldn't embed the scope error in the error message
            throw error(header: "Unclear Type", message: "Couldn't determine return type of prefix operator: \(err.message)", node: node)
        }
    }

    func visit(_ node: PostfixExpression) throws {
        do {
            let wasClosed = scope.closed
            scope.closed = false
            defer { scope.closed = wasClosed }
            node.mooseType = try checkOperationsType(op: node.op, operands: [node.left], token: node.token)
        } catch let err as ScopeError {
            // TODO: we schouldn't embed the scope error in the error message
            throw error(header: "Unclear Type", message: "Couldn't determine return type of postfix operator: \(err.message)", node: node)
        }
    }

    private func checkOperationsType(op: String, operands: [Expression], token: Token) throws -> MooseType {
        guard case let .Operator(pos: opPos, assign: assign) = token.type else {
            throw error(header: "Internal Error", message: "INTERNAL ERROR: token type should be .Operator, but got \(token.type) instead.", token: token)
        }

        try operands.forEach { try $0.accept(self) }
        let opType = try scope.returnType(op: op, opPos: opPos, params: operands.compactMap { $0.mooseType })

        // if it is an assign operation, check if most left operand is identifier
        if assign {
            guard let ident = operands[0] as? Identifier, scope.has(variable: ident.value) else {
                throw error(header: "Illegal Assign", message: "Assign operations can only be made on variables that already exist. `\(operands[0])` must be declared seperatly.", node: operands[0])
            }

            guard try scope.isMut(variable: ident.value) else {
                throw error(header: "Immutability Violation", message: "Variable `\(ident.value)` is immutable.\nTip: Add the `mut` keyword to the variable declaration.", node: ident)
            }

            guard try scope.typeOf(variable: ident.value) == opType else {
                throw error(header: "Type Mismatch", message: "Variable `\(ident.value)` is of type \(ident.mooseType!.description), but operation `\(op)` with params (\(operands.compactMap { $0.mooseType?.description }.joined(separator: ", "))) produces \(opType).", node: ident)
            }
        }

        return opType
    }
}
