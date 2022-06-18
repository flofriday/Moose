//
// Created by flofriday on 31.05.22.
//

import Foundation

class Parser {
    private let tokens: [Token]
    private var current = 0
    private var errors: [CompileErrorMessage] = []

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parse() throws -> [Stmt] {
        var statements: [Stmt] = []

        while (!isAtEnd()) {
            do {
                let stmt = try expressionStmt()
                statements.append(stmt)
            } catch is ParseError {
                // We are inside an error and got confused during parsing.
                // Let's skip to the next thing we recognize so that we can continue parsing.
                // Continuing parsing is important so that we can catch all parsing errors at once.
                synchronize()
            } catch {
            }
        }

        if errors.count > 0 {
            throw CompileError(messages: errors)
        }

        return statements
    }

    private func synchronize() {
        advance();
        while (!isAtEnd()) {
            if (previous().type == .NLine) {
                return
            }

            // TODO: maybe we need more a check of the type of token just like jLox has.
        }
    }

    private func expressionStmt() throws -> Stmt {
        var expr = try expression()
        if !isAtEnd() {
            try consume(type: .NLine, message: "I expected here a newline.")
        }
        return Stmt.ExprStmt(expr)
    }

    private func expression() throws -> Expr {
        let token = try consume(type: .Int, message: "I can only process Ints at the moment")
        return Expr.value(token.literal as! Int)
    }

    private func consume(type: TokenType, message: String) throws -> Token {
        if !check(type: type) {
            try error(message: message, token: peek())
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

    private func peek() -> Token {
        tokens[current]
    }

    private func previous() -> Token {
        tokens[current - 1]
    }

    private func error(message: String, token: Token) throws {
        let msg = CompileErrorMessage(
                line: token.line,
                startCol: token.column,
                endCol: token.column + token.lexeme.count,
                message: message
        )
        errors.append(msg)
        throw ParseError()
    }

    private class ParseError: Error {
    }
}
