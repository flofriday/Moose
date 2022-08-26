//
//  File.swift
//
//
//  Created by Johannes Zottele on 10.08.22.
//

import Foundation

extension Typechecker {
    func visit(_ node: ClassStatement) throws {
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
            // TODO: We need to check for cycles... so if there are dependency cycles
            try checkCycle(for: extends, in: extendClass)
        }

        do {
            try clasScope.flat()
        } catch let err as ScopeError {
            throw error(message: err.message, node: node)
        }

        let prevScope = scope
        scope = clasScope

        // Check all methods and compare their declared type with the actual return type
        for meth in node.methods {
            try meth.accept(self)
        }

        scope = prevScope
    }

    /// check if class inhertiance has dependecy circle
    private func checkCycle(for name: Identifier, in clas: ClassTypeScope) throws {
        guard name.value != clas.superClass?.className else {
            throw error(message: "Class `\(name.value)` results in a dependency circle, since `\(clas.className)` extends it, but is also a dependecy of `\(name.value)`", node: name)
        }

        if let superClass = clas.superClass {
            try checkCycle(for: name, in: superClass)
        }
    }

    func visit(_ node: Dereferer) throws {
        // search for scope and check on this scope
        try node.obj.accept(self)

        guard let className = (node.obj.mooseType as? AnyType)?.asClass?.name else {
            throw error(message: "Expected object of class. Instead got object of type \(node.obj.mooseType?.description ?? "Unknown").", node: node.obj)
        }

        var wasClosed = scope.closed
        scope.closed = false
        guard let classScope = scope.getScope(clas: className) else {
            throw error(message: "No class `\(className)` found in scope.", node: node)
        }
        scope.closed = wasClosed

        let prevScope = scope
        scope = classScope
        wasClosed = scope.closed
        scope.closed = true

        try node.referer.accept(self)
        node.mooseType = node.referer.mooseType

        scope.closed = wasClosed
        scope = prevScope
    }
}
