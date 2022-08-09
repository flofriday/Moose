//
//  GlobalEnvironmentExplorer.swift
//
//
//  Created by Florian Freitag on 09.08.2022.
//

import Foundation

class GlobalEnvironmentExplorer: BaseVisitor {
    let environment: Environment
    let program: Program

    init(program: Program, environment: Environment) {
        self.environment = environment
        self.program = program
        super.init("Should not be explored by GlobalEnvironmentExplorer.")
    }

    func populate() throws -> Environment {
        try visit(program)
        return environment
    }

    override func visit(_ node: Program) throws {
        for stmt in node.statements {
            switch stmt {
            case is OperationStatement:
                fallthrough
            case is FunctionStatement:
                try stmt.accept(self)
            default:
                break
            }
        }
    }

    override func visit(_ node: FunctionStatement) throws {
        let paramNames = node.params.map { $0.name.value }
        let type = MooseType.Function(node.params.map { $0.declaredType }, node.returnType)
        let obj = FunctionObj(name: node.name.value, type: type, paramNames: paramNames, value: node.body)
        environment.set(function: obj.name, value: obj)
    }

    override func visit(_: OperationStatement) throws {}

    override func visit(_: ClassStatement) throws {}
}
