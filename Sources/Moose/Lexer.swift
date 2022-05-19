//
// Created by Johannes Zottele on 19.05.22.
//

import Foundation

class Lexer {
    private var input: String
    private var position: Int = 0
    private var readPosition: Int = 0
    private var char: Character?

    init(input: String) {
        self.input = input
        readChar()
    }
}

extension Lexer {
    func nextToken() -> Token {
        return Token(type: .Identifier, lexeme: "hello", literal: nil, line: 0, column: 0)
    }
}

extension Lexer {
    private func readChar() -> Void {}
}