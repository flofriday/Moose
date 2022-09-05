//
//  File.swift
//
//
//  Created by Johannes Zottele on 03.09.22.
//

import Foundation

/// This resolves all dependencies between classes
///
/// After this pass, each class has a pointer to its superclass (if there is one)
class ClassDependencyResolverPass: BaseVisitor {
    var environment: Environment
    let program: Program

    init(program: Program, environment: Environment) {
        self.environment = environment
        self.program = program
        super.init("Should not be explored by class dependency resolution pass.")
    }

    func populate() throws -> Environment {
        try visit(program)
        return environment
    }

    override func visit(_ node: Program) throws {
        for stmt in node.statements {
            switch stmt {
            case is ClassStatement:
                try stmt.accept(self)
            default:
                break
            }
        }
    }

    /// Resolves all class dependencies, so we know that while executing the next pass, all dependencies are in place
    override func visit(_ node: ClassStatement) throws {
        if let superClass = node.extends?.value {
            try environment
                .get(clas: node.name.value)
                .superClass = environment.get(clas: superClass)
        }
    }
}
