//
//  File.swift
//
//
//  Created by Johannes Zottele on 11.08.22.
//

import Foundation

extension Typechecker {
    func visit(_ node: AssignStatement) throws {
        // assignable (left side) must be assignable (e.g. not (a,1))
        guard node.assignable.isAssignable else {
            throw error(message: "Assignment to `\(node.assignable)` is not valid since it is not assignable.", node: node.assignable)
        }

        // find duplicate idents (not allowed in single assignment)
        let dups = Dictionary(grouping: node.assignable.assignables.compactMap { ($0 as? Identifier)?.value }, by: { $0 }).filter { $1.count > 1 }.keys
        guard dups.count == 0 else {
            throw error(message: "\(dups.first?.description ?? "") is used multiple times on left side of assignment. Multiple assignemnts of the same variable in a single assignment are not allowed.", node: node)
        }

        try node.value.accept(self)
        try assign(valueType: node.value.mooseType!, to: node.assignable, with: node.declaredType, on: node)
    }

    private func assign(valueType: MooseType, to assignable: Expression, with declaredType: MooseType?, on node: AssignStatement) throws {
        switch assignable {
        // if expression is identifier than assign
        case let ident as Identifier:
            try assign(valueType: valueType, to: ident, with: declaredType, on: node)
        case let tuple as Tuple:
            try assign(valueType: valueType, to: tuple, with: declaredType, on: node)
        case let indexing as IndexExpression:
            try assign(valueType: valueType, to: indexing, with: declaredType, on: node)
        case let dereferer as Dereferer:
            try assign(valueType: valueType, to: dereferer, with: declaredType, on: node)
        default:
            throw error(message: "Assignment to `\(assignable.description)` is not valid.", node: node)
        }
    }

    private func assign(valueType: MooseType, to dereferer: Dereferer, with declaredType: MooseType?, on node: AssignStatement) throws {
        // TODO: is something like `mut A().b = 2` or `A().b: Int = 2` allowed? Currently yes. it just doesnt effect anything.
        if let declaredType = declaredType {
            try checkAssignment(given: declaredType, with: valueType, on: node)
        }

        // TODO: Doesn't work yet! Also if property is not mutable, it cannot get checked!
        try dereferer.accept(self)

        guard let className = (dereferer.obj.mooseType as? ClassType)?.name else {
            throw error(message: "Expected object of class. Instead got object of type \(dereferer.obj.mooseType?.description ?? "Unknown").", node: dereferer.obj)
        }

        guard let classScope = scope.getScope(clas: className) else {
            throw error(message: "No class `\(className)` found in scope.", node: node)
        }

        let oldscope = scope
        scope = classScope

        try assign(valueType: valueType, to: dereferer.referer, with: declaredType, on: node)

        scope = oldscope
    }

    private func assign(valueType: MooseType, to indexing: IndexExpression, with declaredType: MooseType?, on node: AssignStatement) throws {
        // TODO: is something like `mut a[0] = 2` or `a[0]: Int = 2` allowed? Currently yes. it just doesnt effect anything.
        if let declaredType = declaredType {
            try checkAssignment(given: declaredType, with: valueType, on: node)
        }

        // processs own mooseType and check if everything is valid
        try indexing.accept(self)

        try checkAssignment(given: indexing.mooseType!, with: valueType, on: node)
    }

    /// Assignment to tuple
    ///
    /// Checks if it is possible to assign value of type `valueType` to tuple `tuple` with the declaredType `declaredType`
    private func assign(valueType: MooseType, to tuple: Tuple, with declaredType: MooseType?, on node: AssignStatement) throws {
        let tupleElements = try toTupleType(type: valueType, size: tuple.expressions.count, debugNode: node)

        var declaredTypes: [MooseType]?
        if let declaredType = declaredType {
            guard let types = (declaredType as? TupleType)?.entries else {
                throw error(message: "You declared type as \(declaredType) while it should be a Tuple.", node: node)
            }
            declaredTypes = types
        }

        for (i, expr) in tuple.expressions.enumerated() {
            try assign(valueType: tupleElements[i], to: expr, with: declaredTypes?[i], on: node)
        }
    }

    /// Assignment to identifier / variable
    ///
    /// Checks if it is possible to assign value of type `valueType` to variable `variable` with the declaredType `declaredType`
    private func assign(valueType: MooseType, to variable: Identifier, with declaredType: MooseType?, on node: AssignStatement) throws {
        // if assignment is declared with type, check if expression has same type as declared
        if let declaredType = declaredType {
            try checkAssignment(given: declaredType, with: valueType, on: node, to: variable)
        }

        // check if variable exists
        if scope.has(variable: variable.value) {
            let varType = try scope.typeOf(variable: variable.value)

            // TODO: Should it be possible to declare type even for existing variables?
            if let t = node.declaredType {
                // TODO: We highlight the variable here instead of the type declaration. At the time of writing we
                // cannot highlight the declaration because it is not part of the AST and thereby not reachable by the
                // checker.
                throw error(message: "Type declarations are only possible for new variable declarations. Variable '\(variable.value)' already exists.\nTipp: Remove `: \(t.description)`", node: node.assignable)
            }

            // check that tuple to assign has same type as stored variable
            try checkAssignment(given: varType, with: valueType, on: node, to: variable)

            guard try scope.isMut(variable: variable.value) else {
                throw error(message: "Variable `\(variable.value)` is inmutable.\nTip: Make `\(variable.value)` mutable by adding the keyworkd `mut` at its declaration.", node: node)
            }

            guard !node.mutable else {
                throw error(message: "Since variable `\(variable.value)` does already exist in scope, you cannot use the `mut` keyword.", node: node)
            }
        } else {
            let type: MooseType = node.declaredType ?? valueType
            try scope.add(variable: variable.value, type: type, mutable: node.mutable)
        }
    }

    /// Checks if assignType is assignable to givenType
    ///
    /// If given and assign type are class types, check if given type is superclass of assigntype
    /// else check if assigntype is the same es the given type
    internal func checkAssignment(given givenType: MooseType, with assignType: MooseType, on node: Node, to variable: Identifier? = nil) throws {
        guard let givenType = givenType as? ParamType else {
            throw error(message: "INTERNAL ERROR: Given type must be param type.", node: node)
        }

        if assignType is NilType { return }

        switch (given: givenType, assign: assignType) {
        case let t as (ListType, ListType):
            try checkAssignment(givenList: t.0, withList: t.1, on: node, to: variable)
        case let t as (ClassType, ClassType):
            try checkAssignment(givenClass: t.0, withClass: t.1, on: node, to: variable)
        case let t as (TupleType, TupleType):
            try checkAssignment(givenTuple: t.0, withTuple: t.1, on: node, to: variable)
        case let t as (DictType, DictType):
            try checkAssignment(givenDict: t.0, withDict: t.1, on: node, to: variable)
        default:
            guard assignType == givenType else {
                if let variable = variable {
                    throw error(message: "Variable `\(variable.value)` has type `\(givenType.description)` but you try to assign type `\(assignType.description)`.", node: node)
                }
                throw error(message: "You want to assign value of type `\(assignType)` to defined type `\(givenType)`.", node: node)
            }
        }
    }

    private func checkAssignment(givenTuple givenType: TupleType, withTuple assignType: TupleType, on node: Node, to variable: Identifier? = nil) throws {
        guard givenType.entries.count == assignType.entries.count else {
            throw error(message: "Given type \(givenType.description) has \(givenType.entries.count) entries while type to assign \(assignType.description) has \(givenType.entries.count).", node: node)
        }
        try zip(givenType.entries, assignType.entries).forEach {
            try checkAssignment(given: $0.0, with: $0.1, on: node, to: variable)
        }
    }

    private func checkAssignment(givenList givenType: ListType, withList assignType: ListType, on node: Node, to variable: Identifier? = nil) throws {
        try checkAssignment(given: givenType.type, with: assignType.type, on: node, to: variable)
    }

    private func checkAssignment(givenDict givenType: DictType, withDict assignType: DictType, on node: Node, to variable: Identifier? = nil) throws {
        try checkAssignment(given: givenType.keyType, with: assignType.keyType, on: node, to: variable)
        try checkAssignment(given: givenType.valueType, with: assignType.valueType, on: node, to: variable)
    }

    private func checkAssignment(givenClass givenType: ClassType, withClass assignType: ClassType, on node: Node, to variable: Identifier? = nil) throws {
        guard scope.global().has(clas: givenType.name) else { throw error(message: "Class `\(givenType.name)` does not exist.", node: node) }

        guard let valueClassScope = scope.getScope(clas: assignType.name) else { throw error(message: "Class `\(assignType.name)` does not exist.", node: node) }

        guard valueClassScope.extends(clas: givenType.name).extends else {
            throw error(message: "`\(assignType.name)` does not extend declared type `\(givenType.name)`.", node: node)
        }
    }

    /// Transform datastructure to tuple. Such as (a,b) -> (String, Int), obj -> (prop1, prop2, ...)
    private func toTupleType(type: MooseType, size: Int, debugNode: Node) throws -> [MooseType] {
        switch type {
        case let tuple as TupleType:

            guard tuple.entries.count >= size else {
                throw error(message: "Tuple on right side has \(tuple.entries.count) values, while at least \(size) are needed by left side of assignment.", node: debugNode)
            }

            return tuple.entries

        // extract tuple assignments from class object
        case let clas as ClassType:
            let className = clas.name
            guard let classScope = scope.getScope(clas: className) else {
                throw error(message: "Class `\(className)` does not exist.", node: debugNode)
            }

            let propTypes = classScope.classProperties.map { $0.type }

            guard propTypes.count >= size else {
                throw error(message: "Class `\(className)` has \(propTypes.count) properties, while at least \(size) are required to unwrap to tuple. ", node: debugNode)
            }

            return propTypes

        default:
            throw error(message: "Could not unwrap \(type.description) to tuple.", node: debugNode)
        }
    }
}
