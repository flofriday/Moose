//
// Created by flofriday on 21.06.22.
//

import Foundation

// The typechecker not only validates types it also checks that all variables and functions
// are visible.
class Typechecker: BaseVisitor {
    typealias ReturnDec = (MooseType, Bool)?

    var isGlobal = true
    var isFunction = false
    var functionReturnType: MooseType?
    var errors: [CompileErrorMessage] = []
    var scope: TypeScope

    init() throws {
        scope = TypeScope()
        super.init("Typechecker is not yet implemented for this scope.")
        try addBuiltIns()
    }

    private func addBuiltIns() throws {
        for op in BuiltIns.builtInOperators {
            try scope.add(op: op.name, opPos: op.opPos, params: op.params, returnType: op.returnType)
        }
        for fn in BuiltIns.builtInFunctions {
            try scope.add(function: fn.name, params: fn.params, returnType: fn.returnType)
        }
    }

    func check(program: Program) throws {
        // clear errors
        errors = []

        let scopeSpawner = GlobalScopeExplorer(program: program, scope: scope)
        scope = try scopeSpawner.spawn()

        try program.accept(self)

        guard errors.count == 0 else {
            throw CompileError(messages: errors)
        }
    }

    override func visit(_ node: Program) throws {
        for stmt in node.statements {
            do {
                try stmt.accept(self)
            } catch let error as CompileErrorMessage {
                errors.append(error)
            }
        }
    }

    override func visit(_ node: BlockStatement) throws {
        let wasGlobal = isGlobal
        isGlobal = false
        pushNewScope()

        var returnDec: ReturnDec = nil
        for stmt in node.statements {
            do {
                try stmt.accept(self)
                returnDec = try newReturnDec(current: returnDec, incoming: stmt)
            } catch let error as CompileErrorMessage {
                errors.append(error)
            }
        }

        // guard no return statements outside function
        guard isFunction || returnDec == nil else {
            throw error(message: "Returns are only allowed inside functions and operators.", token: findReturnStatement(body: node)?.token ?? node.token)
        }
        node.returnDeclarations = returnDec

        try popScope()
        isGlobal = wasGlobal
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

    override func visit(_ node: IfStatement) throws {
        try node.condition.accept(self)
        guard node.condition.mooseType == .Bool else {
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

    override func visit(_ node: Tuple) throws {
        var types: [MooseType] = []

        for expr in node.expressions {
            try expr.accept(self)
            types.append(expr.mooseType!)
        }

        node.mooseType = .Tuple(types)
    }

    override func visit(_ node: Nil) throws {
        node.mooseType = .Nil
    }

    override func visit(_ node: CallExpression) throws {
        // Calculate the arguments
        for arg in node.arguments {
            try arg.accept(self)
        }
        let paramTypes = node.arguments.map { param in
            param.mooseType!
        }

        // Check that the function exists and receive the return type
        // TODO: Should this also work for variables? Like can I store a function in a variable?
        let retType = try scope.returnType(function: node.function.description, params: paramTypes)
        node.mooseType = retType
    }

    override func visit(_ node: AssignStatement) throws {
        // Calculate the type of the experssion (right side)
        try node.value.accept(self)
        let valueType = node.value.mooseType!

        // Verify that the explicit expressed type (if availble) matches the type of the expression
        if let expressedType = node.declaredType {
            guard node.declaredType == valueType else {
                throw error(message: "The expression on the right produces a value of the type \(valueType) but you explicitly require the type to be \(expressedType).", node: node.value)
            }
        }

        // TODO: in the future we want more than just variable assignment to work here
        var name: String?
        switch node.assignable {
        case let id as Identifier:
            name = id.value
        default:
            throw error(message: "NOT IMPLEMENTED: can only parse identifiers for assign", node: node.assignable)
        }

        guard let name = name else {
            throw error(message: "INTERNAL ERROR: could not extract name from assignable", node: node.assignable)
        }

        // Checks to do if the variable was already initialized
        if scope.has(variable: name, includeEnclosing: true) {
            if let t = node.declaredType {
                // TODO: We highlight the variable here instead of the type declaration. At the time of writing we
                // cannot highlight the declaration because it is not part of the AST and thereby not reachable by the
                // checker.
                throw error(message: "Type declarations are only possible for new variable declarations. Variable '\(name)' already exists.\nTipp: Remove `: \(t.description)`", node: node.assignable)
            }

            // Check that this new assignment doesn't have the mut keyword as the variable already exists
            guard !node.mutable else {
                throw error(message: "Variable '\(name)' was already declared, so the `mut` keyword doesn't make any sense here.\nTipp: Remove the `mut` keyword.", node: node.assignable)
            }

            // Check that the variable wasn mutable
            guard try scope.isMut(variable: name) else {
                throw error(message: "Variable '\(name)' is inmutable and cannot be reassigned.\nTipp: Declare '\(name)' as mutable with the the `mut` keyword.", node: node.assignable)
            }

            // Check that the new assignment still has the same type from the initialization
            let currentType = try scope.typeOf(variable: name)
            guard currentType == valueType else {
                throw error(message: "Variable '\(name)' has the type \(currentType), but the expression on the right produces a value of the type \(valueType).", node: node.value)
            }
        } else {
            try scope.add(variable: name, type: valueType, mutable: node.mutable)
        }
    }

    override func visit(_ node: ReturnStatement) throws {
        try node.returnValue?.accept(self)
        var retType: MooseType = .Void
        if let expr = node.returnValue {
            guard let t = expr.mooseType else {
                throw error(message: "Couldn't determine type of return statement.", node: expr)
            }
            retType = t
        }
        node.returnDeclarations = (retType, true)
    }

    override func visit(_ node: ExpressionStatement) throws {
        try node.expression.accept(self)
    }

    override func visit(_ node: Identifier) throws {
        node.mooseType = try scope.typeOf(variable: node.value)
    }

    override func visit(_ node: IntegerLiteral) throws {
        node.mooseType = .Int
    }

    override func visit(_ node: Boolean) throws {
        node.mooseType = .Bool
    }

    override func visit(_ node: StringLiteral) throws {
        node.mooseType = .String
    }

    override func visit(_ node: FunctionStatement) throws {
        let wasGlobal = isGlobal
        let wasFunction = isFunction
        isGlobal = false
        isFunction = true
        pushNewScope()
        
        for param in node.params {
            try scope.add(variable: param.name.value, type: param.declaredType, mutable: param.mutable)
        }
        
        try node.body.accept(self)
        var realReturnValue: MooseType = .Void
        if let (typ, eachBranch) = node.body.returnDeclarations {
            // if functions defined returnType is not Void and not all branches return, function body need explicit return at end
            guard node.returnType == .Void || eachBranch else {
                throw error(message: "Return missing in function body.\nTipp: Add explicit return with value of type '\(node.returnType)' to end of function body", node: node.body.statements.last ?? node.body)
            }
            realReturnValue = typ
        }

        guard realReturnValue == node.returnType else {
            // TODO: We highlight the wrong thing here, but there is no reference to the correct return in the AST here.
            throw error(message: "Function returns '\(realReturnValue)', but signature requires it as '\(node.returnType)'", token: node.token)
        }

        
        try popScope()
        isFunction = wasFunction
        isGlobal = wasGlobal
    }

    override func visit(_ node: OperationStatement) throws {
        let wasGlobal = isGlobal
        let wasFunction = isFunction
        isGlobal = false
        isFunction = true
        
        guard wasGlobal else {
            throw error(message: "Operator definition is only allowed in global scope.", node: node)
        }
        
        pushNewScope()
        for param in node.params {
            try scope.add(variable: param.name.value, type: param.declaredType, mutable: false)
        }

        try node.body.accept(self)

        // get real return type
        var realReturnValue: MooseType = .Void
        if let (typ, eachBranch) = node.body.returnDeclarations {
            // if functions defined returnType is not Void and not all branches return, function body need explizit return at end
            guard node.returnType == .Void || eachBranch else {
                throw error(message: "Return missing in operator body.\nTipp: Add explicit return with value of type '\(node.returnType)' to end of operator body", node: node.body.statements.last ?? node.body)
            }
            realReturnValue = typ
        }

        // compare declared and real returnType
        guard realReturnValue == node.returnType else {
            // TODO: We highlight the wrong thing here
            throw error(message: "Return type of operator is \(realReturnValue), not \(node.returnType) as declared in signature", token: node.token)
        }

        // TODO: assure it is in scope

        try popScope()
        isFunction = wasFunction
        isGlobal = wasGlobal
    }

    override func visit(_ node: InfixExpression) throws {
        guard case let .Operator(pos: opPos, assign: assign) = node.token.type else {
            throw error(message: "INTERNAL ERROR: token type should be .Operator, but got \(node.token.type) instead.", node: node)
        }

        if assign {
            guard let ident = node.left as? Identifier, scope.has(variable: ident.value) else {
                throw error(message: "Assign operations can only be made on variables that already exist. `\(node.left)` must be declared seperatly.", node: node.left)
            }
        }

        try node.left.accept(self)
        try node.right.accept(self)

        // TODO: I think this is too defensive. We can asume that it worked otherwise it would have thrown an error.
        // Right?
        guard let left = node.left.mooseType else {
            throw error(message: "Couldn't determine type of left side exprssion '\(node.left.description.prefix(20))'...", token: node.left.token)
        }

        guard let right = node.right.mooseType else {
            throw error(message: "Couldn't determine type of right side expression '\(node.right.description.prefix(20))'...", token: node.right.token)
        }

        do {
            let type = try scope.returnType(op: node.op, opPos: opPos, params: [left, right])
            node.mooseType = type
        } catch let err as ScopeError {
            throw error(message: "Couldn't determine return type of operator: \(err.message)", token: node.token)
        }
    }
    
    override func visit(_ node: ClassStatement) throws {
        let wasGlobal = isGlobal
        isGlobal = false
        pushNewScope()
        
        guard wasGlobal else {
            throw error(message: "Classes can only be defined in global scope.", node: node)
        }
        
        for prop in node.properties {
            try scope.add(variable: prop.name.value, type: prop.declaredType, mutable: prop.mutable)
        }
        
        for meth in node.methods {
            try meth.accept(self)
        }
        
        try popScope()
        isGlobal = wasGlobal
    }

    private func error(message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
            line: token.line,
            startCol: token.column,
            endCol: token.column + token.lexeme.count,
            message: message
        )
    }

    private func error(message: String, node: Node) -> CompileErrorMessage {
        let locator = AstLocator(node: node)
        let location = locator.getLocation()

        return CompileErrorMessage(
            line: location.line,
            startCol: location.col,
            endCol: location.endCol,
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
    private func pushNewScope() {
        self.scope = TypeScope(enclosing: self.scope)
    }
    
    /// Replaces the current scope by the enclosing scope of the current scope. If it doesn't has an enclosing scope, the internal error occures.
    private func popScope() throws {
        guard let enclosing = self.scope.enclosing else {
            throw CompileErrorMessage(line: 1, startCol: 1,endCol: 1, message: "INTERNAL ERROR: Could not pop current scope \n\n\(self.scope)\n\n since it's enclosing scope is nil!")
        }
        self.scope = enclosing
    }
}
