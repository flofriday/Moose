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
        _ = try consume(type: .RBracket, message: "Expected `]` as end of List, but got `\(peek().lexeme)` instead.")

        return List(token: token, expressions: exprs)
    }

    func parseIndex(left: Expression) throws -> Expression {
        let token = try consume(type: .LBracket, message: "`[` expected as start of index access, but got `\(peek().lexeme)` instead.")

        let index = try parseExpression(.Lowest)

        _ = try consume(type: .RBracket, message: "Expected `]` as end of index access, but got `\(peek().lexeme)` instead.")
        return IndexExpression(token: token, indexable: left, index: index)
    }
}
