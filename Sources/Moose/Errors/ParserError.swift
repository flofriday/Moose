//
// Created by Johannes Zottele on 16.06.22.
//

enum ParseError: Error {
    typealias Line = Int
    typealias Column = Int

    case parseError(msg: String, Line, Column)
    case tokenTypeError(msg: String, expected: TokenType, received: TokenType, Line, Column)
    case noParseFn(msg: String, type: TokenType, Line, Column)
    case literalTypeError(msg: String, expected: String, received: String, Line, Column)
}
