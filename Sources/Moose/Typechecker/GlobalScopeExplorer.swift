//
//  GlobalScopeExplorer.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

// A helperclass that populates the global scope.
// Note: ok there is a pretty big limitation and that is that you can only call funtions in the
// global scope that were already defined. This also applies to custom operations, but otherwise we would need a pass
// for classes and functions and one for global variables so yeah.
// b: Int = 1 + a()
// func a() -> Int ...
class GlobalScopeExplorer: BaseVisitor {
    var scope: TypeScope
    let program: Program

    var errors = [CompileErrorMessage]()

    init(program: Program, scope: TypeScope) {
        self.scope = scope
        self.program = program
        super.init("Should not be explored by GlobalScopeExplorer.")
    }

    func populate() throws -> TypeScope {
        try visit(program)

        guard errors.count == 0 else {
            throw CompileError(messages: errors)
        }

        return scope
    }

    override func visit(_ node: Program) throws {
        for stmt in node.statements {
            let oldScope = scope
            do {
                switch stmt {
                case is OperationStatement:
                    fallthrough
                case is FunctionStatement:
                    try stmt.accept(self)
                case is ClassStatement:
                    try stmt.accept(self)
                default:
                    break
                }
            } catch let err as CompileErrorMessage {
                errors.append(err)
                scope = oldScope
            }
        }
    }

    override func visit(_ node: FunctionStatement) throws {
        let paramTypes = node.params.map {
            $0.declaredType
        }
        do {
            try scope.add(function: node.name.value, params: paramTypes, returnType: node.returnType)
        } catch let err as ScopeError {
            throw error(header: "Function Redefinition", message: err.message, token: node.token)
        }
    }

    override func visit(_ node: OperationStatement) throws {
        let paramTypes = node.params.map {
            $0.declaredType
        }
        do {
            try scope.add(op: node.name, opPos: node.position, params: paramTypes, returnType: node.returnType)
        } catch let err as ScopeError {
            throw error(header: "Operation Redefinition", message: err.message, token: node.token)
        }
    }

    // TODO: Check if class is already defined
    override func visit(_ node: ClassStatement) throws {
        guard scope.isGlobal() else {
            throw error(header: "Bad class declaration", message: "Classes can only be defined in global scope.", node: node)
        }

        guard !scope.has(clas: node.name.value) else {
            throw error(header: "Class Redefinition", message: "Class `\(node.name)` was already defined.", node: node)
        }

        let classScope = ClassTypeScope(
            enclosing: scope,
            name: node.name.value,
            properties: node.properties.map { (name: $0.name.value, $0.declaredType, $0.mutable) }
        )

        for prop in node.properties {
            try classScope.add(variable: prop.name.value, type: prop.declaredType, mutable: prop.mutable)
        }

        for meth in node.methods {
            try classScope.add(function: meth.name.value, params: meth.params.map { $0.declaredType }, returnType: meth.returnType)
        }

        try scope.add(clas: node.name.value, scope: classScope)
    }

    private func error(header: String, message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
            location: locationFromToken(token),
            header: header,
            message: message
        )
    }

    private func error(header: String, message: String, node: Node) -> CompileErrorMessage {
        return CompileErrorMessage(
            location: node.location,
            header: header,
            message: message
        )
    }
}
