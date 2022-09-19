//
// Created by flofriday on 21.06.22.
//

import Foundation

// The typechecker not only validates types it also checks that all variables and functions
// are visible.
class Typechecker: Visitor {
    typealias ReturnDec = (MooseType, Bool)?

    var isFunction = false
    var isLoop = false
    var functionReturnType: MooseType?
    var errors: [CompileErrorMessage] = []
    var scope: TypeScope

    /// We set the param scope since params have to be in current scope not in class scope.
    /// E.g.: `func a() { b = 2; obj.call(b) }` would not find b
    var paramScope: TypeScope?

    init() throws {
        scope = TypeScope()
        TypeScope.global = scope

        try addBuiltIns()
    }

    private func addBuiltIns() throws {
        for op in BuiltIns.builtInOperators {
            try scope.add(op: op.name, opPos: op.opPos, params: op.params, returnType: op.returnType)
        }
        for fn in BuiltIns.builtInFunctions {
            try scope.add(function: fn.name, params: fn.params, returnType: fn.returnType)
        }

        try scope.add(
            clas: "Int",
            scope: BuiltIns.builtIn_Integer_Env.asClassTypeScope("Int")
        )
        try scope.add(
            clas: "Float",
            scope: BuiltIns.builtIn_Float_Env.asClassTypeScope("Float")
        )
        try scope.add(
            clas: "Bool",
            scope: BuiltIns.builtIn_Bool_Env.asClassTypeScope("Bool")
        )
        try scope.add(
            clas: "String",
            scope: BuiltIns.builtIn_String_Env.asClassTypeScope("String")
        )
        try scope.add(
            clas: "Tuple",
            scope: BuiltIns.builtIn_Tuple_Env.asClassTypeScope("Tuple")
        )
        try scope.add(
            clas: "List",
            scope: BuiltIns.builtIn_List_Env.asClassTypeScope("List")
        )
        try scope.add(
            clas: "Dict",
            scope: BuiltIns.builtIn_Dict_Env.asClassTypeScope("Dict")
        )

        try scope.add(
            variable: "args",
            type: ListType(StringType()),
            mutable: false
        )
    }

    func check(program: Program) throws {
        // clear errors
        errors = []

        let explorer = GlobalScopeExplorer(program: program, scope: scope)
        scope = try explorer.populate()

        let secondPass = ClassDependecyPass(program: program, scope: scope)
        scope = try secondPass.populate()

        try program.accept(self)

        guard errors.count == 0 else {
            throw CompileError(messages: errors)
        }
    }

    func visit(_ node: Program) throws {
        for stmt in node.statements {
            let oldScope = scope
            do {
                try stmt.accept(self)
            } catch let error as CompileErrorMessage {
                errors.append(error)
                scope = oldScope
            } catch is StopTypeCheckingSignal {
                scope = oldScope
            }
        }
    }

    func visit(_ node: BlockStatement) throws {
        pushNewScope()

        var returnDec: ReturnDec = nil
        for stmt in node.statements {
            let oldScope = scope
            do {
                try stmt.accept(self)
                returnDec = try newReturnDec(current: returnDec, incoming: stmt)
            } catch let error as CompileErrorMessage {
                errors.append(error)
                scope = oldScope

                returnDec = try newReturnDec(current: returnDec, incoming: stmt)
            } catch is StopTypeCheckingSignal {
                scope = oldScope
                returnDec = try newReturnDec(current: returnDec, incoming: stmt)
            }
        }

        // guard no return statements outside function
        guard isFunction || returnDec == nil else {
            throw error(header: "Illegal Return", message: "Returns are only allowed inside functions and operators.", token: findReturnStatement(body: node)?.token ?? node.token)
        }
        node.returnDeclarations = returnDec

        try popScope()
    }

    private func newReturnDec(current: ReturnDec, incoming: Statement) throws -> ReturnDec {
        guard let (currType, _) = current else {
            return incoming.returnDeclarations
        }
        guard let (incType, incStatus) = incoming.returnDeclarations else {
            return current
        }
        guard currType == incType else {
            throw error(header: "Type Mismatch", message: "Different return types occured. This branch returns type \(incType) while previous branch returned \(currType)", node: incoming)
        }

        // if incoming has all brances returning, we return incoming status, else current
        if incStatus {
            return (incType, incStatus)
        } else {
            return current
        }
    }

    func visit(_ node: IfStatement) throws {
        try node.condition.accept(self)
        guard node.condition.mooseType == BoolType() else {
            throw error(header: "Type Mismatch", message: "The condition `\(node.condition.description)` evaluates to a \(String(describing: node.condition.mooseType)) but if-conditions need to evaluate to Bool.", node: node.condition)
        }

        try node.consequence.accept(self)
        let conRet = node.consequence.returnDeclarations

        // if alternative doesnt exists, set returnDeclaration to type of consequence but false as if condition doesn't apply it doesn't return
        guard let alternative = node.alternative else {
            guard let (conTyp, _) = conRet else {
                node.returnDeclarations = nil
                return
            }
            node.returnDeclarations = (conTyp, false)
            return
        }

        try alternative.accept(self)
        let altRet = alternative.returnDeclarations

        // guard alternative does return in some branch
        guard let (altTyp, altStatus) = altRet else {
            // if not, guard that consequence return in some branch
            guard let (conTyp, _) = conRet else {
                // if not, the whole if statement doesn't return
                return node.returnDeclarations = nil
            }
            // return typ of consequence, but branch status of false (since alternative doesnt return)
            return node.returnDeclarations = (conTyp, false)
        }

        // guard that consequence returns in some branch
        guard let (conTyp, conStatus) = conRet else {
            // if not set return type of alternative, with false as status
            node.returnDeclarations = (altTyp, false)
            return
        }

        // guard that alternative and consequence return same types
        guard conTyp == altTyp else {
            // if not throw an error
            throw error(header: "Type Mismatch", message: "The consequence of if statement returns type \(conTyp) while alternative branch returns \(altTyp)", node: node.alternative!)
        }

        // set return declaration for if statement. Status is true if all branches in consequence AND in alternative return, else false.
        node.returnDeclarations = (conTyp, conStatus && altStatus)
    }

    func visit(_ node: TernaryExpression) throws {
        try node.condition.accept(self)
        guard node.condition.mooseType == BoolType() else {
            // TODO: the Error highlights the wrong character here
            throw error(header: "Type Mismatch", message: "The condition `\(node.condition.description)` evaluates to a \(node.condition.mooseType!) but if-conditions need to evaluate to Bool.", node: node.condition)
        }

        try node.consequence.accept(self)
        try node.alternative.accept(self)

        // Verify that both branches return the same type

        let conType = node.consequence.mooseType
        let altType = node.alternative.mooseType
        guard conType == altType else {
            throw error(header: "Type Mismatch", message: "Both branches need to return the same but the consequence returns \(conType!), while the alternativereturns \(altType!).", node: node)
        }

        node.mooseType = conType
    }

    func visit(_ node: Tuple) throws {
        var types: [ParamType] = []

        for expr in node.expressions {
            try expr.accept(self)
            guard let type = expr.mooseType! as? ParamType else {
                throw error(header: "Type Mismatch", message: "Expression is of type \(expr.mooseType!) which is not suitable as tuple entry.", node: expr)
            }
            types.append(type)
        }

        node.mooseType = TupleType(types)
    }

    func visit(_ node: Nil) throws {
        node.mooseType = NilType()
    }

    /// Check if me keyword is used inside a class function an set node name to .Class(className)
    func visit(_ node: Me) throws {
        guard let scope = scope.nearestClassScope() else {
            throw error(header: "Illegal Me", message: "`me` keyword is only available in class functions.", node: node)
        }

        node.mooseType = ClassType(scope.className)
    }

    func visit(_ node: ReturnStatement) throws {
        guard isFunction else {
            throw error(header: "Illegal Return", message: "You can only return inside a functions.", node: node)
        }

        do {
            try node.returnValue?.accept(self)
        } catch let e as CompileErrorMessage {
            node.returnDeclarations = (InternalErrorType(), true)
            throw e
        } catch let e as StopTypeCheckingSignal {
            node.returnDeclarations = (InternalErrorType(), true)
            throw e
        }
        var retType: MooseType = VoidType()

        if let expr = node.returnValue {
            retType = expr.mooseType!
        }
        node.returnDeclarations = (retType, true)
    }

    func visit(_ node: ExpressionStatement) throws {
        try node.expression.accept(self)
    }

    func visit(_ node: Identifier) throws {
        do {
            node.mooseType = try scope.typeOf(variable: node.value)
        } catch is ScopeError {
            var message = "I couldn't find any `\(node.value)` variable."

            let similars = scope.getSimilar(variable: node.value).prefix(16)
            if !similars.isEmpty {
                message += "\n\n\nThese variables seem close though:\n\n"
                message += similars.map { name, type in
                    "\t\(name): \(type)".yellow
                }
                .joined(separator: "\n")
            }

            throw error(header: "Variable Error", message: message, node: node)
        }
    }

    func visit(_ node: IntegerLiteral) throws {
        node.mooseType = IntType()
    }

    func visit(_ node: FloatLiteral) throws {
        node.mooseType = FloatType()
    }

    func visit(_ node: Boolean) throws {
        node.mooseType = BoolType()
    }

    func visit(_ node: StringLiteral) throws {
        node.mooseType = StringType()
    }

    func visit(_ node: Is) throws {
        try node.expression.accept(self)
        if let clas = MooseType.toType(node.type.value) as? ClassType {
            guard scope.has(clas: clas.name) else {
                throw error(header: "Type Error", message: "I couldn't find a `\(clas.name)` type.", node: node.type)
            }
        }
        node.mooseType = BoolType()
    }

    func visit(_ node: FunctionStatement) throws {
        guard !scope.has(clas: node.name.value) else {
            throw error(header: "Name Collision", message: "A class with name `\(node.name.value)` already exists, so this function cannot have the same name.", node: node.name)
        }

        let wasFunction = isFunction
        isFunction = true
        pushNewScope()

        for param in node.params {
            if let className = (param.declaredType as? ClassType)?.name {
                guard scope.global().has(clas: className) else {
                    throw error(header: "Type Error", message: "I couldn't find the type `\(className)` of the parameter `\(param.name.value)`.", node: param)
                }
            }

            try scope.add(variable: param.name.value, type: param.declaredType, mutable: param.mutable)
        }

        try node.body.accept(self)
        var realReturnValue: MooseType = VoidType()
        if let (typ, eachBranch) = node.body.returnDeclarations {
            // if functions defined returnType is not Void and not all branches return, function body need explicit return at end
            guard node.returnType is VoidType || eachBranch else {
                throw error(header: "Type Mismatch", message: "A `return` is missing in function body.\nTipp: Add explicit return with value of type '\(node.returnType)' to end of function body", node: node.body.statements.last ?? node.body)
            }
            realReturnValue = typ
        }

        guard realReturnValue == node.returnType || realReturnValue == InternalErrorType() else {
            // TODO: We highlight the wrong thing here, but there is no reference to the correct return in the AST here.
            throw error(header: "Type Mismatch", message: "Function returns '\(realReturnValue)', but signature requires it to be '\(node.returnType)'", node: node)
        }

        try popScope()
        isFunction = wasFunction
    }

    func visit(_ node: VariableDefinition) throws {
        node.mooseType = node.declaredType

        if let className = (node.declaredType as? ClassType)?.name {
            guard scope.global().has(clas: className) else {
                throw error(header: "Type Error", message: "I couldn't find the type `\(className)` of the variable `\(node.name.value).", node: node)
            }
        }
    }

    internal func error(header: String, message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
            location: token.location,
            header: header,
            message: message
        )
    }

    internal func error(header: String, message: String, node: Node) -> CompileErrorMessage {
        return CompileErrorMessage(
            location: node.location,
            header: header,
            message: message
        )
    }
}

extension Typechecker {
    private func findReturnStatement(body: BlockStatement) -> ReturnStatement? {
        for stmt in body.statements {
            if let retStmt = stmt as? ReturnStatement {
                return retStmt
            }
        }
        return nil
    }

    /// Replaces current scope by new scope, whereby the old scope is the enclosing scope of the new scope
    func pushNewScope() {
        scope = TypeScope(enclosing: scope)
    }

    /// Replaces the current scope by the enclosing scope of the current scope. If it doesn't has an enclosing scope, the internal error occures.
    func popScope() throws {
        guard let enclosing = scope.enclosing else {
            throw CompileErrorMessage(
                location: Location(col: 1, endCol: 1, line: 1, endLine: 1),
                header: "Internal Scope Error",
                message: "INTERNAL ERROR: Could not pop current scope \n\n\(scope)\n\n since it's enclosing scope is nil!"
            )
        }
        scope = enclosing
    }

    func validType(ident: String) -> Bool {
        guard let clas = (MooseType.toType(ident) as? ClassType) else {
            return true
        }

        return scope.global().has(clas: clas.name)
    }
}

internal func error(header: String, message: String, node: Node) -> CompileErrorMessage {
    return CompileErrorMessage(
        location: node.location,
        header: header,
        message: message
    )
}
