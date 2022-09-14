//
// Created by Johannes Zottele on 19.05.22.
//

import Foundation
@testable import Moose

@resultBuilder
enum TokenBuilder {
    static func buildBlock() -> [Token] { [] }
}

extension TokenBuilder {
    static func buildBlock(_ defs: (type: TokenType, lexeme: String)...) -> [Token] {
        return defs.map { type, lexeme -> Token in
            Token(type: type, lexeme: lexeme, literal: nil, location: Location(col: 1, endCol: 1, line: 1, endLine: 1))
        }
    }
}

func buildTokenList(@TokenBuilder _ tokens: () -> [Token]) -> [Token] {
    return tokens()
}
