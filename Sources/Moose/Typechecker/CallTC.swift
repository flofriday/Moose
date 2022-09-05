//
//  File.swift
//
//
//  Created by Johannes Zottele on 11.08.22.
//

import Foundation

extension Typechecker {
    /// CallExpressions are responisble for classic function calls and constructor calls
    func visit(_ node: CallExpression) throws {
        // Calculate the arguments
        for arg in node.arguments {
            try arg.accept(self)
        }
        let paramTypes = node.arguments.map { param in
            param.mooseType!
        }

        // Check that the function exists and receive the return type
        // TODO: Should this also work for variables? Like can I store a function in a variable?
        // IF SO we have to add an other catch block
        do {
            let retType = try scope.returnType(function: node.function.value, params: paramTypes)
            node.mooseType = retType
        } catch let err as ScopeError {
            // If no function where found, we check if it is a class constructor call
            do {
                try checkConstructorCall(node)
            } catch _ as ScopeError {
                // TODO: We could do even more here, and iterate over the scopes
                // finding all functions with the correct name but differend
                // type and listing them.
                // Or maybe even finding similarly named functions with the
                // correct types.
                throw self.error(message: "Couldn't find callable `\(node.function)(\(paramTypes.map { $0.description }.joined(separator: ", ")))` in current scope: \(err.message)", node: node)
            }
        }
    }

    private func checkConstructorCall(_ node: CallExpression) throws {
        guard let classScope = scope.getScope(clas: node.function.value) else {
            throw ScopeError(message: "Couldn't find class \(node.function.value)")
        }

        do {
            // is required since constructor need to know all properties
            try classScope.flat()
        } catch let err as ScopeError {
            throw error(message: err.message, node: node)
        }

        guard MooseType.toType(node.function.value) is ClassType else {
            throw error(message: "`\(node.function.value)` is a built in type and therefore not constructable!", node: node)
        }

        guard classScope.propertyCount == node.arguments.count, node.arguments.count == classScope.classProperties.count else {
            throw error(message: "Constructor needs \(classScope.classProperties.count) arguments (\(classScope.classProperties.map { $0.type.description }.joined(separator: ", "))), but got \(node.arguments.count) instead.", node: node)
        }

        for (arg, prop) in zip(node.arguments, classScope.classProperties) {
            do {
                try checkAssignment(given: prop.type, with: arg.mooseType!, on: arg)
            } catch let err as CompileErrorMessage {
                throw error(message: "Couldn't assign \(arg) to property \(prop.name): \(err.message)", node: arg)
            }
        }

        node.mooseType = ClassType(classScope.className)
        node.isConstructorCall = true
    }
}