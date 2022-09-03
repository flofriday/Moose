//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation

extension Parser {
    func parseList() throws -> Expression {
        let token = try consume(type: .LBracket, message: "`[` expected as start of List, but got `\(peek().lexeme)` instead.")

        let exprs = try parseExpressionList(seperator: .Comma, end: .RBracket)
        let rbracket = try consume(type: .RBracket, message: "Expected `]` as end of List, but got `\(peek().lexeme)` instead.")

        let location = mergeLocations(token, rbracket)
        return List(token: token, location: location, expressions: exprs)
    }

    func parseIndex(left: Expression) throws -> Expression {
        let token = try consume(type: .LBracket, message: "`[` expected as start of index access, but got `\(peek().lexeme)` instead.")

        let index = try parseExpression(.Lowest)
        let rbracket = try consume(type: .RBracket, message: "Expected `]` as end of index access, but got `\(peek().lexeme)` instead.")

        let location = mergeLocations(token, rbracket)
        return IndexExpression(token: token, location: location, indexable: left, index: index)
    }
}
