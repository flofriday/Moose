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
        // set scope to paramScope to ensure that params are called via right outer scope
        let normalScope = scope
        scope = paramScope ?? scope

        // Toggles the argumentCheck. See github issue #31 for more info.
        let prevArgCheck = TypeScope.argumentCheck
        TypeScope.argumentCheck = true
        // Calculate the arguments
        for arg in node.arguments {
            try arg.accept(self)
        }
        TypeScope.argumentCheck = prevArgCheck
        scope = normalScope

        let paramTypes = node.arguments.map { param in
            param.mooseType!
        }

        // Check that the function exists and receive the return type
        // TODO: Should this also work for variables? Like can I store a function in a variable?
        // IF SO we have to add an other catch block
        do {
            let retType = try scope.returnType(function: node.function.value, params: paramTypes)
            node.mooseType = retType
        } catch is ScopeError {
            // If no function where found, we check if it is a class constructor call
            do {
                try checkConstructorCall(node)
            } catch _ as ScopeError {
                var message = "I cannot find any function `\(node.function)(\(paramTypes.map { $0.description }.joined(separator: ", ")))`."

                let similars = scope.getSimilar(function: node.function.value, params: paramTypes)
                if !similars.isEmpty {
                    message += "\n\n\nThese functions seem close though:\n\n"
                    message += similars.map { name, type in
                        "\t\(name)(\(type.params.map { $0.description }.joined(separator: ", "))) > \(type.returnType)".yellow
                    }
                    .joined(separator: "\n")
                }
                throw self.error(header: "Unknown Function", message: message, node: node)
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
            throw error(header: "Unknown Class", message: err.message, node: node)
        }

        guard MooseType.toType(node.function.value) is ClassType else {
            throw error(header: "Class Error", message: "`\(node.function.value)` is a built in type and therefore not constructable!", node: node)
        }

        guard classScope.propertyCount == node.arguments.count, node.arguments.count == classScope.classProperties.count else {
            throw error(header: "Argument Mismatch", message: "Constructor needs \(classScope.classProperties.count) arguments (\(classScope.classProperties.map { $0.type.description }.joined(separator: ", "))), but got \(node.arguments.count) instead.", node: node)
        }

        for (arg, prop) in zip(node.arguments, classScope.classProperties) {
            do {
                try checkAssignment(given: prop.type, with: arg.mooseType!, on: arg)
            } catch let err as CompileErrorMessage {
                throw error(header: "Type Mismatch", message: "Couldn't assign \(arg) to property \(prop.name): \(err.message)", node: arg)
            }
        }

        node.mooseType = ClassType(classScope.className)
        node.isConstructorCall = true
    }
}
