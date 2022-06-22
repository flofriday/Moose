//
// Created by flofriday on 21.06.22.
//

import Foundation

// The typechecker not only validates types it also checks that all variables and functions
// are visible.
class Typechecker: Visitor {
    var isGlobal = true
    var isFunction = false
    var functionReturnType: MooseType?
    var errors: [CompileErrorMessage] = []
    var scope: Scope

    init() {
        self.scope = Scope()
    }

    func check(program: Program) throws {
        try program.accept(self)

        let scopeSpawner = GlobalScopeExplorer(program: program, scope: scope)
        scope = try scopeSpawner.spawn()

        guard errors.count == 0 else {
            throw CompileError(messages: errors)
        }
    }

    func visit(_ node: Program) throws {
        for stmt in node.statements {
            do {
                try stmt.accept(self)
            } catch let error as CompileErrorMessage {
                errors.append(error)
            }
        }
    }

    func visit(_ node: BlockStatement) throws {
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

    func visit(_ node: IfStatement) throws {
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

    func visit(_ node: Tuple) throws {
        var types: [MooseType] = []

        for expr in node.expressions {
            try expr.accept(self)
            types.append(expr.mooseType!)
        }

        node.mooseType = .Tuple(types)
    }

    func visit(_ node: Nil) throws {
        node.mooseType = .Nil
    }

    func visit(_ node: CallExpression) throws {}

    func visit(_ node: AssignStatement) throws {
        // Calculate the type of the experssion (right side)
        try node.value.accept(self)
        let valueType = node.value.mooseType!

        // Verify that the explicit expressed type (if availble) matches the type of the expression
        if let expressedType = node.type {
            guard try MooseType.from(node.type!) == valueType else {
                throw error(message: "The expression on the right produces a value of the type \(valueType) but you explicitly require the type to be \(expressedType).", token: node.token)
            }
        }

        // TODO: in the future we want more than just variable assignment to work here
        let name: String!
        switch node.assignable {
        case let id as Identifier:
            name = id.value
        default:
            throw error(message: "NOT IMPLEMENTED: can only parse identifiers for assign", token: node.token)
        }

        // The following checks only will make sense if you are not in the global scope
        guard !isGlobal else {
            return
        }

        // Checks to do if the variable was already initialized
        if scope.hasVar(name: name, includeEnclosing: true) {
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
                throw error(message: "Variable '\(name)' is has the type \(currentType), but the expression on the right produces a value of the type \(valueType) ", token: node.token)
            }
        } else {
            try scope.addVar(name: name, type: valueType, mutable: node.mutable)
        }
    }

    func visit(_ node: ReturnStatement) throws {}

    func visit(_ node: ExpressionStatement) throws {
        try node.expression.accept(self)
    }

    func visit(_ node: Identifier) throws {}

    func visit(_ node: IntegerLiteral) throws {
        node.mooseType = .Int
    }

    func visit(_ node: Boolean) throws {
        node.mooseType = .Bool
    }

    func visit(_ node: StringLiteral) throws {
        node.mooseType = .String
    }

    func visit(_ node: PrefixExpression) throws {}

    func visit(_ node: InfixExpression) throws {}

    func visit(_ node: PostfixExpression) throws {}

    func visit(_ node: VariableDefinition) throws {}

    func visit(_ node: FunctionStatement) throws {
        let wasGlobal = isGlobal

        // Some Code

        isGlobal = wasGlobal
    }

    func visit(_ node: ValueType) throws {}

    private func error(message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
            line: token.line,
            startCol: token.column,
            endCol: token.column + token.lexeme.count,
            message: message
        )
    }
}

// A helperclass that spawns the initial global scope.
// Note: ok there is a pretty big limitation and that is that you can only call funtions in the
// global scope that were already defined. This also applies to custom operations, but otherwise we would need a pass
// for classes and functions and one for global variables so yeah.
// b: Int = 1 + a()
// func a() -> Int ...
//
// func a() -> Int ...
// b = 1 + a()
class GlobalScopeExplorer: Visitor {
    let scope: Scope
    let program: Program

    init(program: Program, scope: Scope) {
        self.scope = scope
        self.program = program
    }

    func spawn() throws -> Scope {
        // TODO: add more native functions
        try scope.addFunc(name: "print", args: [.String], returnType: nil)
        return scope
    }

    func visit(_ node: Program) throws {
        for stmt in node.statements {
            try stmt.accept(self)
        }
    }

    func visit(_ node: BlockStatement) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: IfStatement) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: Tuple) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: Nil) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: CallExpression) throws {}

    /// Checks initial assignment types
    /// If assignment, it must have a declared type if it is a declaration.
    ///
    /// - Parameter node: assign statement
    /// - Throws:
    func visit(_ node: AssignStatement) throws {
        guard let assignable = node.assignable as? Declareable else {
            return
        }

        // check if it is declaration or just assignment. If it is a declaration without type, throw error
        guard let vType = node.type else {
            for n in assignable.idents {
                guard scope.hasVar(name: n.value) else {
                    throw error(message: "Assignments in global scope must be explicitly typed.", token: n.token)
                }
            }
            // we are not interrest in this assignment since it is no declaration
            return
        }

        // now we know that we have a type declaration with type definition.
        // we dont check if the assignment is currect, since this is done by the type checker
        if let ident = assignable as? Identifier {
            let valType = try MooseType.from(vType)
            try scope.addVar(name: ident.value, type: valType, mutable: node.mutable)
        } else if let tuple = assignable as? Tuple {
            guard case .Tuple(let valTypes) = try MooseType.from(vType) else {
                throw error(message: "Type of tuple is not tuple", token: node.token)
            }
            guard tuple.expressions.count == valTypes.count else {
                throw error(message: "Tuple has not the same amount of length as type declares", token: node.token)
            }
            for (i, (e, t)) in zip(tuple.expressions, valTypes).enumerated() {
                guard let e = e as? Identifier else {
                    throw error(message: "\(i + 1). element of tuple is not an identier.", token: node.token)
                }
                try scope.addVar(name: e.value, type: t, mutable: node.mutable)
            }

        } else {
            throw error(message: "Assignment for '\(type(of: node.assignable))' is not supported.", token: node.token)
        }
    }

    func visit(_ node: ReturnStatement) throws {
        // We don't need to do this now
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: ExpressionStatement) throws {
        // We don't need to do this now
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: Identifier) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: IntegerLiteral) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: Boolean) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: StringLiteral) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: PrefixExpression) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: InfixExpression) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: PostfixExpression) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: VariableDefinition) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: FunctionStatement) throws {
        throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
    }

    func visit(_ node: ValueType) throws {
        // throw error(message: "Should not be explored by GlobalScopeExplorer.", token: node.token)
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
