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

    private func addBuiltIns() {
        // for op in BuiltIns.builtInOperators {
        //     TODO:
        // }

        for fn in BuiltIns.builtInFunctions {
            environment.set(function: fn.name, value: fn)
        }
    }

    func run(program: Program) throws {
        _ = try visit(program)
        // environment.printDebug()
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

    func visit(_ node: ExpressionStatement) throws -> MooseObject {
        _ = try node.expression.accept(self)
        return VoidObj()
    }

    func visit(_ node: BlockStatement) throws -> MooseObject {
        environment = Environment(enclosing: environment)
        for statement in node.statements {
            _ = try statement.accept(self)
        }
        environment = environment.enclosing!
        return VoidObj()
    }

    func visit(_: FunctionStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_: ClassStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_ node: IfStatement) throws -> MooseObject {
        let conditionResult = try node.condition.accept(self) as! BoolObj

        if conditionResult.value! {
            _ = try node.consequence.accept(self)
        } else if let alternative = node.alternative {
            _ = try alternative.accept(self)
        }

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

    func visit(_ node: CallExpression) throws -> MooseObject {
        let args = try node.arguments.map { try $0.accept(self) }
        let argTypes = args.map { $0.type }

        let callee = try environment.get(function: node.function.value, params: argTypes)
        if let callee = callee as? BuiltInFunctionObj {
            return callee.function(args)
        } else if let callee = callee as? BuiltInFunctionObj {
            // TODO: Implement other functions
            return VoidObj()
        } else {
            throw RuntimeError(message: "I cannot call \(callee)!")
        }
    }

    func visit(_: OperationStatement) throws -> MooseObject {
        return VoidObj()
    }
}
