//
// Created by Johannes Zottele on 19.05.22.
//

import Foundation
@testable import Moose

@resultBuilder
struct TokenBuilder {
    static func buildBlock() -> [Token] { [] }
}
extension TokenBuilder {
    static func buildBlock(_ defs:  (type: TokenType, lexeme: String)...) -> [Token] {
        return defs.map { type, lexeme -> Token in
            Token(type: type, lexeme: lexeme, literal: nil, line: 0, column: 0)
        }
    }
}
func buildTokenList(@TokenBuilder _ tokens: () -> [Token]) -> [Token] {
    return tokens()
}
