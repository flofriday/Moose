//
// Created by flofriday on 31.05.22.
//

import Foundation

class Interpreter: Visitor {
    var errors: [RuntimeError] = []
    var environment: Environment

    init() {
        environment = Environment(enclosing: nil)
        addBuiltIns()
    }

    private func addBuiltIns() {}

    func run(program: Program) throws {
        _ = try visit(program)
        environment.printDebug()
    }

    func visit(_ node: Program) throws -> MooseObject {
        for stmt in node.statements {
            _ = try stmt.accept(self)
        }
        return VoidObj()
    }

    func visit(_ node: AssignStatement) throws -> MooseObject {
        let value = try node.value.accept(self)

        // TODO: in the future we want more than just variable assignment to work here
        var name: String
        switch node.assignable {
        case let id as Identifier:
            name = id.value
        default:
            throw RuntimeError(message: "NOT IMPLEMENTED: can only parse identifiers for assign")
        }

        _ = environment.update(variable: name, value: value)

        return VoidObj()
    }

    func visit(_: ReturnStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: ExpressionStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: BlockStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: FunctionStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: ClassStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: IfStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_ node: Identifier) throws -> MooseObject {
        return try environment.get(variable: node.value)
    }

    func visit(_ node: IntegerLiteral) throws -> MooseObject {
        return IntegerObj(value: node.value)
    }

    func visit(_ node: Boolean) throws -> MooseObject {
        return BoolObj(value: node.value)
    }

    func visit(_ node: StringLiteral) throws -> MooseObject {
        return StringObj(value: node.value)
    }

    func visit(_: PrefixExpression) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: InfixExpression) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: PostfixExpression) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: VariableDefinition) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: Tuple) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: Nil) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: CallExpression) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: OperationStatement) throws -> MooseObject {
        return VoidObj()
    }
}
