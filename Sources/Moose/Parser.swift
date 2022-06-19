//
// Created by Johannes Zottele on 16.06.22.
//

import Foundation

enum Precendence: Int {
    case Lowest
    case Infix
    case Prefix
    case Postfix
    case Call
    case Index
}

class Parser {
    typealias prefixParseFn = () throws -> Expression
    typealias infixParseFn = (Expression) throws -> Expression
    typealias postfixParseFn = (Expression) throws -> Expression

    let l: Lexer

    var curToken: Token
    var peekToken: Token

    var errors = [ParseError]()

    var prefixParseFns = [TokenType: prefixParseFn]()
    var infixParseFns = [TokenType: infixParseFn]()
    var postfixParseFns = [TokenType: postfixParseFn]()

    let precendences: [TokenType: Precendence] = [
        .Operator: .Infix,
        .PrefixOperator: .Prefix,
        .PostfixOperator: .Postfix,
    ]

    init(_ l: Lexer) {
        self.l = l
        self.curToken = l.nextToken()
        self.peekToken = l.nextToken()

        // TODO: add parse functions
        prefixParseFns[.Identifier] = parseIdentifier
        prefixParseFns[.Int] = parseIntegerLiteral
        prefixParseFns[.PrefixOperator] = parsePrefixExpression
        prefixParseFns[.True] = parseBoolean
        prefixParseFns[.False] = parseBoolean
        prefixParseFns[.LParen] = parseGroupedExpression

        infixParseFns[.Operator] = parseInfixExpression
    }
}

extension Parser {
    private func nextToken() {
        curToken = peekToken
        peekToken = l.nextToken()
    }

    func parseProgram() -> Program {
        var statements = [Statement]()
        while curToken.type != .EOF {
            do {
                let stmt = try parseStatement()
                statements.append(stmt)
            } catch let e as ParseError {
                errors.append(e)
            } catch {}
            nextToken()
        }

        return Program(statements: statements)
    }

    func parseStatement() throws -> Statement {
        if curToken.type == .Mut || peekToken.type == .Assign {
            // parse AssignStatement
            return try parseAssignStatement()
        } else if curToken.type == .Ret {
            // pase ReturnStatement
            return try parseReturnStatement()
        } else {
            // parse ExpressionStatement
            return try parseExpressionStatement()
        }
    }

    func parseAssignStatement() throws -> AssignStatement {
        var mutable = false
        let token = curToken

        if curToken.type == .Mut {
            mutable = true
            nextToken()
        }

        guard curToken.type == .Identifier else {
            throw ParseError.tokenTypeError(msg: "Identifier expected for assignment", expected: .Identifier, received: curToken.type, curToken.line, curToken.column)
        }

        let ident = Identifier(token: curToken, value: curToken.lexeme)
        try expectPeek(.Assign)

        nextToken() // from '=' to 'expr'
        let val = try parseExpression(.Lowest)

        skipStatementEnd()
        return AssignStatement(token: token, name: ident, value: val, mutable: mutable)
    }

    func parseReturnStatement() throws -> ReturnStatement {
        let token = curToken
        try expectCurrent(.Ret)
//        nextToken()
        let val = try parseExpression(.Lowest)
        skipStatementEnd()
        return ReturnStatement(token: token, returnValue: val)
    }

    func parseExpressionStatement() throws -> ExpressionStatement {
        let token = curToken
        let val = try parseExpression(.Lowest)
        skipStatementEnd()
        return ExpressionStatement(token: token, expression: val)
    }

    func parseExpression(_ prec: Precendence) throws -> Expression {
        // TODO: implement parseExpression Function
        let prefix = prefixParseFns[curToken.type]
        guard let prefix = prefix else {
            throw noPrefixParseFnError(t: curToken)
        }
        var leftExpr = try prefix()
        while !isStatementEnd(), prec.rawValue < peekPrecedence.rawValue {
            let infix = infixParseFns[peekToken.type]
            guard let infix = infix else {
                return leftExpr
            }
            nextToken()
            leftExpr = try infix(leftExpr)
        }
        return leftExpr
    }

    func parseIdentifier() throws -> Expression {
        guard let literal = curToken.literal as? String else {
            throw genLiteralTypeError(t: curToken, expected: "String")
        }
        return Identifier(token: curToken, value: literal)
    }

    func parseIntegerLiteral() throws -> Expression {
        guard let literal = curToken.literal as? Int64 else {
            throw genLiteralTypeError(t: curToken, expected: "Int64")
        }
        return IntegerLiteral(token: curToken, value: literal)
    }

    func parseBoolean() throws -> Expression {
        guard let literal = curToken.literal as? Bool else {
            throw genLiteralTypeError(t: curToken, expected: "Bool")
        }
        return Boolean(token: curToken, value: literal)
    }

    func parseGroupedExpression() throws -> Expression {
        nextToken()
        let exp = try parseExpression(.Lowest)
        try expectPeek(.RParen)
        return exp
    }

    func parsePrefixExpression() throws -> Expression {
        let token = curToken
        nextToken()
        let rightExpr = try parseExpression(.Prefix)
        return PrefixExpression(token: token, op: token.lexeme, right: rightExpr)
    }

    func parseInfixExpression(left: Expression) throws -> Expression {
        let token = curToken
        let prec = curPrecedence
        nextToken()
        let right = try parseExpression(prec)
        return InfixExpression(token: token, left: left, op: token.lexeme, right: right)
    }
}

extension Parser {
    func curTokenIs(_ t: TokenType) -> Bool {
        return curToken.type == t
    }

    func peekTokenIs(_ t: TokenType) -> Bool {
        return peekToken.type == t
    }

    func expectPeek(_ t: TokenType) throws {
        guard peekTokenIs(t) else {
            throw peekError(expected: t, got: curToken.type)
        }
        nextToken()
    }

    func expectCurrent(_ t: TokenType) throws {
        guard curTokenIs(t) else {
            throw curError(expected: curToken.type, got: t)
        }
        nextToken()
    }

    func isStatementEnd() -> Bool {
        peekTokenIs(.SemiColon) || peekTokenIs(.NLine) || peekTokenIs(.EOF)
    }

    func skipStatementEnd() {
        if isStatementEnd() {
            nextToken()
        }
    }
}

extension Parser {
    func peekError(expected: TokenType, got: TokenType) -> ParseError {
        let msg = "expected next to be \(expected), got \(got) instead"
        return ParseError.tokenTypeError(msg: msg, expected: expected, received: got, peekToken.line, peekToken.column)
    }

    func curError(expected: TokenType, got: TokenType) -> ParseError {
        let msg = "expected token to be \(expected), got \(got) instead"
        return ParseError.tokenTypeError(msg: msg, expected: expected, received: got, curToken.line, curToken.column)
    }

    func noPrefixParseFnError(t: Token) -> ParseError {
        let msg = "no prefix parse function for \(t.type) found"
        return ParseError.noParseFn(msg: msg, type: t.type, t.line, t.column)
    }

    func genLiteralTypeError(t: Token, expected: String) -> ParseError {
        let msg = "expected literal '\(t.lexeme)' (literal: \(t.literal ?? "nil")) to be of type \(expected)"
        return ParseError.literalTypeError(
            msg: msg,
            expected: expected,
            received: String(describing: type(of: t.literal)),
            t.line, t.column)
    }
}

extension Parser {
    var peekPrecedence: Precendence {
        /// - Todo: implement Precendence
        guard let prec = precendences[peekToken.type] else {
            return .Lowest
        }
        return prec
    }

    var curPrecedence: Precendence {
        /// - Todo: implement Precendence
        guard let prec = precendences[curToken.type] else {
            return .Lowest
        }
        return prec
    }
}
