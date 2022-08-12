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
            throw error(message: "Left side of assignment is not valid.", node: node.assignable)
        }

        switch node.assignable {
        case _ as Identifier:
            try processIdentAssignment(node)
        case _ as Tuple:
            try processTupleAssignment(node)
        default:
            throw error(message: "\(node.assignable.description) on left side of assignment is currently not supported.", node: node.assignable)
        }
    }

    private func processIdentAssignment(_ node: AssignStatement) throws {
        // Calculate the type of the experssion (right side)
        try node.value.accept(self)
        let valueType = node.value.mooseType!

        // Verify that the explicit expressed type (if availble) matches the type of the expression
        if let expressedType = node.declaredType {
            guard node.declaredType == valueType else {
                throw error(message: "The expression on the right produces a value of the type \(valueType) but you explicitly require the type to be \(expressedType).", node: node.value)
            }
        }

        let name: String = (node.assignable as! Identifier).value

        // Checks to do if the variable was already initialized
        if scope.has(variable: name, includeEnclosing: true) {
            if let t = node.declaredType {
                // TODO: We highlight the variable here instead of the type declaration. At the time of writing we
                // cannot highlight the declaration because it is not part of the AST and thereby not reachable by the
                // checker.
                throw error(message: "Type declarations are only possible for new variable declarations. Variable '\(name)' already exists.\nTipp: Remove `: \(t.description)`", node: node.assignable)
            }

            // Check that this new assignment doesn't have the mut keyword as the variable already exists
            guard !node.mutable else {
                throw error(message: "Variable '\(name)' was already declared, so the `mut` keyword doesn't make any sense here.\nTipp: Remove the `mut` keyword.", node: node.assignable)
            }

            // Check that the variable wasn mutable
            guard try scope.isMut(variable: name) else {
                throw error(message: "Variable '\(name)' is inmutable and cannot be reassigned.\nTipp: Declare '\(name)' as mutable with the the `mut` keyword.", node: node.assignable)
            }

            // Check that the new assignment still has the same type from the initialization
            let currentType = try scope.typeOf(variable: name)
            guard currentType == valueType else {
                throw error(message: "Variable '\(name)' has the type \(currentType), but the expression on the right produces a value of the type \(valueType).", node: node.value)
            }
        } else {
            try scope.add(variable: name, type: valueType, mutable: node.mutable)
        }
    }

    /// Handle Tuple assignment
    ///
    /// Examples:
    /// `(a,b) = (1, 3)`
    /// `(a,b): (Int, String) = (1, "Hello")`
    /// `(a, b, c) = Obj()`
    ///
    private func processTupleAssignment(_ node: AssignStatement) throws {
        let assignable = node.assignable as! Tuple
        let size = assignable.expressions.count
        let idents = assignable.idents

        // find duplicate idents (not allowed in one tuple)
        let dups = Dictionary(grouping: idents.map { $0.value }, by: { $0 }).filter { $1.count > 1 }.keys
        guard dups.count == 0 else {
            throw error(message: "\(dups.first?.description ?? "") is used multiple times in tuple on left side of assignment. Multiple variable usages in assignable tuple are not allowed.", node: node)
        }

        guard size == idents.count else {
            throw error(message: "INTERNAL ERROR: size of idents is not same as of expressions of assignable", node: assignable)
        }

        try node.value.accept(self)
        let tupleToAssign = try toTupleType(expression: node.value, size: size)

        var declaredTypes: [MooseType]?
        if let declaredT = node.declaredType {
            guard case let .Tuple(types) = declaredT else {
                throw error(message: "Declared type is not tuple.", node: node)
            }
            declaredTypes = types
        }

        for (i, vari) in idents.enumerated() {
            // if assignment is declared with type, check if expression has same type as declared
            if let declaredTypes = declaredTypes {
                guard tupleToAssign[i] == declaredTypes[i] else {
                    throw error(message: "Declared type for variable `\(vari.value)` is `\(declaredTypes[i].description)` but you want to assign value of type `\(tupleToAssign[i])`", node: node)
                }
            }

            // check if variable exists
            if scope.has(variable: vari.value) {
                let varType = try scope.typeOf(variable: vari.value)

                // check that tuple to assign has same type as stored variable
                guard tupleToAssign[i] == varType else {
                    throw error(message: "Variable `\(vari.value)` has type `\(varType.description)` but you try to assign type `\(tupleToAssign[i].description)`.", node: node)
                }

                guard try scope.isMut(variable: vari.value) else {
                    throw error(message: "Variable `\(vari.value)` is unmutable.\nTip: Make `\(vari.value)` mutable by adding the keyworkd `mut` at its declaration.", node: node)
                }

                guard !node.mutable else {
                    throw error(message: "Since variable `\(vari.value)` does already exist in scope, you cannot use the `mut` keyword.", node: node)
                }
            } else {
                try scope.add(variable: vari.value, type: tupleToAssign[i], mutable: node.mutable)
            }
        }
    }

    /// Transform datastructure to tuple. Such as (a,b) -> (String, Int), tupVar -> (
    private func toTupleType(expression: Expression, size: Int) throws -> [MooseType] {
        switch expression.mooseType {
        case let .Tuple(types):
            guard types.count >= size else {
                throw error(message: "Tuple on right side has \(types.count) values, while at least \(size) are needed by left side of assignment.", node: expression)
            }

            return types
        default:
            throw error(message: "Could not unwrap \(expression.mooseType!) to tuple.", node: expression)
        }
    }
}
