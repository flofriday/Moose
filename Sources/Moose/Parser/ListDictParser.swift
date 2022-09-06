//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation

extension Parser {
    func parseList() throws -> List {
        let token = try consume(type: .LBracket, message: "`[` expected as start of List, but got `\(peek().lexeme)` instead.")

        let exprs = try parseExpressionList(seperator: .Comma, end: .RBracket)
        _ = try consume(type: .RBracket, message: "Expected `]` as end of List, but got `\(peek().lexeme)` instead.")

        return List(token: token, expressions: exprs)
    }

    func parseDictInit() throws -> Dict {
        let token = try consume(type: .LBrace, message: "`{` expected as start of dict.")
        let pairs = try parseDictPairs(end: .RBrace)
        _ = try consume(type: .RBrace, message: "`}` as end of dict expected, but got `\(peek().lexeme)` instead.")
        return Dict(token: token, pairs: pairs)
    }

    func parseIndex(left: Expression) throws -> Expression {
        let token = try consume(type: .LBracket, message: "`[` expected as start of index access, but got `\(peek().lexeme)` instead.")

        let index = try parseExpression(.Lowest)

        _ = try consume(type: .RBracket, message: "Expected `]` as end of index access, but got `\(peek().lexeme)` instead.")
        return IndexExpression(token: token, indexable: left, index: index)
    }

    private func parseDictPairs(end: TokenType) throws -> [(Expression, Expression)] {
        var pairs = [(Expression, Expression)]()
        skip(all: .NLine)
        while !check(type: end) {
            let key = try parseExpression(.Lowest)
            _ = try consume(type: .Colon, message: "Expected `:` between key and value.")
            let value = try parseExpression(.Lowest)
            skip(all: .NLine)
            if !match(types: .Comma) {
                guard check(type: end) else {
                    throw error(message: "Expected `,` or end of dict, but got \(peek().lexeme) instead.", token: peek())
                }
            }
            skip(all: .NLine)
            pairs.append((key, value))
        }
        return pairs
    }
}
