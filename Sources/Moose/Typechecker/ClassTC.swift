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
            throw error(message: "Class can only be defined in global scope.", node: node)
        }

        guard let clasScope = scope.getScope(clas: node.name.value) else {
            throw error(message: "Scope of class `\(node.name.value)` was not found in global scope!", node: node)
        }

        // Check if there are dependency circles (like `A < A` or `A < B, B < A`)
        try checkCycle(for: node.name, in: clasScope)

        do {
            try clasScope.flat()
        } catch let err as ScopeError {
            throw error(message: err.message, node: node)
        }

        // check if declared types exist
        try node.properties.forEach {
            try $0.accept(self)
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

    func visit(_ node: ExtendStatement) throws {
        guard scope.isGlobal() else {
            throw error(message: "Extend statements can only be defined in global scope.", node: node)
        }

        guard let clasScope = scope.getScope(clas: node.name.value) else {
            throw error(message: "Class `\(node.name.value)` does not exist.", node: node)
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

        guard let type = (node.obj.mooseType as? AnyType) else {
            throw error(message: "Expected object of AnyType. Instead got object of type \(node.obj.mooseType?.description ?? "Unknown").", node: node.obj)
        }

        var wasClosed = scope.closed
        scope.closed = false

        let classScope: ClassTypeScope!
        do {
            classScope = try type.inferredClass()
        } catch let err as ScopeError {
            throw error(message: "Couldn't get class: \(err.message)", node: node)
        }
        scope.closed = wasClosed

        // We set the param scope since params have to be in current scope not in class scope
        // like: `func a() { b = 2; obj.call(b) }` would not find b
        let prevParamScope = paramScope
        // when derefering multiple times, only the first deref should change paramScope
        paramScope = paramScope == nil ? scope : paramScope

        // We do this since in case of
        // me.call( a.set(x), b) we want that a.set is closed, so we have to disable the
        // argumentCheck
        let prevArgCheck = TypeScope.argumentCheck
        TypeScope.argumentCheck = false

        let prevScope = scope
        scope = classScope

        wasClosed = scope.closed
        scope.closed = true

        try node.referer.accept(self)
        node.mooseType = node.referer.mooseType

        scope.closed = wasClosed
        scope = prevScope

        TypeScope.argumentCheck = prevArgCheck

        paramScope = prevParamScope
    }
}
