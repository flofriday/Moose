//
// Created by flofriday on 31.05.22.
//

import Foundation

enum Precendence: Int {
    case Lowest
    case IsOperator
    case OpDefault
    case Trenary
    case DoubleQuestionMark
    case LogicalOR
    case LogicalAND
    case Equals
    case LessGreater
    case Sum
    case Product
    case Prefix
    case Postfix
    case Reference // obj dereference with .
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
        .Is: .IsOperator,
        .Operator(pos: .Prefix, assign: false): .Prefix,
        .Operator(pos: .Postfix, assign: false): .Postfix,
        .LParen: .Call,
        .LBracket: .Index,
        .Dot: .Reference,
        .QuestionMark: .Trenary,
        .DoubleQuestionMark: .DoubleQuestionMark,
    ]

    let opPrecendences: [String: Precendence] = [
        "||": .LogicalOR,
        "&&": .LogicalAND,
        "==": .Equals,
        "!=": .Equals,
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
        prefixParseFns[.Float] = parseFloatLiteral
        prefixParseFns[.Operator(pos: .Prefix, assign: false)] = parsePrefixExpression
        prefixParseFns[.Operator(pos: .Prefix, assign: true)] = parsePrefixExpression
        prefixParseFns[.Boolean(true)] = parseBoolean
        prefixParseFns[.Boolean(false)] = parseBoolean
        prefixParseFns[.LParen] = parseTupleAndGroupedExpression
        prefixParseFns[.LBracket] = parseList
        prefixParseFns[.LBrace] = parseDictInit
        prefixParseFns[.String] = parseStringLiteral
        prefixParseFns[.Nil] = parseNil
        prefixParseFns[.Me] = parseMe

        infixParseFns[.QuestionMark] = parseTernaryOperator
        infixParseFns[.DoubleQuestionMark] = parseDoubleQuestionMarkOperator
        infixParseFns[.Operator(pos: .Infix, assign: false)] = parseInfixExpression
        infixParseFns[.LParen] = parseCallExpression
        infixParseFns[.LBracket] = parseIndex
        infixParseFns[.Dot] = parseDereferer
        infixParseFns[.Is] = parseIs

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
        if check(type: .Ret) {
            // pase ReturnStatement
            return try parseReturnStatement()
        } else if check(type: .Func) {
            return try parseFunctionStatement()
            // block statements are crashing with dict constructions
            // anyways... who tf uses block statements?
//        } else if check(type: .LBrace) {
//            return try parseBlockStatement()
        } else if check(oneOf: .Prefix, .Infix, .Postfix) {
            return try parseOperationStatement()
        } else if check(type: .If) {
            return try parseIfStatement()
        } else if check(type: .Class) {
            return try parseClassDefinition()
        } else if check(type: .Extend) {
            return try parseExtendDefinition()
        } else if check(type: .For) {
            return try parseForLoop()
        } else if check(type: .Break) {
            return try parseBreak()
        } else if check(type: .Continue) {
            return try parseContinue()
        } else {
            return try parseAssignExpressionStatement()
        }
    }

    // TODO: this function is a mess and should be split up in multiple.
    /// Parses assign and expression statements. If expr starts with mut or first expression is followed by
    ///  `:` or `=`, it will parse an AssignStatement. Else it will return the expression as ExpressionStatement
    func parseAssignExpressionStatement() throws -> Statement {
        let startToken = peek()
        let mutable = match(types: .Mut)

        let exprToken = peek()
        let assignee = try parseExpression(.Lowest)

        guard mutable || check(oneOf: .Colon, .Assign, .Operator(pos: .Infix, assign: true)) else {
            try consumeStatementEnd()
            return ExpressionStatement(token: exprToken, expression: assignee)
        }

        guard let assignable = assignee as? Assignable, assignable.isAssignable else {
            // But what if they were? Sure the language would be really complex and it would be kinda useless and one
            // would have to think hard what the exact semantic would be but it is at least a truly novel idea
            // (at least I haven't heard about anything like that).
            throw error(message: "Expressions like `\(assignee.description)` are not assignable.", node: assignee)
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
            // guard !(expr is Nil) || type != nil || assignable is IndexExpression else {
            //     throw error(message: "Nil assignment only possible for typed assignments", token: token)
            // }
        } else {
            // if no assignment, nil by default
            // but end of statement expected
            guard isStatementEnd else {
                throw error(message: "Assignment or end of statement expected, but got \(token.lexeme) instead.", token: token)
            }
            guard type != nil else {
                throw error(message: "Implicit nil assignment is only valid for typed assignables.", token: previous())
            }
            expr = Nil(token: token)
        }

        try consumeStatementEnd()
        let location = Location(startToken.location, expr.location)
        return AssignStatement(token: token, location: location, assignable: assignable, value: expr, mutable: mutable, type: type)
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

        let returnType: MooseType = try parseReturnTypeDefinition() ?? VoidType()

        let body = try parseBlockStatement()
        try consumeStatementEnd()
        return FunctionStatement(token: token, name: name, body: body, params: params, returnType: returnType)
    }

    func parseAllMethodDefinitions() throws -> [FunctionStatement] {
        var methods = [FunctionStatement]()
        skip(all: .NLine)
        while check(type: .Func) {
            guard !check(oneOf: .Prefix, .Infix, .Postfix) else {
                throw error(message: "Operators have to be defined in global scope not in class definition scope.", token: peek())
            }
            guard !check(oneOf: .Class) else {
                throw error(message: "Class cannot be defined inside of other class. Class definitions are only possible in global scope", token: peek())
            }
            methods.append(try parseFunctionStatement())
            skip(all: .NLine)
        }
        return methods
    }

    func parseOperationStatement() throws -> OperationStatement {
        let posToken = try consume(oneOf: [.Infix, .Prefix, .Postfix], message: "Expected start of operator definition w0ith positional definition, but got \(peek().lexeme) instead.")

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

        let retType: MooseType = try parseReturnTypeDefinition() ?? VoidType()
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
            } else {
                isFirst = false
            }

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
        let rbrace = try consume(type: .RBrace, message: "expected } at end of function body")
        let location = Location(token.location, rbrace.location)
        return BlockStatement(token: token, location: location, statements: stmts)
    }

    func parseIfStatement() throws -> IfStatement {
        let token = try consume(type: .If, message: "'if' was expected, but got '\(peek().lexeme)' instead")

        skip(all: .NLine)
        let condition = try parseExpression(.Lowest)
        skip(all: .NLine)
        let consequence = try parseBlockStatement()
        skip(all: .NLine)
        guard match(types: .Else) else {
            return IfStatement(token: token, condition: condition, consequence: consequence, alternative: nil)
        }
        skip(all: .NLine)
        var alternative: Statement?
        if peek().type == .If {
            alternative = try parseIfStatement()
        } else {
            alternative = try parseBlockStatement()
        }

        try consumeStatementEnd()
        return IfStatement(token: token, condition: condition, consequence: consequence, alternative: alternative)
    }

    func parseClassDefinition() throws -> ClassStatement {
        let token = try consume(type: .Class, message: "'class' was expected, but got '\(peek().lexeme)' instead")

        skip(all: .NLine)
        let name = try parseIdentifier()
        skip(all: .NLine)

        var extends: Identifier?
        if case .Operator(pos: _, assign: false) = peek().type,
           peek().lexeme == "<"
        {
            _ = advance()
            extends = try parseIdentifier()
        }

        _ = try consume(type: .LBrace, message: "Expected '{' as start of class body, got '\(peek().lexeme)' instead.")
        skip(all: .NLine)
        let properties = try parseAllVariableDefinitions()
        let methods = try parseAllMethodDefinitions()
        let rbrace = try consume(type: .RBrace, message: "Expected '}' as end of class body, got '\(peek().lexeme)' instead.")

        let location = Location(token.location, rbrace.location)
        return ClassStatement(token: token, location: location, name: name, properties: properties, methods: methods, extends: extends)
    }

    func parseExtendDefinition() throws -> ExtendStatement {
        let token = try consume(type: .Extend, message: "'extend' was expected, but got '\(peek().lexeme)' instead")

        let name = try parseIdentifier()
        skip(all: .NLine)

        guard peek().lexeme != "<" else {
            throw error(message: "Extend statements cannot inherit from other classes.", token: peek())
        }

        _ = try consume(type: .LBrace, message: "Expected `{` as start of extend body, got `\(peek().lexeme)` instead.")
        skip(all: .NLine)

        let props = try parseAllVariableDefinitions()
        guard props.isEmpty else {
            throw error(message: "Class properties cannot be defined in extend statements.", token: props[0].token)
        }

        let methods = try parseAllMethodDefinitions()
        let rbrace = try consume(type: .RBrace, message: "Expected `}` as end of extend body, got `\(peek().lexeme)` instead.")
//        let location = rbrace.location(token)
        let location = Location(rbrace.location, token.location)
        return ExtendStatement(token: token, location: location, name: name, methods: methods)
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

        // parse postfix expression
        if case .Operator(pos: .Postfix, assign: _) = peek().type {
            guard let postfix = postfixParseFns[peek().type] else {
                throw error(message: "could not find postfix function for postfix operator \(String(describing: peek()))", token: peek())
            }
            leftExpr = try postfix(leftExpr)
        }

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

    func parseDereferer(_ lhs: Expression) throws -> Dereferer {
        let obj = lhs
        let prec = curPrecedence
        let token = try consume(type: .Dot, message: ". was expected, got '\(peek().lexeme)' instead.")

        if check(type: .Int) {
            let num = try parseIntegerLiteral()
            let ref = Identifier(token: num.token, value: num.value.description)
            return Dereferer(token: token, obj: lhs, referer: ref)
        }

        guard check(oneOf: .Identifier) else {
            throw error(message: "Identifier was expected for reference, got `\(peek().lexeme)` instead.", token: peek())
        }

        let ref = try parseExpression(prec)
        return Dereferer(token: token, obj: obj, referer: ref)
    }

    func parseIdentifier() throws -> Identifier {
        let ident = try consume(type: .Identifier, message: "Identifier was expected")
        return Identifier(token: ident, value: ident.literal as! String)
    }

    func parseNil() throws -> Nil {
        let n = try consume(type: .Nil, message: "'nil' was expected")
        return Nil(token: n)
    }

    func parseMe() throws -> Me {
        let token = try consume(type: .Me, message: "Expected keyword `me`, but got `\(peek().lexeme)` instead.")
        return Me(token: token)
    }

    func parseIs(expression: Expression) throws -> Is {
        let token = try consume(type: .Is, message: "Expected keyword `is`.")
        let ident = try parseIdentifier()
        return Is(token: token, expression: expression, type: ident)
    }

    func parseBreak() throws -> Break {
        let token = try consume(type: .Break, message: "Expected keyword `break`.")
        return Break(token: token)
    }

    func parseContinue() throws -> Continue {
        let token = try consume(type: .Continue, message: "Expected keyword `continue`.")
        return Continue(token: token)
    }

    func parseIntegerLiteral() throws -> IntegerLiteral {
        guard let literal = advance().literal as? Int64 else {
            throw genLiteralTypeError(t: previous(), expected: "Int64")
        }
        return IntegerLiteral(token: previous(), value: literal)
    }

    func parseFloatLiteral() throws -> Expression {
        guard let literal = advance().literal as? Float64 else {
            throw genLiteralTypeError(t: previous(), expected: "Float64")
        }
        return FloatLiteral(token: previous(), value: literal)
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
        let rparen = try consume(type: .RParen, message: "I expected a closing parenthesis here.")

        let location = Location(token.location, rparen.location)

        guard !exprs.isEmpty else {
            // TODO: We should not only point to the opening parenthesis (token) here, but also to the closing.
            throw error(message: "Parentheses have to contain an expression", token: token)
        }

        // if only one expression, it's a group
        if exprs.count == 1 {
            return exprs[0]
        }

        // more than 1 expression is a tuple
        return Tuple(token: token, location: location, expressions: exprs)
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

    func parseTernaryOperator(left: Expression) throws -> Expression {
        let condition = left
        let token = try consume(type: .QuestionMark, message: "expected ? , got '\(peek().lexeme)'")
        let consequence = try parseExpression(.Lowest)
        _ = try consume(type: .Colon, message: "expected : , got '\(peek().lexeme)'")
        let alternative = try parseExpression(.Lowest)
        return TernaryExpression(token: token, condition: condition, consequence: consequence, alternative: alternative)
    }

    func parseDoubleQuestionMarkOperator(left: Expression) throws -> Expression {
        let token = try consume(type: .DoubleQuestionMark, message: "expected ?? , got '\(peek().lexeme)'")
        let right = try parseExpression(curPrecedence)

        // Rewrite to a ternary expression
        // Example: `a ?? b`  -> `a != nil ? a : b`
        let nilToken = Token(type: .Nil, lexeme: "nil", location: token.location)
        let notEqToken = Token(type: .Operator(pos: .Infix, assign: false), lexeme: "!=", location: token.location)
        let condition = InfixExpression(token: notEqToken, left: left, op: notEqToken.lexeme, right: Nil(token: nilToken))

        return TernaryExpression(token: token, condition: condition, consequence: left, alternative: right)
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
            // TODO: If we allow higher order function you could store one in an array and call it from the array right?
            throw error(message: "Function calls are only valid for identifiers, not for `\(function.description)`", node: function)
        }

        let exprs = try parseExpressionList(seperator: .Comma, end: .RParen)
        let rparen = try consume(type: .RParen, message: "expected ')' at end of argument list")
        let location = Location(Location(token.location, rparen.location), function.location)
        return CallExpression(token: token, location: location, function: function, arguments: exprs)
    }

    /// Parses expression list until an (exclusivly) end tokentype occures.
    /// So it assumes that `(` is already consumed and does not consume nor check `)` at the end (taken on the example `(1, 2)`.
    func parseExpressionList(seperator: TokenType, end: TokenType) throws -> [Expression] {
        var list = [Expression]()
        skip(all: .NLine)

        guard !check(type: end) else {
            return list
        }

        list.append(try parseExpression(.Lowest))

        while match(types: seperator) {
            skip(all: .NLine)
            list.append(try parseExpression(.Lowest))
        }
        skip(all: .NLine)
        return list
    }
}

extension Parser {
    func consumeStatementEnd() throws {
        if
            !isAtEnd(),
            !check(type: .RBrace), // for function body such as f() {x}
            !check(type: .LBrace), // for loop in c-style `for smt; cond; stmt {}`
            !match(types: .SemiColon, .NLine)
        {
            throw error(message: "I expected, the statement to end here (with a newline or semicolon), but it kept going with '\(peek().lexeme)'.\nTipp: Maybe you forgot an (infix) operator here?", token: peek())
        }
    }

    private var isStatementEnd: Bool {
        isAtEnd() || check(oneOf: .SemiColon, .NLine, .LBrace, .RBrace)
    }

    func match(types: TokenType...) -> Bool {
        for type in types {
            if check(type: type) {
                _ = advance()
                return true
            }
        }
        return false
    }

    func consume(type: TokenType, message: String) throws -> Token {
        try consume(oneOf: [type], message: message)
    }

    private func consume(oneOf types: [TokenType], message: String) throws -> Token {
        guard check(oneOf: types) else {
            throw error(message: message, token: peek())
        }
        return advance()
    }

    func check(type: TokenType) -> Bool {
        return check(oneOf: type)
    }

    func check(oneOf types: TokenType...) -> Bool {
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

    func tokenIsBefore(toFind first: TokenType, isBefore second: TokenType, offset: Int = 0) -> Bool {
        guard (current + offset) < tokens.count else {
            return false
        }
        guard tokens[current + offset].type != second else { return false }
        if tokens[current + offset].type == first { return true }
        return tokenIsBefore(toFind: first, isBefore: second, offset: offset + 1)
    }

    func advance() -> Token {
        if !isAtEnd() {
            current += 1
        }
        return previous()
    }

    func peek2() -> Token {
        guard (current + 1) < tokens.count else {
            return tokens[tokens.count - 1]
        }
        return tokens[current + 1]
    }

    func peek() -> Token {
        guard current < tokens.count else {
            return tokens[tokens.count - 1]
        }
        return tokens[current]
    }

    func previous() -> Token {
        tokens[current - 1]
    }
}

extension Parser {
    func error(message: String, token: Token) -> CompileErrorMessage {
        // TODO: The header could be more descriptive but I cannot really
        // think of a good one in each case so this is the solution for now.
        CompileErrorMessage(
            location: token.location,
            header: "Parsing Error",
            message: message
        )
    }

    func error(message: String, node: Node) -> CompileErrorMessage {
        // TODO: The header could be more descriptive but I cannot really
        // think of a good one in each case so this is the solution for now.
        return CompileErrorMessage(
            location: node.location,
            header: "Parsing Error",
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
        let msg = "I couldn't find any prefix parse function `\(t.lexeme)` of token type \(t.type)"
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
    internal func skip(all toSkip: TokenType...) {
        while check(oneOf: toSkip) {
            current += 1
        }
    }
}
