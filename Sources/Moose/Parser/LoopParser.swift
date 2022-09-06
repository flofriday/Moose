//
//  File.swift
//
//
//  Created by Johannes Zottele on 16.08.22.
//

import Foundation

extension Parser {
    func parseForLoop() throws -> Statement {
        let token = try consume(type: .For, message: "Expected `for` as begin of for loop, but got \(peek().lexeme) instead.")
        skip(all: .NLine)

        if peek2().type == .In {
            return try parseForEach(token: token)
        } else {
            return try parseForC(token: token)
        }
    }

    /// Parses loops like `for i in range(5) {}`
    ///
    /// Does currently not support unpackaging like `for (a,b) in [(1,2)] {}`
    func parseForEach(token: Token) throws -> ForEachStatement {
        let variable = try parseIdentifier()
        _ = try consume(type: .In, message: "Expected `in` after variable in for each loop, but got \(peek().lexeme) instead.")
        let list = try parseExpression(.Lowest)
        skip(all: .NLine)
        let body = try parseBlockStatement()
        return ForEachStatement(token: token, variable: variable, list: list, body: body)
    }

    func parseForC(token: Token) throws -> ForCStyleStatement {
        var preStmt: Statement?

        let directSemiColon = match(types: .SemiColon) // like `for ;true;a++ {}`
        if !directSemiColon {
            preStmt = try parseStatement()
        }
        skip(all: .NLine)

        // case cond {... so it has to be expressionStatment
        // so we know it is a single condition loop
        if let preStmt = preStmt, check(type: .LBrace) {
            guard let preStmt = preStmt as? ExpressionStatement else {
                throw error(message: "For loops with single condition have to define condition. `\(preStmt)` is not a condition.", node: preStmt)
            }

            let body = try parseBlockStatement()
            return ForCStyleStatement(token: token, preStmt: nil, condition: preStmt.expression, postEachSmt: nil, body: body)
        }
        skip(all: .NLine)

        let condition = try parseExpression(.Lowest)
        _ = try consume(type: .SemiColon, message: "For C-Style loops `;` is required after the condition as seperator to the post statement.\nTip: If no post statement is needed, use this pattern: `for stmt; condition; {...}`")

        skip(all: .NLine)
        var postStmt: Statement?
        if !check(type: .LBrace) {
            postStmt = try parseStatement()
        }
        skip(all: .NLine)

        let body = try parseBlockStatement()
        return ForCStyleStatement(token: token, preStmt: preStmt, condition: condition, postEachSmt: postStmt, body: body)
    }
}
