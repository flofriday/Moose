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
        for op in BuiltIns.builtInOperators {
            environment.set(op: op.name, value: op)
        }

        for fn in BuiltIns.builtInFunctions {
            environment.set(function: fn.name, value: fn)
        }
    }

    func run(program: Program) throws {
        let explorer = GlobalEnvironmentExplorer(program: program, environment: environment)
        environment = try explorer.populate()
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

    func visit(_ node: ReturnStatement) throws -> MooseObject {
        var value: MooseObject = VoidObj()
        if let returnValue = node.returnValue {
            value = try returnValue.accept(self)
        }
        throw ReturnSignal(value: value)
    }

    func visit(_ node: ExpressionStatement) throws -> MooseObject {
        _ = try node.expression.accept(self)
        return VoidObj()
    }

    func visit(_ node: BlockStatement) throws -> MooseObject {
        environment = Environment(enclosing: environment)
        do {
            for statement in node.statements {
                _ = try statement.accept(self)
            }
        } catch {
            // Always leave the environment in peace
            environment = environment.enclosing!
            throw error
        }

        environment = environment.enclosing!
        return VoidObj()
    }

    func visit(_ node: FunctionStatement) throws -> MooseObject {
        // The global scope was already added by GlobalEnvironmentExplorer
        guard !environment.isGlobal() else {
            return VoidObj()
        }

        let paramNames = node.params.map { $0.name.value }
        let type = MooseType.Function(node.params.map { $0.declaredType }, node.returnType)
        let obj = FunctionObj(name: node.name.value, type: type, paramNames: paramNames, value: node.body)
        environment.set(function: obj.name, value: obj)
        return VoidObj()
    }

    func visit(_: ClassStatement) throws -> MooseObject {
        // The global scope was already added by GlobalEnvironmentExplorer
        guard !environment.isGlobal() else {
            return VoidObj()
        }

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

    func visit(_ node: FloatLiteral) throws -> MooseObject {
        return FloatObj(value: node.value)
    }

    func visit(_ node: Boolean) throws -> MooseObject {
        return BoolObj(value: node.value)
    }

    func visit(_ node: StringLiteral) throws -> MooseObject {
        return StringObj(value: node.value)
    }

    func callFunctionOrOperator(callee: MooseObject, args: [MooseObject]) throws -> MooseObject {
        if let callee = callee as? BuiltInFunctionObj {
            return try callee.function(args)
        } else if let callee = callee as? FunctionObj {
            environment = Environment(enclosing: environment)

            let argPairs = Array(zip(callee.paramNames, args))
            for (name, value) in argPairs {
                _ = environment.update(variable: name, value: value)
            }

            var result: MooseObject = VoidObj()
            do {
                _ = try callee.value.accept(self)
            } catch let error as ReturnSignal {
                result = error.value
            }

            environment = environment.enclosing!
            return result
        } else if let callee = callee as? BuiltInOperatorObj {
            return try callee.function(args)
        } else if let callee = callee as? OperatorObj {
            environment = Environment(enclosing: environment)

            let argPairs = Array(zip(callee.paramNames, args))
            for (name, value) in argPairs {
                _ = environment.update(variable: name, value: value)
            }

            var result: MooseObject = VoidObj()
            do {
                _ = try callee.value.accept(self)
            } catch let error as ReturnSignal {
                result = error.value
            }

            environment = environment.enclosing!
            return result
        } else {
            throw RuntimeError(message: "I cannot call \(callee)!")
        }
    }

    func visit(_ node: PrefixExpression) throws -> MooseObject {
        let args = try [node.right.accept(self)]
        let argTypes = [node.right.mooseType!]

        let handler = try environment.get(op: node.op, pos: .Prefix, params: argTypes)
        return try callFunctionOrOperator(callee: handler, args: args)
    }

    func visit(_ node: InfixExpression) throws -> MooseObject {
        let args = try [node.left, node.right].map { try $0.accept(self) }
        let argTypes = [node.left.mooseType!, node.right.mooseType!]

        let handler = try environment.get(op: node.op, pos: .Infix, params: argTypes)
        return try callFunctionOrOperator(callee: handler, args: args)
    }

    func visit(_ node: PostfixExpression) throws -> MooseObject {
        let args = try [node.left.accept(self)]
        let argTypes = [node.left.mooseType!]

        let handler = try environment.get(op: node.op, pos: .Postfix, params: argTypes)
        return try callFunctionOrOperator(callee: handler, args: args)
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
        return try callFunctionOrOperator(callee: callee, args: args)
    }

    func visit(_: OperationStatement) throws -> MooseObject {
        // The global scope was already added by GlobalEnvironmentExplorer
        guard !environment.isGlobal() else {
            return VoidObj()
        }

        return VoidObj()
    }
}
