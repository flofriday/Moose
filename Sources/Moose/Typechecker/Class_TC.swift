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

        let prevScope = scope
        scope = clasScope

        // Check all methods and compare their declared type with the actual return type
        for meth in node.methods {
            try meth.accept(self)
        }

        scope = prevScope
    }

    func visit(_ node: Dereferer) throws {
        // search for scope and check on this scope
        try node.obj.accept(self)

        guard case let .Class(className) = node.obj.mooseType else {
            throw error(message: "Expected object of class. Instead got object of type \(node.obj.mooseType?.description ?? "Unknown").", node: node.obj)
        }

        guard let classScope = scope.getScope(clas: className) else {
            throw error(message: "No class `\(className)` found in scope.", node: node)
        }

        let prevScope = scope
        scope = classScope

        try node.referer.accept(self)
        node.mooseType = node.referer.mooseType

        scope = prevScope
    }
}
