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
                case is ExtendStatement:
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

    override func visit(_ node: ClassStatement) throws {
        guard scope.isGlobal() else {
            throw error(header: "Internal Error", message: "INTERNAL ERROR: Classes can only be defined in global scope. Should already be checked in GlobalScopeExplorer!", node: node)
        }

        guard let clasScope = scope.getScope(clas: node.name.value) else {
            throw error(header: "Scope Not Found", message: "Scope of class `\(node.name.value)` was not found in global scope!", node: node)
        }

        if let extends = node.extends {
            guard let extendClass = scope.getScope(clas: extends.value) else {
                throw error(header: "Class Error", message: "Class `\(extends.value)` was not found, so `\(node.name.value)` can not extend it.", node: extends)
            }

            clasScope.superClass = extendClass
        }
    }

    override func visit(_ node: ExtendStatement) throws {
        guard scope.isGlobal() else {
            throw error(header: "Illegal Extension", message: "Class extensions can only be defined in global scope.", node: node)
        }

        guard MooseType.toType(node.name.value) is ClassType else {
            throw error(header: "Illegal Extension", message: "BuiltIn classes cannot be extended.", node: node)
        }

        guard let classScope = scope.getScope(clas: node.name.value) else {
            throw error(header: "Class Error", message: "Class `\(node.name.value)` is not defined.", node: node)
        }

        for meth in node.methods {
            let paramTypes = meth.params.map { $0.declaredType }
            guard !classScope.has(function: meth.name.value, params: paramTypes) else {
                throw error(header: "Method Redefinition", message: "Method `\(meth.name.value)(\(paramTypes.map { $0.description }.joined(separator: ", ")))` is already defined in class `\(classScope.className)`.", node: meth)
            }

            try classScope.add(function: meth.name.value, params: paramTypes, returnType: meth.returnType)
        }
    }

    internal func error(header: String, message: String, node: Node) -> CompileErrorMessage {
        return CompileErrorMessage(
            location: node.location,
            header: header,
            message: message
        )
    }
}
