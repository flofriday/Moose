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
        let rbracket = try consume(type: .RBracket, message: "Expected `]` as end of List, but got `\(peek().lexeme)` instead.")

        let location = mergeLocations(token, rbracket)
        return List(token: token, location: location, expressions: exprs)
    }

    func parseDictInit() throws -> Dict {
        let token = try consume(type: .LBrace, message: "`{` expected as start of dict.")
        let pairs = try parseDictPairs(end: .RBrace)
        let rbrace = try consume(type: .RBrace, message: "`}` as end of dict expected, but got `\(peek().lexeme)` instead.")

        let location = mergeLocations(token, rbrace)
        return Dict(token: token, location: location, pairs: pairs)
    }

    func parseIndex(left: Expression) throws -> Expression {
        let token = try consume(type: .LBracket, message: "`[` expected as start of index access, but got `\(peek().lexeme)` instead.")

        let index = try parseExpression(.Lowest)

        let rbracket = try consume(type: .RBracket, message: "Expected `]` as end of index access, but got `\(peek().lexeme)` instead.")

        let location = mergeLocations(left.location, locationFromToken(rbracket))
        return IndexExpression(token: token, location: location, indexable: left, index: index)
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
