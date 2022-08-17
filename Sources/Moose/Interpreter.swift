//
// Created by flofriday on 31.05.22.
//

import Foundation

class Interpreter: Visitor {
    static let shared = Interpreter()

    var errors: [RuntimeError] = []
    var environment: Environment

    private init() {
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
    }

    func visit(_ node: Program) throws -> MooseObject {
        for stmt in node.statements {
            _ = try stmt.accept(self)
        }
        return VoidObj()
    }

    private func assign(valueType: MooseType, dst: Assignable, value: MooseObject) throws {
        switch dst {
        case let id as Identifier:
            var newValue = value
            if let nilObj = value as? NilObj {
                newValue = try nilObj.toObject(type: valueType)
            }
            _ = environment.update(variable: id.value, value: newValue)

        case let tuple as Tuple:
            // TODO: many things can be unwrapped into tuples, like classes
            // and lists.
            switch valueType {
            case let .Tuple(types):
                let valueTuple = value as! TupleObj
                for (n, assignable) in tuple.assignables.enumerated() {
                    try assign(valueType: types[n], dst: assignable, value: valueTuple.value![n])
                }
            default:
                throw RuntimeError(message: "NOT IMPLEMENTED: can only parse identifiers and tuples for assign")
            }
        default:
            throw RuntimeError(message: "NOT IMPLEMENTED: can only parse identifiers and tuples for assign")
        }
    }

    func visit(_ node: AssignStatement) throws -> MooseObject {
        let value = try node.value.accept(self)
        try assign(valueType: node.declaredType ?? node.value.mooseType!, dst: node.assignable, value: value)

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

    func visit(_ node: Tuple) throws -> MooseObject {
        let args = try node.expressions.map { try $0.accept(self) }
        return TupleObj(type: node.mooseType!, value: args)
    }

    func visit(_: Nil) throws -> MooseObject {
        return NilObj()
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

    func visit(_: Dereferer) throws -> MooseObject {
        fatalError("Not implemented Dereferer")
    }

    func visit(_: List) throws -> MooseObject {
        fatalError("Not implemented List")
    }

    func visit(_: IndexExpression) throws -> MooseObject {
        fatalError("Not implemented IndexExpression")
    }

    func visit(_: Me) throws -> MooseObject {
        fatalError("Not implemented Me")
    }

    func visit(_: ForEachStatement) throws -> MooseObject {
//        let arr = loop.list.accept(self)

//        guard case let  = arr
//        environment.update(variable: loop.variable.value, value: )
        fatalError("Not implemented ForEach")
    }

    func visit(_ node: ForCStyleStatement) throws -> MooseObject {
        // First push a new Environment since the variable definitions only
        // apply here
        environment = Environment(enclosing: environment)

        if let preStmt = node.preStmt {
            _ = try preStmt.accept(self)
        }

        while true {
            // Check condition
            let condition: Bool? = (try node.condition.accept(self) as! BoolObj).value
            guard condition != nil else {
                throw NilUsagePanic()
            }
            if condition == false {
                break
            }

            // Execute body
            _ = try node.body.accept(self)

            // Post statement
            if let postEachStmt = node.postEachStmt {
                _ = try postEachStmt.accept(self)
            }
        }

        // Pop the loop environment
        environment = environment.enclosing!
        return VoidObj()
    }
}
