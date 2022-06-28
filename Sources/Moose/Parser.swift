//
// Created by flofriday on 31.05.22.
//

import Foundation

enum Precendence: Int {
    case Lowest
    case OpDefault
    case Equals
    case LessGreater
    case Sum
    case Product
    case Prefix
    case Postfix
    case Call
    case Index
}

class Parser {
    typealias prefixParseFn = () throws -> Expression
    typealias infixParseFn = (Expression) throws -> Expression
    typealias postfixParseFn = (Expression) throws -> Expression

    private var tokens: [Token]
    private var current = 0
    private var errors: [CompileErrorMessage] = []

    var prefixParseFns = [TokenType: prefixParseFn]()
    var infixParseFns = [TokenType: infixParseFn]()
    var postfixParseFns = [TokenType: postfixParseFn]()

    // precendences by type
    let typePrecendences: [TokenType: Precendence] = [
        .Operator(pos: .Prefix, assign: false): .Prefix,
        .Operator(pos: .Postfix, assign: false): .Postfix,
        .LParen: .Call,
    ]

    let opPrecendences: [String: Precendence] = [
        "==": .Equals,
        "<": .LessGreater,
        ">": .LessGreater,
        "<=": .LessGreater,
        ">=": .LessGreater,
        "+": .Sum,
        "-": .Sum,
        "*": .Product,
        "/": .Product,
    ]

    init(tokens: [Token]) {
        self.tokens = tokens

        // TODO: add parse functions
        prefixParseFns[.Identifier] = parseIdentifier
        prefixParseFns[.Int] = parseIntegerLiteral
        prefixParseFns[.Operator(pos: .Prefix, assign: false)] = parsePrefixExpression
        prefixParseFns[.Operator(pos: .Prefix, assign: true)] = parsePrefixExpression
        prefixParseFns[.Boolean(true)] = parseBoolean
        prefixParseFns[.Boolean(false)] = parseBoolean
        prefixParseFns[.LParen] = parseTupleAndGroupedExpression
        prefixParseFns[.String] = parseStringLiteral
        prefixParseFns[.Nil] = parseNil

        infixParseFns[.Operator(pos: .Infix, assign: false)] = parseInfixExpression
        infixParseFns[.LParen] = parseCallExpression

        postfixParseFns[.Operator(pos: .Postfix, assign: true)] = parsePostfixExpression
        postfixParseFns[.Operator(pos: .Postfix, assign: false)] = parsePostfixExpression
    }

    func parse() throws -> Program {
        var statements: [Statement] = []

        skip(all: .NLine)
        while !isAtEnd() {
            do {
                let stmt = try parseStatement()
                statements.append(stmt)
                skip(all: .NLine)
            } catch let e as CompileErrorMessage {
                // We are inside an error and got confused during parsing.
                // Let's skip to the next thing we recognize so that we can continue parsing.
                // Continuing parsing is important so that we can catch all parsing errors at once.
                errors.append(e)
                synchronize()
            }
        }

        if errors.count > 0 {
            throw CompileError(messages: errors)
        }

        return Program(statements: statements)
    }

    private func synchronize() {
        _ = advance()
        while !isAtEnd() {
            if previous().type == .NLine || previous().type == .SemiColon {
                return
            }

            // TODO: maybe we need more a check of the type of token just like jLox has.
            _ = advance()
        }
    }

    func parseStatement() throws -> Statement {
        // TODO: the assign doesn't work for arrays

        if check(type: .Ret) {
            // pase ReturnStatement
            return try parseReturnStatement()
        } else if check(type: .Func) {
            return try parseFunctionStatement()
        } else if check(type: .LBrace) {
            return try parseBlockStatement()
        } else if check(oneOf: .Prefix, .Infix, .Postfix) {
            return try parseOperationStatement()
        } else if check(type: .If) {
            return try parseIfStatement()
        } else {
            return try parseAssignExpressionStatement()
        }
    }

    /// Parses assign and expression statements. If expr starts with mut or first expression is followed by
    ///  `:` or `=`, it will parse an AssignStatement. Else it will return the expression as ExpressionStatement
    func parseAssignExpressionStatement() throws -> Statement {
        let mutable = match(types: .Mut)

        let exprToken = peek()
        let assignable = try parseExpression(.Lowest)

        guard mutable || check(oneOf: .Colon, .Assign, .Operator(pos: .Infix, assign: true)) else {
            try consumeStatementEnd()
            return ExpressionStatement(token: exprToken, expression: assignable)
        }

        guard let assignable = assignable as? Assignable, assignable.isAssignable else {
            throw error(message: "Expression '\(assignable.description)' is not assignable.", token: exprToken)
        }

        var type: MooseType?
        if check(type: .Colon) {
            _ = advance()
            type = try parseValueTypeDefinition()
        }

        // do not consume since it could be the operator of assign operator such as +: 3
        var token = peek()

        var expr: Expression = assignable
        if case .Operator(pos: .Infix, assign: true) = token.type {
            // manipulate ast from a +: 2 to a = a + 2
            expr = try parseInfixExpression(left: expr)
        } else if check(type: .Assign) {
            token = try consume(oneOf: [.Assign], message: "I expected a '=' after a variable decleration.")
            expr = try parseExpression(.Lowest)
            guard !(expr is Nil) || type != nil else {
                throw error(message: "Nil assignment only possible for typed assignments", token: token)
            }
        } else {
            // if no assignment, nil by default
            // but end of statement expected
            guard isStatementEnd else {
                throw error(message: "Assignment or end of statement expected, but got \(token.lexeme) instead", token: token)
            }
            guard type != nil else {
                throw error(message: "Implicit nil assignment is only valid for typed assignables", token: previous())
            }
            expr = Nil(token: token)
        }

        try consumeStatementEnd()
        return AssignStatement(token: token, assignable: assignable, value: expr, mutable: mutable, type: type)
    }

    func parseReturnStatement() throws -> ReturnStatement {
        let token = try consume(type: .Ret, message: "expected that return statement starts with 'return', but got '\(peek())' instead")
        var val: Expression?
        if !isStatementEnd {
            val = try parseExpression(.Lowest)
        }
        try consumeStatementEnd()
        return ReturnStatement(token: token, returnValue: val)
    }

    func parseFunctionStatement() throws -> FunctionStatement {
        let token = try consume(type: .Func, message: "func keyword was expected")

        // remove all newlines since these are not relevant for function definition
        remove(all: .NLine, until: .LBrace)

        let name = try parseIdentifier()
        let params = try parseFunctionParameters()

        let returnType: MooseType = try parseReturnTypeDefinition() ?? .Void

        let body = try parseBlockStatement()
        try consumeStatementEnd()
        return FunctionStatement(token: token, name: name, body: body, params: params, returnType: returnType)
    }

    func parseOperationStatement() throws -> OperationStatement {
        let posToken = try consume(oneOf: [.Infix, .Prefix, .Postfix], message: "Expected start of operator definition with positional definition, but got \(peek().lexeme) instead.")

        // remove all newlines since these are not relevant for operator definition
        remove(all: .NLine, until: .LBrace)

        guard let pos = OpPos.from(token: posToken.type) else {
            throw error(message: "Could not determine operator position.", token: posToken)
        }

        guard case .Operator(pos: _, assign: let isAssign) = peek().type else {
            throw error(message: "Operator name definition expected. Got \(peek().lexeme) instead.", token: peek())
        }
        let opToken = advance()

        // is this smart? maybe not, since if the operator name ends with : we can only use this operator as assign operator
        let opNameExt = isAssign ? ":" : ""
        let opName = opToken.lexeme + opNameExt

        let paramStartToken = peek()
        guard paramStartToken.type == .LParen else {
            throw error(message: "Expected start of operation parameter list, but got '\(peek().lexeme)' instead.", token: peek())
        }

        let params = try parseFunctionParameters()
        guard params.count == pos.numArgs else {
            throw error(message: "Expected \(pos.numArgs) parameter for \(pos) operation, but got \(params.count) parameters instead", token: paramStartToken)
        }

        let retType: MooseType = try parseReturnTypeDefinition() ?? .Void
        let body = try parseBlockStatement()
        try consumeStatementEnd()
        return OperationStatement(token: posToken, name: opName, position: pos, body: body, params: params, returnType: retType)
    }

    func parseFunctionParameters() throws -> [VariableDefinition] {
        var defs = [VariableDefinition]()
        _ = try consume(type: .LParen, message: "expected begin of parameter definition with (, but got \(peek().lexeme) instead")

        var isFirst = true
        while !check(type: .RParen) {
            // expect , seperator
            if !isFirst {
                _ = try consume(type: .Comma, message: "parameter seperator ',' expected, but got '\(peek().lexeme)' instead")
            } else { isFirst = false }

            let def = try parseVariableDefinition()
            defs.append(def)
        }
        _ = try consume(type: .RParen, message: "expected end of parameter definition with ), but got \(peek().lexeme) instead")
        return defs
    }

    func parseBlockStatement() throws -> BlockStatement {
        let token = try consume(type: .LBrace, message: "expected start of body starting with {")
        var stmts = [Statement]()
        skip(all: .NLine)
        while !check(type: .RBrace) {
            stmts.append(try parseStatement())
            skip(all: .NLine)
        }
        _ = try consume(type: .RBrace, message: "expected } at end of function body")
        return BlockStatement(token: token, statements: stmts)
    }

    func parseIfStatement() throws -> IfStatement {
        let token = try consume(type: .If, message: "'if' was expected, but got '\(peek().lexeme)' instead")

        skip(all: .NLine)
        let condition = try parseExpression(.Lowest)
        skip(all: .NLine)
        let consequence = try parseBlockStatement()
        guard match(types: .Else) else {
            return IfStatement(token: token, condition: condition, consequence: consequence, alternative: nil)
        }
        skip(all: .NLine)
        let alternative = try parseBlockStatement()
        try consumeStatementEnd()
        return IfStatement(token: token, condition: condition, consequence: consequence, alternative: alternative)
    }

    @available(*, deprecated, message: "This method is deprecated since parseAssignExpressionStatement is used to parse ExpressionStatements")
    func parseExpressionStatement() throws -> ExpressionStatement {
        let token = peek()
        let val = try parseExpression(.Lowest)
        // TODO: skip end of statement
        try consumeStatementEnd()
        return ExpressionStatement(token: token, expression: val)
    }

    func parseExpression(_ prec: Precendence) throws -> Expression {
        // parse prefix expression
        let prefix = prefixParseFns[peek().type]
        guard let prefix = prefix else {
            throw noPrefixParseFnError(t: peek())
        }
        var leftExpr = try prefix()

        // -----

        // parse postfix expression
        if case .Operator(pos: .Postfix, assign: _) = peek().type {
            guard let postfix = postfixParseFns[peek().type] else {
                throw error(message: "could not find postfix function for postfix operator \(String(describing: peek()))", token: peek())
            }
            leftExpr = try postfix(leftExpr)
        }

        // -----

        // parse infix expression
        while !isAtEnd(), prec.rawValue < curPrecedence.rawValue {
            let infix = infixParseFns[peek().type]
            guard let infix = infix else {
                return leftExpr
            }
            leftExpr = try infix(leftExpr)
        }
        return leftExpr
    }

    func parseIdentifier() throws -> Identifier {
//        let ident = advance()
        let ident = try consume(type: .Identifier, message: "Identifier was expected")
        return Identifier(token: ident, value: ident.literal as! String)
    }

    func parseNil() throws -> Nil {
        let n = try consume(type: .Nil, message: "'nil' was expected")
        return Nil(token: n)
    }

    func parseIntegerLiteral() throws -> Expression {
        guard let literal = advance().literal as? Int64 else {
            throw genLiteralTypeError(t: previous(), expected: "Int64")
        }
        return IntegerLiteral(token: previous(), value: literal)
    }

    func parseBoolean() throws -> Expression {
        guard let literal = advance().literal as? Bool else {
            throw genLiteralTypeError(t: previous(), expected: "Bool")
        }
        return Boolean(token: previous(), value: literal)
    }

    func parseStringLiteral() throws -> StringLiteral {
        let token = try consume(type: .String, message: "excpected to get a string, but go \(peek().lexeme) instead.")
        return StringLiteral(token: token, value: token.literal as! String)
    }

    // groups only contain 1 expression while tuple contain 2 or more
    func parseTupleAndGroupedExpression() throws -> Expression {
        let token = try consume(type: .LParen, message: "'(' expected, but got \(peek().lexeme) instead.")
        let exprs = try parseExpressionList(seperator: .Comma, end: .RParen)
        _ = try consume(type: .RParen, message: "I expected a closing parenthesis here.")

        guard !exprs.isEmpty else {
            throw error(message: "Priority parentheses have to contain an expression", token: token)
        }

        // if only one expression, it's a group
        if exprs.count == 1 {
            return exprs[0]
        }

        // more than 1 expression is a tuple
        return Tuple(token: token, expressions: exprs)
    }

    func parseGroupedExpression() throws -> Expression {
        _ = advance()
        let exp = try parseExpression(.Lowest)
        _ = try consume(type: .RParen, message: "I expected a closing parenthesis here.")
        return exp
    }

    func parsePrefixExpression() throws -> Expression {
        let token = advance()
        let rightExpr = try parseExpression(.Prefix)
        return PrefixExpression(token: token, op: token.lexeme, right: rightExpr)
    }

    func parseInfixExpression(left: Expression) throws -> Expression {
        let prec = curPrecedence
        let token = advance()
        let right = try parseExpression(prec)
        return InfixExpression(token: token, left: left, op: token.lexeme, right: right)
    }

    func parsePostfixExpression(left: Expression) throws -> Expression {
        let token = advance()
        return PostfixExpression(token: token, left: left, op: token.lexeme)
    }

    func parseCallExpression(function: Expression) throws -> CallExpression {
        let token = try consume(type: .LParen, message: "excepted '(' for function call, but got \(peek().lexeme) instead.")
        guard let function = function as? Identifier else {
            throw error(message: "function call is only valid for identifiers, not \(function.description)", token: token)
        }

        let exprs = try parseExpressionList(seperator: .Comma, end: .RParen)
        _ = try consume(type: .RParen, message: "expected ')' at end of argument list")
        return CallExpression(token: token, function: function, arguments: exprs)
    }

    /// Parses expression list until an (exclusivly) end tokentype occures.
    /// So it assumes that `(` is already consumed and does not consume nor check `)` at the end (taken on the example `(1, 2)`.
    func parseExpressionList(seperator: TokenType, end: TokenType) throws -> [Expression] {
        var list = [Expression]()

        guard !check(type: end) else {
            return list
        }

        list.append(try parseExpression(.Lowest))

        while match(types: seperator) {
            list.append(try parseExpression(.Lowest))
        }

        return list
    }

    /// returns type of `> Type`. If there was no `>` nil is returned
    func parseReturnTypeDefinition() throws -> MooseType? {
        if !check(type: .LBrace) {
            let toTok = advance() // > token as infix prefix or postfix op
            guard
                case .Operator(pos: _, assign: false) = toTok.type,
                toTok.lexeme == ">"
            else {
                throw error(message: "expected > in function signature to define type, but got \(toTok.lexeme) instead", token: toTok)
            }
            return try parseValueTypeDefinition()
        }

        return nil
    }

    // -----------------------
    // ---- TypeDefinition ---

    func parseValueTypeDefinition() throws -> MooseType {
        switch peek().type {
        case .Void:
            return try parseVoidTypeDefinition()
        case .Identifier:
            let ident = try parseIdentifier()
            return MooseType.toClass(ident.value)
        case .LParen:
            return try parseTupleGroupFunction_TypeDefinition()
        default:
            throw error(message: "Could not find type definition parsing method for token \(peek().type)", token: peek())
        }
    }

    func parseVoidTypeDefinition() throws -> MooseType {
        let _ = try consume(type: .Void, message: "expected 'Void', but got \(peek().lexeme) instead")
        return .Void
    }

    @available(*, deprecated, message: "This method is deprecated since parseTupleGroupFunction_TypeDefinition is used to parse Tuple")
    func parseTupleTypeDefinition() throws -> MooseType {
        let token = try consume(type: .LParen, message: "expected an starting ( for tupel definition")
        var types = [MooseType]()
        repeat {
            let t = try parseValueTypeDefinition()
            types.append(t)
        } while match(types: .Comma)
        _ = try consume(type: .RParen, message: "expected closing ) at end of tuple, got \(peek().lexeme)")
        guard types.count > 1 else {
            throw error(message: "tuple have to contain at least 2 values", token: token)
        }
        return .Tuple(types)
    }

    func parseFunctionTypeDefinition(params: [MooseType]) throws -> MooseType {
        guard case .Operator(pos: _, false) = peek().type, peek().lexeme == ">" else {
            throw error(message: "Expected a '>' for function defintion, but got \(peek().lexeme) instead.", token: peek())
        }
        _ = advance()

        let resultType = try parseValueTypeDefinition()
        return .Function(params, resultType)
    }

    func parseTupleGroupFunction_TypeDefinition() throws -> MooseType {
        _ = try consume(type: .LParen, message: "Expected a starting '(', but got \(peek().lexeme) instead.")
        let types = try parseTypeDefinitionList(seperator: .Comma, end: .RParen)

        // if next token is '>', it is a function type, else its a void, tuple or group (Int) that is mapped to Int
        if case .Operator(pos: _, false) = peek2().type, peek2().lexeme == ">" {
            _ = try consume(type: .RParen, message: "expected closing ) at end of function parameter definition, got \(peek().lexeme)")
            return try parseFunctionTypeDefinition(params: types)
        } else if types.isEmpty {
            _ = try consume(type: .RParen, message: "expected closing ) at end of Void definition, got \(peek().lexeme)")
            return .Void
        } else if types.count == 1 {
            _ = try consume(type: .RParen, message: "expected closing ) at end of group defintion, got \(peek().lexeme)")
            return types[0]
        } else {
            _ = try consume(type: .RParen, message: "expected closing ) at end of tuple, got \(peek().lexeme)")
            return .Tuple(types)
        }
    }

    func parseTypeDefinitionList(seperator: TokenType, end: TokenType) throws -> [MooseType] {
        var list = [MooseType]()

        guard !check(type: end) else {
            return list
        }

        list.append(try parseValueTypeDefinition())
        while match(types: seperator) {
            list.append(try parseValueTypeDefinition())
        }
        return list
    }

    // strongly typed, currently used by parameter and class property definitions
    func parseVariableDefinition() throws -> VariableDefinition {
        let mut = match(types: .Mut)
        let ident = try parseIdentifier()
        _ = try consume(type: .Colon, message: "expected : to define type, but got \(peek().lexeme) instead")
        let type = try parseValueTypeDefinition()
        return VariableDefinition(token: ident.token, mutable: mut, name: ident, type: type)
    }
}

extension Parser {
    private func consumeStatementEnd() throws {
        if
            !isAtEnd(),
            !check(type: .RBrace), // for function body such as f() {x}
            !match(types: .SemiColon, .NLine)
        {
            throw error(message: "I expected, the statement to end here (with a newline or semicolon), but it kept going with '\(peek().lexeme)'.\nTipp: Maybe you forgot an (infix) operator here?", token: peek())
        }
    }

    private var isStatementEnd: Bool {
        isAtEnd() || check(oneOf: .SemiColon, .NLine)
    }

    private func match(types: TokenType...) -> Bool {
        for type in types {
            if check(type: type) {
                _ = advance()
                return true
            }
        }
        return false
    }

    private func consume(type: TokenType, message: String) throws -> Token {
        try consume(oneOf: [type], message: message)
    }

    private func consume(oneOf types: [TokenType], message: String) throws -> Token {
        guard check(oneOf: types) else {
            throw error(message: message, token: peek())
        }
        return advance()
    }

    private func check(type: TokenType) -> Bool {
        return check(oneOf: type)
    }

    private func check(oneOf types: TokenType...) -> Bool {
        return check(oneOf: types)
    }

    private func check(oneOf types: [TokenType]) -> Bool {
        if isAtEnd() {
            return false
        }
        return types.contains(peek().type)
    }

    private func assert(token: Token, ofType type: TokenType, _ msg: String) throws {
        guard case type = token.type else {
            throw error(message: msg, token: token)
        }
    }

    private func isAtEnd() -> Bool {
        peek().type == .EOF
    }

    private func advance() -> Token {
        if !isAtEnd() {
            current += 1
        }
        return previous()
    }

    private func peek2() -> Token {
        guard (current + 1) < tokens.count else {
            return tokens[tokens.count - 1]
        }
        return tokens[current + 1]
    }

    private func peek() -> Token {
        guard current < tokens.count else {
            return tokens[tokens.count - 1]
        }
        return tokens[current]
    }

    private func previous() -> Token {
        tokens[current - 1]
    }
}

extension Parser {
    private func error(message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
            line: token.line,
            startCol: token.column,
            endCol: token.column + token.lexeme.count,
            message: message
        )
    }

    func peekError(expected: TokenType, got: TokenType) -> CompileErrorMessage {
        let msg = "I expected next to be \(expected), got \(got) instead"
        return error(message: msg, token: peek2())
    }

    func curError(expected: TokenType, got: TokenType) -> CompileErrorMessage {
        let msg = "I expected token to be \(expected), got \(got) instead"
        return error(message: msg, token: peek())
    }

    func noPrefixParseFnError(t: Token) -> CompileErrorMessage {
        let msg = "I couldn't find any prefix parse function for \(t.type)"
        return error(message: msg, token: peek())
    }

    func genLiteralTypeError(t: Token, expected: String) -> CompileErrorMessage {
        let msg = "I expected literal '\(t.lexeme)' (literal: \(String(describing: t.literal))) to be of type \(expected)"
        return error(message: msg, token: peek())
    }
}

extension Parser {
    private func getPrecedence(of t: Token) -> Precendence {
        // in case of assign statement a *: 3 + 2. this should be evaluated as a *: (3 + 2)
        if case .Operator(pos: .Infix, assign: true) = t.type {
            return .Lowest
        } else if case .Operator = t.type {
            guard let prec = opPrecendences[t.lexeme] else {
                return .OpDefault
            }
            return prec
        } else {
            guard let prec = typePrecendences[t.type] else {
                return .Lowest
            }
            return prec
        }
    }

    var peekPrecedence: Precendence {
        getPrecedence(of: peek2())
    }

    var curPrecedence: Precendence {
        getPrecedence(of: peek())
    }
}

extension Parser {
    /// Removes all tokens of type all, until the first appearance of until.
    /// This is mostly used to remove new line tokens.
    private func remove(all toRemove: TokenType, until: TokenType) {
        var i = current
        while tokens[i].type != .EOF, tokens[i].type != until {
            if tokens[i].type == toRemove {
                tokens.remove(at: i)
            } else {
                i += 1
            }
        }
    }

    /// Skips all tokenTypes until something else was found.
    private func skip(all toSkip: TokenType...) {
        while check(oneOf: toSkip) {
            current += 1
        }
    }
}
