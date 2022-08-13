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
        default:
            throw error(message: "Assignment to `\(assignable.description)` with is not valid.", node: node)
        }
    }

    /// Assignment to tuple
    ///
    /// Checks if it is possible to assign value of type `valueType` to tuple `tuple` with the declaredType `declaredType`
    private func assign(valueType: MooseType, to tuple: Tuple, with declaredType: MooseType?, on node: AssignStatement) throws {
        let tupleElements = try toTupleType(type: valueType, size: tuple.expressions.count, debugNode: node)

        var declaredTypes: [MooseType]?
        if let declaredType = declaredType {
            guard case let .Tuple(types) = declaredType else {
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
            guard valueType == declaredType else {
                throw error(message: "Declared type for variable `\(variable.value)` is `\(declaredType.description)` but you want to assign value of type `\(valueType)`", node: node)
            }
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
            guard valueType == varType else {
                throw error(message: "Variable `\(variable.value)` has type `\(varType.description)` but you try to assign type `\(valueType.description)`.", node: node)
            }

            guard try scope.isMut(variable: variable.value) else {
                throw error(message: "Variable `\(variable.value)` is unmutable.\nTip: Make `\(variable.value)` mutable by adding the keyworkd `mut` at its declaration.", node: node)
            }

            guard !node.mutable else {
                throw error(message: "Since variable `\(variable.value)` does already exist in scope, you cannot use the `mut` keyword.", node: node)
            }
        } else {
            try scope.add(variable: variable.value, type: valueType, mutable: node.mutable)
        }
    }

    /// Transform datastructure to tuple. Such as (a,b) -> (String, Int), obj -> (prop1, prop2, ...)
    private func toTupleType(type: MooseType, size: Int, debugNode: Node) throws -> [MooseType] {
        switch type {
        case let .Tuple(types):
            guard types.count >= size else {
                throw error(message: "Tuple on right side has \(types.count) values, while at least \(size) are needed by left side of assignment.", node: debugNode)
            }

            return types

        // extract tuple assignments from class object
        case let .Class(className):
            guard let classScope = scope.getScope(clas: className) else {
                throw error(message: "Class `\(className)` does not exist.", node: debugNode)
            }

            let propTypes = classScope.astNode.properties.map { $0.declaredType }

            guard propTypes.count >= size else {
                throw error(message: "Class `\(className)` has \(propTypes.count) properties, while at least \(size) are required to unwrap to tuple. ", node: debugNode)
            }

            return propTypes

        default:
            throw error(message: "Could not unwrap \(type.description) to tuple.", node: debugNode)
        }
    }
}
