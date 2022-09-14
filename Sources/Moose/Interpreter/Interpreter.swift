//
// Created by flofriday on 31.05.22.
//

import Foundation

class Interpreter: Visitor {
    static let shared = Interpreter()

    var errors: [RuntimeError] = []
    var environment: Environment

    /// We set the param environment since params have to be in current scope not in class scope.
    /// E.g.: `func a() { b = 2; obj.call(b) }` would not find b
    var paramEnvironment: (env: Environment, alreadySet: Bool)

    private init() {
        environment = BaseEnvironment(enclosing: nil)
        paramEnvironment = (environment, false)
        addBuiltIns()
    }

    /// This init is used to call functions from outside the interpreter
    ///
    /// E.g. the builtin functions
    init(environment: Environment) {
        self.environment = environment
        paramEnvironment = (environment, false)
    }

    /// Reset the internal state of the interpreter.
    func reset() {
        errors = []
        environment = BaseEnvironment(enclosing: nil)
        addBuiltIns()
    }

    func run(program: Program) throws {
        let explorer = GlobalEnvironmentExplorer(program: program, environment: environment)
        environment = try explorer.populate()

        let dependencyResolver = ClassDependencyResolverPass(program: program, environment: environment)
        environment = try dependencyResolver.populate()

        _ = try visit(program)
    }

    private func addBuiltIns() {
        for op in BuiltIns.builtInOperators {
            environment.set(op: op.name, value: op)
        }

        for fn in BuiltIns.builtInFunctions {
            environment.set(function: fn.name, value: fn)
        }
    }

    func pushEnvironment() {
        environment = BaseEnvironment(enclosing: environment)
    }

    func popEnvironment() {
        environment = environment.enclosing!
    }

    func visit(_ node: Program) throws -> MooseObject {
        for stmt in node.statements {
            _ = try stmt.accept(self)
        }
        return VoidObj()
    }

    /// This assignes the value to an indexExpression.
    ///
    /// The plan was to built an artifical derefe->ident->setItemCall ast, but since the assign function only provides
    /// the MooeObject value and not its ast node, we cannot create a CallExpression Node.
    /// This means we have to rewrite the whole derefer and callexpression interpreter stuff in one function for index exprssions
    private func assign(valueType: MooseType, indexExpr: IndexExpression, value: MooseObject) throws {
        let obj = try indexExpr.indexable.accept(self)
        guard !obj.isNil else { throw NilUsagePanic() }

        // Evaluate the arguments
        // Since we are doing this before the derefering
        // we have no logic with the paramEnvironment in the next step (derefering)
        let (index, indexType) = try evaluateArgs(exprs: [indexExpr.index])

        // Now we are derefering to the object environment
        let prevEnv = environment
        environment = obj.env

        // -- Now we have to call the setItem function
        let callee = try environment.get(function: Settings.SET_ITEM_FUNCTIONNAME, params: [indexType[0], valueType])
        let _ = try callFunctionOrOperator(callee: callee, args: [index[0], value])

        // Set environment back to normal
        environment = prevEnv
    }

    func assign(valueType: MooseType, dst: Assignable, value: MooseObject) throws {
        switch dst {
        case let id as Identifier:
            var newValue = value
            if let nilObj = value as? NilObj {
                newValue = try nilObj.toObject(type: valueType)
            }
            _ = environment.update(variable: id.value, value: newValue, allowDefine: true)

        case let tuple as Tuple:
            // TODO: many things can be unwrapped into tuples, like lists
            switch valueType {
            case let t as TupleType:
                let types = t.entries
                let valueTuple = value as! TupleObj
                for (n, expression) in tuple.expressions.enumerated() {
                    try assign(valueType: types[n], dst: expression as! Assignable, value: valueTuple.value![n])
                }
            case let clas as ClassType:
                let props = try clas.inferredClass().classProperties
                let valueClass = value as! ClassObject
                for (n, expression) in tuple.expressions.enumerated() {
                    let prop = try valueClass.classEnv!.get(variable: props[n].name)
                    try assign(valueType: props[n].type, dst: expression as! Assignable, value: prop)
                }
            default:
                throw RuntimeError(message: "NOT IMPLEMENTED: can only parse identifiers and tuples for assign")
            }

        case let indexExpr as IndexExpression:
            try assign(valueType: valueType, indexExpr: indexExpr, value: value)

        case let dereferExpr as Dereferer:
            let obj = try dereferExpr.obj.accept(self)

            let prevParamEnv = paramEnvironment
            paramEnvironment = !paramEnvironment.alreadySet ? (environment, true) : paramEnvironment
            let prevEnv = environment
            environment = obj.env

            let val = try dereferExpr.referer.accept(self)
            try assign(valueType: val.type, dst: dereferExpr.referer as! Assignable, value: value)

            environment = prevEnv
            paramEnvironment = prevParamEnv

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
        pushEnvironment()
        defer { popEnvironment() }

        for statement in node.statements {
            _ = try statement.accept(self)
        }

        return VoidObj()
    }

    func visit(_ node: FunctionStatement) throws -> MooseObject {
        // The global scope was already added by GlobalEnvironmentExplorer
        guard !environment.isGlobal() else {
            return VoidObj()
        }

        let paramNames = node.params.map { $0.name.value }
        let type = FunctionType(params: node.params.map { $0.declaredType }, returnType: node.returnType)
        let obj = FunctionObj(name: node.name.value, type: type, paramNames: paramNames, value: node.body, closure: environment)
        environment.set(function: obj.name, value: obj)
        return VoidObj()
    }

    func visit(_ node: OperationStatement) throws -> MooseObject {
        // The global scope was already added by GlobalEnvironmentExplorer
        guard !environment.isGlobal() else {
            return VoidObj()
        }

        let paramNames = node.params.map { $0.name.value }
        let params = node.params.map { $0.declaredType }
        let type = FunctionType(params: params, returnType: node.returnType)
        let obj = OperatorObj(name: node.name, opPos: node.position, type: type, paramNames: paramNames, value: node.body, closure: environment)
        environment.set(op: obj.name, value: obj)
        return VoidObj()
    }

    func visit(_: ClassStatement) throws -> MooseObject {
        // The global scope was already added by GlobalEnvironmentExplorer
        guard !environment.isGlobal() else {
            return VoidObj()
        }

        return VoidObj()
    }

    func visit(_: ExtendStatement) throws -> MooseObject {
        return VoidObj()
    }

    func visit(_ node: IfStatement) throws -> MooseObject {
        let conditionResult = try node.condition.accept(self) as! BoolObj

        guard let value = conditionResult.value else {
            throw NilUsagePanic(node: node.condition)
        }

        if value {
            _ = try node.consequence.accept(self)
        } else if let alternative = node.alternative {
            _ = try alternative.accept(self)
        }

        return VoidObj()
    }

    func visit(_ node: TernaryExpression) throws -> MooseObject {
        let conditionResult = try node.condition.accept(self) as! BoolObj

        guard let value = conditionResult.value else {
            throw NilUsagePanic(node: node.condition)
        }

        if value {
            return try node.consequence.accept(self)
        } else {
            return try node.alternative.accept(self)
        }
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

    func visit(_ node: Tuple) throws -> MooseObject {
        let args = try node.expressions.map { try $0.accept(self) }
        return TupleObj(type: node.mooseType!, value: args)
    }

    func visit(_ node: List) throws -> MooseObject {
        let args = try node.expressions.map { try $0.accept(self) }
        return ListObj(type: node.mooseType!, value: args)
    }

    func visit(_ node: Dict) throws -> MooseObject {
        let pairs = try node.pairs.map { (key: try $0.key.accept(self), value: try $0.value.accept(self)) }
        return DictObj(type: node.mooseType!, pairs: pairs)
    }

    func visit(_ node: Is) throws -> MooseObject {
        let obj = try node.expression.accept(self)
        if let obj = obj as? ClassObject {
            return BoolObj(value: obj.classEnv?.extends(clas: node.type.value).extends ?? false)
        }
        return BoolObj(value: obj.type.description == node.type.value)
    }

    func callFunctionOrOperator(callee: MooseObject, args: [MooseObject]) throws -> MooseObject {
        if let callee = callee as? BuiltInFunctionObj {
            // If the environment is already the class environment we do noting,
            // however, if it is not we set the current environment to the
            // global.
            let oldEnv = environment
            if !(environment is BuiltInClassEnvironment) {
                environment = environment.global()
            }

            defer {
                environment = oldEnv
            }
            // Execute the function
            return try callee.function(args, environment)
        } else if let callee = callee as? FunctionObj {
            // Activate the  environment in which the function was defined
            let oldEnv = environment
            environment = callee.closure

            pushEnvironment()

            // Reactivate the original environment at the end
            defer {
                popEnvironment()
                environment = oldEnv
            }

            // Set all arguments
            let argPairs = Array(zip(callee.paramNames, args))
            for (name, value) in argPairs {
                _ = environment.updateInCurrentEnv(variable: name, value: value, allowDefine: true)
            }

            // Execute the body
            do {
                _ = try callee.value.accept(self)
            } catch let error as ReturnSignal {
                return error.value
            }

            return VoidObj()

        } else {
            throw RuntimeError(message: "I cannot call \(callee)!")
        }
    }

    /// This function evaluates arguments for a function call.
    /// Since the environment could be an enclosed environment (because of derefering before calling e.g. `classObj.call(a)`)
    /// We use the paramEnvironment, since it is the last environment before the dereference
    func evaluateArgs(exprs: [Expression]) throws -> ([MooseObject], [MooseType]) {
        // use paramEnvironment
        let normalEnv = environment
        environment = paramEnvironment.alreadySet ? paramEnvironment.env : environment

        let args = try exprs.map { try $0.accept(self) }
        let argTypes = exprs.map { $0.mooseType! }

        environment = normalEnv
        paramEnvironment.alreadySet = false

        return (args, argTypes)
    }

    func visit(_ node: PrefixExpression) throws -> MooseObject {
        let (args, argTypes) = try evaluateArgs(exprs: [node.right])

        let handler = try environment.get(op: node.op, pos: .Prefix, params: argTypes)
        do {
            return try callFunctionOrOperator(callee: handler, args: args)
        } catch let panic as Panic {
            panic.stacktrace.push(node: node)
            throw panic
        }
    }

    func visit(_ node: InfixExpression) throws -> MooseObject {
        let (args, argTypes) = try evaluateArgs(exprs: [node.left, node.right])

        let handler = try environment.get(op: node.op, pos: .Infix, params: argTypes)
        do {
            return try callFunctionOrOperator(callee: handler, args: args)
        } catch let panic as Panic {
            panic.stacktrace.push(node: node)
            throw panic
        }
    }

    func visit(_ node: PostfixExpression) throws -> MooseObject {
        let (args, argTypes) = try evaluateArgs(exprs: [node.left])

        let handler = try environment.get(op: node.op, pos: .Postfix, params: argTypes)
        do {
            return try callFunctionOrOperator(callee: handler, args: args)
        } catch let panic as Panic {
            panic.stacktrace.push(node: node)
            throw panic
        }
    }

    func visit(_: VariableDefinition) throws -> MooseObject {
        // The interpreter doesn't ever need to read this so it is ok to just
        // crash here.
        fatalError("Unreachable VariableDefinition in Interpreter")
    }

    func visit(_: Nil) throws -> MooseObject {
        return NilObj()
    }

    func visit(_ node: CallExpression) throws -> MooseObject {
        let (args, argTypes) = try evaluateArgs(exprs: node.arguments)

        if node.isConstructorCall {
            return try callConstructor(className: node.function.value, args: args)
        }

        let callee = try environment.get(function: node.function.value, params: argTypes)

        do {
            return try callFunctionOrOperator(callee: callee, args: args)
        } catch let panic as Panic {
            panic.stacktrace.push(node: node)
            throw panic
        }
    }

    private func callConstructor(className: String, args: [MooseObject]) throws -> MooseObject {
        let classDefinition = try environment.get(clas: className)
        // flat class definition to eliminate class hirachie
        classDefinition.flat()
        // create new object from definition
        let classObject = ClassEnvironment(copy: classDefinition)

        guard classObject.propertyNames.count == args.count else {
            throw EnvironmentError(message: "Args and property names have not same number of elements")
        }

        for (name, arg) in zip(classObject.propertyNames, args) {
            _ = classObject.updateInCurrentEnv(variable: name, value: arg)
        }

        // Bind all methods to this excat object
        classObject.bindMethods()

        return ClassObject(env: classObject, name: classObject.className)
    }

    func visit(_ node: Dereferer) throws -> MooseObject {
        let obj = try node.obj.accept(self)

        guard !obj.isNil else {
            throw NilUsagePanic()
        }

        // set environment to paramEnvironment accept if the paramEnvironment was already set before used
        // for example we are at `objB` in `objA.objB.call(a)`
        // here we want to use the environemnt before derefering `objA` which is already set
        // by the first dereference
        let prevParamEnv = paramEnvironment
        paramEnvironment = !paramEnvironment.alreadySet ? (environment, true) : paramEnvironment

        let prevEnv = environment
        environment = obj.env

        let val = try node.referer.accept(self)

        environment = prevEnv
        paramEnvironment = prevParamEnv

        return val
    }

    func visit(_ node: IndexExpression) throws -> MooseObject {
        let funcIdent = Identifier(token: node.indexable.token, value: Settings.GET_ITEM_FUNCTIONNAME)
        let location = Location(node.indexable.token.location, node.index.token.location)
        let indexCall = CallExpression(token: node.index.token, location: location, function: funcIdent, arguments: [node.index])
        let dereferer = Dereferer(token: node.token, obj: node.indexable, referer: indexCall)
        return try dereferer.accept(self)
    }

    func visit(_: Me) throws -> MooseObject {
        let env = try environment.nearestClass()
        return ClassObject(env: env, name: env.className)
    }
}
