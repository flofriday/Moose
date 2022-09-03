//
// Created by flofriday on 21.06.22.
//

import Foundation

// The typechecker not only validates types it also checks that all variables and functions
// are visible.
class Typechecker: Visitor {
    typealias ReturnDec = (MooseType, Bool)?

    var isFunction = false
    var functionReturnType: MooseType?
    var errors: [CompileErrorMessage] = []
    var scope: TypeScope

    init() throws {
        scope = TypeScope()
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
            }
        }

        // guard no return statements outside function
        guard isFunction || returnDec == nil else {
            throw error(message: "Returns are only allowed inside functions and operators.", token: findReturnStatement(body: node)?.token ?? node.token)
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
            throw error(message: "Different return types occured. This branch returns type \(incType) while previous branch returned \(currType)", node: incoming)
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
            // TODO: the Error highlights the wrong character here
            throw error(message: "The condition `\(node.condition.description)` evaluates to a \(String(describing: node.condition.mooseType)) but if-conditions need to evaluate to Bool.", node: node.condition)
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
            throw error(message: "Consequence of if statement returns type \(conTyp) while alternative branch returns \(altTyp)", node: node.alternative!)
        }

        // set return declaration for if statement. Status is true if all branches in consequence AND in alternative return, else false.
        node.returnDeclarations = (conTyp, conStatus && altStatus)
    }

    func visit(_ node: Tuple) throws {
        var types: [ParamType] = []

        for expr in node.expressions {
            try expr.accept(self)
            guard let type = expr.mooseType! as? ParamType else {
                throw error(message: "Expression is of type \(expr.mooseType!) which is not suitable as tuple entry.", node: expr)
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
            throw error(message: "`me` keyword is only available in class functions.", node: node)
        }

        node.mooseType = ClassType(scope.className)
    }

    func visit(_ node: ReturnStatement) throws {
        try node.returnValue?.accept(self)
        var retType: MooseType = VoidType()
        if let expr = node.returnValue {
            guard let t = expr.mooseType else {
                throw error(message: "Couldn't determine type of return statement.", node: expr)
            }
            retType = t
        }
        node.returnDeclarations = (retType, true)
    }

    func visit(_ node: ExpressionStatement) throws {
        try node.expression.accept(self)
    }

    func visit(_ node: Identifier) throws {
        do {
            node.mooseType = try scope.typeOf(variable: node.value)
        } catch let err as ScopeError {
            throw error(message: "Could not find `\(node.value)`: \(err.message)", node: node)
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

    func visit(_ node: FunctionStatement) throws {
        let wasFunction = isFunction
        isFunction = true
        pushNewScope()

        for param in node.params {
            if let className = (param.declaredType as? ClassType)?.name {
                guard scope.has(clas: className) else {
                    throw error(message: "Type `\(className)` of parameter `\(param.name.value)` could not be found.", node: param)
                }
            }

            try scope.add(variable: param.name.value, type: param.declaredType, mutable: param.mutable)
        }

        try node.body.accept(self)
        var realReturnValue: MooseType = VoidType()
        if let (typ, eachBranch) = node.body.returnDeclarations {
            // if functions defined returnType is not Void and not all branches return, function body need explicit return at end
            guard node.returnType is VoidType || eachBranch else {
                throw error(message: "Return missing in function body.\nTipp: Add explicit return with value of type '\(node.returnType)' to end of function body", node: node.body.statements.last ?? node.body)
            }
            realReturnValue = typ
        }

        guard realReturnValue == node.returnType else {
            // TODO: We highlight the wrong thing here, but there is no reference to the correct return in the AST here.
            throw error(message: "Function returns '\(realReturnValue)', but signature requires it as '\(node.returnType)'", node: node)
        }

        try popScope()
        isFunction = wasFunction
    }

    func visit(_ node: VariableDefinition) throws {
        node.mooseType = node.declaredType
    }

    internal func error(message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
            location: locationFromToken(token),
            message: message
        )
    }

    internal func error(message: String, node: Node) -> CompileErrorMessage {
        return CompileErrorMessage(
            location: node.location,
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
            throw CompileErrorMessage(location: Location(col: 1, endCol: 1, line: 1, endLine: 1), message: "INTERNAL ERROR: Could not pop current scope \n\n\(scope)\n\n since it's enclosing scope is nil!")
        }
        scope = enclosing
    }
}

internal func error(message: String, node: Node) -> CompileErrorMessage {
    return CompileErrorMessage(
        location: node.location,
        message: message
    )
}
