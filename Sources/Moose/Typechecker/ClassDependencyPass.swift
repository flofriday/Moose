//
//  File.swift
//
//
//  Created by Johannes Zottele on 01.09.22.
//

import Foundation

class ClassDependecyPass: BaseVisitor {
    var scope: TypeScope
    let program: Program

    var errors = [CompileErrorMessage]()

    init(program: Program, scope: TypeScope) {
        self.scope = scope
        self.program = program
        super.init("Should not be explored by third typcheckin pass.")
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
                case is ClassStatement:
                    try stmt.accept(self)
                default:
                    return
                }
            } catch let err as CompileErrorMessage {
                errors.append(err)
                scope = oldScope
            }
        }
    }

    override func visit(_ node: ClassStatement) throws {
        guard scope.isGlobal() else {
            throw error(message: "INTERNAL ERROR: Classes can only be defined in global scope. Should already be checked in GlobalScopeExplorer!", node: node)
        }

        guard let clasScope = scope.getScope(clas: node.name.value) else {
            throw error(message: "Scope of class `\(node.name.value)` was not found in global scope!", node: node)
        }

        if let extends = node.extends {
            guard let extendClass = scope.getScope(clas: extends.value) else {
                throw error(message: "Class `\(extends.value)` was not found, so `\(node.name.value)` can not extend it.", node: extends)
            }

            clasScope.superClass = extendClass
        }
    }

    internal func error(message: String, node: Node) -> CompileErrorMessage {
        let locator = AstLocator(node: node)
        let location = locator.getLocation()

        return CompileErrorMessage(
            line: location.line,
            startCol: location.col,
            endCol: location.endCol,
            message: message
        )
    }
}
