//
// Created by flofriday on 21.06.22.
//

import Foundation

// The typechecker not only validates types it also checks that all variables and functions
// are visible.
class Typechecker: BaseVisitor {
    var isGlobal = true
    var isFunction = false
    var functionReturnType: MooseType?
    var errors: [CompileErrorMessage] = []
    var scope: Scope

    init() {
        self.scope = Scope()
        super.init("Typechecker is not yet implemented for this scope.")
    }

    func check(program: Program) throws {
        // clear errors
        errors = []

        let scopeSpawner = GlobalScopeExplorer(program: program, scope: scope)
        scope = try scopeSpawner.spawn()
        try scopeSpawner.visit(program)

        try program.accept(self)

        guard errors.count == 0 else {
            throw CompileError(messages: errors)
        }
    }

    override func visit(_ node: Program) throws {
        for stmt in node.statements {
            do {
                try stmt.accept(self)
            } catch let error as CompileErrorMessage {
                errors.append(error)
            }
        }
    }

    override func visit(_ node: BlockStatement) throws {
        let wasGlobal = isGlobal

        for stmt in node.statements {
            do {
                try stmt.accept(self)
            } catch let error as CompileErrorMessage {
                errors.append(error)
            }
        }

        isGlobal = wasGlobal
    }

    override func visit(_ node: IfStatement) throws {
        try node.condition.accept(self)
        guard node.condition.mooseType == .Bool else {
            // TODO: the Error highlights the wrong character here
            throw error(message: "The condition `\(node.condition.description)` evaluates to a \(String(describing: node.condition.mooseType)) but if-conditions need to evaluate to Bool.", token: node.token)
        }

        try node.consequence.accept(self)

        if let alternative = node.alternative {
            try alternative.accept(self)
        }
    }

    override func visit(_ node: Tuple) throws {
        var types: [MooseType] = []

        for expr in node.expressions {
            try expr.accept(self)
            types.append(expr.mooseType!)
        }

        node.mooseType = .Tuple(types)
    }

    override func visit(_ node: Nil) throws {
        node.mooseType = .Nil
    }

    override func visit(_ node: CallExpression) throws {
        throw error(message: "NOT IMPLEMENTED: can only parse identifiers for assign", token: node.token)
    }

    override func visit(_ node: AssignStatement) throws {
        // Calculate the type of the experssion (right side)
        try node.value.accept(self)
        let valueType = node.value.mooseType!

        // Verify that the explicit expressed type (if availble) matches the type of the expression
        if let expressedType = node.declaredType {
            guard node.declaredType == valueType else {
                throw error(message: "The expression on the right produces a value of the type \(valueType) but you explicitly require the type to be \(expressedType).", token: node.token)
            }
        }

        // TODO: in the future we want more than just variable assignment to work here
        var name: String?
        switch node.assignable {
        case let id as Identifier:
            name = id.value
        default:
            throw error(message: "NOT IMPLEMENTED: can only parse identifiers for assign", token: node.token)
        }

        guard let name = name else {
            throw error(message: "INTERNAL ERROR: could not extract name from assignable", token: node.assignable.token)
        }

        // Checks to do if the variable was already initialized
        if scope.hasVar(name: name, includeEnclosing: true) {
            if let t = node.declaredType {
                throw error(message: "Type declarations are only possible for new variable declarations. Variable '\(name)' already exists.\nTipp: Remove `: \(t.description)`", token: node.assignable.token)
            }

            // Check that the variable wasn mutable
            guard scope.isVarMut(name: name, includeEnclosing: true) else {
                throw error(message: "Variable '\(name)' is inmutable and cannot be reassigned.\nTipp: Define '\(name)' as mutable with the the `mut` keyword.", token: node.token)
            }

            // Check that this new assignment doesn't have the mut keyword as the variable already exists
            guard !node.mutable else {
                throw error(message: "Variable '\(name)' was already declared, so the `mut` keyword doesn't make any sense here.\nTipp: Remove the `mut` keyword.", token: node.token)
            }

            // Check that the new assignment still has the same type from the initialization
            let currentType = try scope.getVarType(name: name)
            guard currentType == valueType else {
                throw error(message: "Variable '\(name)' has the type \(currentType), but the expression on the right produces a value of the type \(valueType).", token: node.value.token)
            }
        } else {
            try scope.addVar(name: name, type: valueType, mutable: node.mutable)
        }
    }

    override func visit(_ node: ReturnStatement) throws {
        try node.returnValue.accept(self)
    }

    override func visit(_ node: ExpressionStatement) throws {
        try node.expression.accept(self)
    }

    override func visit(_ node: Identifier) throws {
        throw error(message: "NOT IMPLEMENTED: can only parse identifiers for assign", token: node.token)
    }

    override func visit(_ node: IntegerLiteral) throws {
        node.mooseType = .Int
    }

    override func visit(_ node: Boolean) throws {
        node.mooseType = .Bool
    }

    override func visit(_ node: StringLiteral) throws {
        node.mooseType = .String
    }

    override func visit(_ node: FunctionStatement) throws {
        let wasGlobal = isGlobal

        // Some Code

        isGlobal = wasGlobal
    }

    override func visit(_ node: OperationStatement) throws {
        let wasGlobal = isGlobal
        isGlobal = false

        guard wasGlobal else {
            throw error(message: "Operator definition is only allowed in global scope.", token: node.token)
        }

        try node.body.accept(self)

        // get real return type
        var realReturnValue: MooseType = .Void
        if let lastStmt = node.body.statements.last, let retStmt = lastStmt as? ReturnStatement {
            guard let typ = retStmt.returnValue.mooseType else {
                throw error(message: "Could not determine return type of body", token: retStmt.token)
            }
            realReturnValue = typ
        }

        // compare declared and real returnType
        guard realReturnValue == node.returnType else {
            throw error(message: "Return type of operator is \(realReturnValue), not \(node.returnType) as declared in signature", token: node.token)
        }

        // TODO: assure it is in scope

        isGlobal = wasGlobal
    }

    private func error(message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
            line: token.line,
            startCol: token.column,
            endCol: token.column + token.lexeme.count,
            message: message
        )
    }
}
