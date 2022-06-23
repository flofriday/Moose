//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

// A helperclass that spawns the initial global scope.
// Note: ok there is a pretty big limitation and that is that you can only call funtions in the
// global scope that were already defined. This also applies to custom operations, but otherwise we would need a pass
// for classes and functions and one for global variables so yeah.
// b: Int = 1 + a()
// func a() -> Int ...
class GlobalScopeExplorer: BaseVisitor {
    let scope: TypeScope
    let program: Program

    init(program: Program, scope: TypeScope) {
        self.scope = scope
        self.program = program
        super.init("Should not be explored by GlobalScopeExplorer.")
    }

    func spawn() throws -> TypeScope {
        // TODO: add more native functions
//        try scope.addFunc(name: "print", args: [.String], returnType: nil)

        // start exploring
        try visit(program)
        return scope
    }

    override func visit(_ node: Program) throws {
        for stmt in node.statements {
            switch stmt {
            case is OperationStatement:
                fallthrough
            case is FunctionStatement:
                try stmt.accept(self)
            // assignment not needed since evaluation order is well defined
            // case is AssignmentStatement:
            // try stmt.accept(self)
            default:
                break
            }
        }
    }

    override func visit(_ node: FunctionStatement) throws {
        let paramTypes = node.params.map { $0.declaredType }
        do {
            try scope.add(function: node.name.value, args: paramTypes, returnType: node.returnType)
        } catch let err as ScopeError {
            throw error(message: err.message, token: node.token)
        }
    }

    override func visit(_ node: OperationStatement) throws {
        let paramTypes = node.params.map { $0.declaredType }
        guard !scope.has(op: node.name, opPos: node.position, args: paramTypes, includeEnclosing: false) else {
            throw error(message: "Operation is already defined with the same signature", token: node.token)
        }
        do {
            try scope.add(op: node.name, opPos: node.position, args: paramTypes, returnType: node.returnType)
        } catch let err as ScopeError {
            throw error(message: err.message, token: node.token)
        }
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
