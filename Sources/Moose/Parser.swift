//
// Created by flofriday on 31.05.22.
//

import Foundation

enum Precendence: Int {
    case Lowest
    case Equals
    case LessGreater
    case Sum
    case Product
    case Prefix
    case Call
    case Index
}

class Parser {
    typealias prefixParseFn = () throws -> Expression
    typealias infixParseFn = (Expression) throws -> Expression
    typealias postfixParseFn = (Expression) throws -> Expression

    private let tokens: [Token]
    private var current = 0
    private var errors: [CompileErrorMessage] = []

    var prefixParseFns = [TokenType: prefixParseFn]()
    var infixParseFns = [TokenType: infixParseFn]()
    var postfixParseFns = [TokenType: postfixParseFn]()

    init(tokens: [Token]) {
        self.tokens = tokens

        // TODO: add parse functions
        prefixParseFns[.Identifier] = parseIdentifier
        prefixParseFns[.Int] = parseIntegerLiteral
        prefixParseFns[.PrefixOperator] = parsePrefixExpression
        prefixParseFns[.True] = parseBoolean
        prefixParseFns[.False] = parseBoolean
        prefixParseFns[.LParen] = parseGroupedExpression

        infixParseFns[.Operator] = parseInfixExpression
    }

    func parse() throws -> Program {
        var statements: [Statement] = []

        while (!isAtEnd()) {
            do {
                let stmt = try parseStatement()
                statements.append(stmt)
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
        advance();
        while (!isAtEnd()) {
            if (previous().type == .NLine || previous().type == .SemiColon) {
                return
            }

            // TODO: maybe we need more a check of the type of token just like jLox has.
            advance()
        }
    }


    func parseStatement() throws -> Statement {
        // TODO: the assign doesn't work for arrays
        if match(types: .Mut) || peek().type == .Assign {
            // parse AssignStatement
            return try parseAssignStatement()
        } else if match(types: .Ret) {
            // pase ReturnStatement
            return try parseReturnStatement()
        } else {
            // parse ExpressionStatement
            return try parseExpressionStatement()
        }
    }

    func parseAssignStatement() throws -> AssignStatement {
        var mutable = previous().type == .Mut

        let identifierToken = try consume(type: .Identifier, message: "You can only assign values to identifiers.")
        let ident = Identifier(token: identifierToken, value: identifierToken.lexeme)
        let token = try consume(type: .Assign, message: "I expected a '=' after a variable decleration.")

        let val = try parseExpression(.Lowest)


        try consumeStatementEnd()
        return AssignStatement(token: token, name: ident, value: val, mutable: mutable)
    }

    func parseReturnStatement() throws -> ReturnStatement {
        let token = previous()
        let val = try parseExpression(.Lowest)
        try consumeStatementEnd()
        return ReturnStatement(token: token, returnValue: val)
    }

    func parseExpressionStatement() throws -> ExpressionStatement {
        let token = peek()
        let val = try parseExpression(.Lowest)
        // TODO: skip end of statement
        //try consumeStatementEnd()
        return ExpressionStatement(token: token, expression: val)
    }

    func parseExpression(_ prec: Precendence) throws -> Expression {
        // TODO: implement parseExpression Function
        let prefix = prefixParseFns[peek().type]
        guard let prefix = prefix else {
            throw noPrefixParseFnError(t: peek())
        }
        print(peek().type)
        var leftExpr = try prefix()
        print(current)
        while !isAtEnd() && prec.rawValue < peekPrecedence.rawValue {
            let infix = infixParseFns[peek2().type]
            guard let infix = infix else {
                return leftExpr
            }
            advance()
            print("inner")
            print(current)
            leftExpr = try infix(leftExpr)
        }
        print("done")
        return leftExpr
    }

    func parseIdentifier() throws -> Expression {
        let literal = advance().literal as! String
        return Identifier(token: peek(), value: literal)
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

    func parseGroupedExpression() throws -> Expression {
        advance()
        let exp = try parseExpression(.Lowest)
        try consume(type: .RParen, message: "I expected a closing parenthesis here.")
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

//    private func expressionStmt() throws -> Stmt {
//        var expr = try expression()
//        if !isAtEnd() {
//            try consume(type: .NLine, message: "I expected here a newline.")
//        }
//        return Stmt.ExprStmt(expr)
//    }
//
//    private func expression() throws -> Expr {
//        let token = try consume(type: .Int, message: "I can only process Ints at the moment")
//        return Expr.value(token.literal as! Int)
//    }

    private func consumeStatementEnd() throws {
        if !isAtEnd() && !match(types: .SemiColon, .NLine) {
            throw error(message: "I expected, the statement to end with a newline or semicolon.", token: peek())
        }
    }

    private func match(types: TokenType...) -> Bool {
        for type in types {
            if (check(type: type)) {
                advance()
                return true
            }
        }
        return false;
    }


    private func consume(type: TokenType, message: String) throws -> Token {
        if !check(type: type) {
            throw error(message: message, token: peek())
        }
        return advance()
    }

    private func check(type: TokenType) -> Bool {
        if isAtEnd() {
            return false
        }
        return peek().type == type
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
        tokens[current + 1]
    }

    private func peek() -> Token {
        tokens[current]
    }

    private func previous() -> Token {
        tokens[current - 1]
    }

    private func error(message: String, token: Token) -> CompileErrorMessage {
        CompileErrorMessage(
                line: token.line,
                startCol: token.column,
                endCol: token.column + token.lexeme.count,
                message: message
        )
    }
}


extension Parser {
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
        let msg = "I expected literal '\(t.lexeme)' (literal: \(t.literal)) to be of type \(expected)"
        return error(message: msg, token: peek())
    }
}

extension Parser {
    var peekPrecedence: Precendence {
        /// - Todo: implement Precedence
        .Lowest
    }

    var curPrecedence: Precendence {
        /// - Todo: implement Precedence
        .Lowest
    }
}