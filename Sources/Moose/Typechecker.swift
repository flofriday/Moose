//
// Created by flofriday on 21.06.22.
//

import Foundation

// The typechecker not only validates types it also checks that all variables and functions
// are visible.
class Typechecker: Visitor {
    let program: Program
    let errors: [CompileErrorMessage] = []
    let scope: Scope

    init(program: Program) {
        self.program = program

        let scopespawner = ScopeSpawner()
        do {
            self.scope = try scopespawner.spawn()
        } catch {
            self.scope = Scope()
        }
    }

    func check() throws {

    }

    func visit(_ view: Program) throws {

    }

    func visit(_ view: AssignStatement) throws {

    }

    func visit(_ view: ReturnStatement) throws {
    }

    func visit(_ view: ExpressionStatement) throws {
    }

    func visit(_ view: Identifier) throws {

    }

    func visit(_ view: IntegerLiteral) throws {

    }

    func visit(_ view: Boolean) throws {
    }

    func visit(_ view: StringLiteral) throws {
    }

    func visit(_ view: PrefixExpression) throws {
    }

    func visit(_ view: InfixExpression) throws {
    }

    func visit(_ view: PostfixExpression) throws {
    }

    func visit(_ view: VariableDefinition) throws {
    }

    func visit(_ view: FunctionStatement) throws {

    }

    func visit(_ view: ValueType) throws {

    }
}

// A helperclass that spawns the initial global scope.
// Note: ok there is a pretty big limitation and that is that you can only call funtions in the
// global scope that were already defined. This also applies to custom operations, but otherwise we would need a pass
// for classes and functions and one for global variables so yeah.
class ScopeSpawner: Visitor {
    let scope = Scope();

    init() {
    }

    func spawn() throws -> Scope {
        // TODO: add more native functions
        try scope.addFunc(name: "print", args: [.String], returnType: nil)
        return scope
    }

    func visit(_ view: Program) throws {
        for stmt in view.statements {
            try stmt.accept(self)
        }
    }

    func visit(_ view: AssignStatement) throws {
        // Calculate the type of the experssion (right side)
        try view.value.accept(self)
        let valueType = view.value.mooseType!

        if let expressedType = view.type {
            guard MooseType.from(view.type!) == valueType else {
                throw error(message: "The expression on the right produces a value of the type \(valueType) but you explicitly require the type to be \(expressedType).", token: view.token)
            }
        }

        let name = view.name.value
        if scope.hasVar(name: name, includeEnclosing: false) {
            let currentType = try scope.getVarType(name: name)
            guard currentType == valueType else {
                throw error(message: "Variable '\(name)' is has the type \(currentType), but the expression on the right produces a value of the type \(valueType) ", token: view.token)
            }
        }

        if !scope.hasVar(name: name, includeEnclosing: false) {
            try scope.addVar(name: name, type: valueType, mutable: view.mutable)
        }
    }

    func visit(_ view: ReturnStatement) throws {
        // We don't need to do this now
    }

    func visit(_ view: ExpressionStatement) throws {
        // We don't need to do this now
    }

    func visit(_ view: Identifier) throws {
        let type = try scope.getIdentifierType(name: view.value)
        //view.mooseType = type


    }

    func visit(_ view: IntegerLiteral) throws {

    }

    func visit(_ view: Boolean) throws {

    }

    func visit(_ view: StringLiteral) throws {

    }

    func visit(_ view: PrefixExpression) throws {

    }

    func visit(_ view: InfixExpression) throws {

    }

    func visit(_ view: PostfixExpression) throws {

    }

    func visit(_ view: VariableDefinition) throws {

    }

    func visit(_ view: FunctionStatement) throws {

    }

    func visit(_ view: ValueType) throws {

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