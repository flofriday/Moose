//
// Created by Johannes Zottele on 19.05.22.
//

import Foundation

class Lexer {
    private var input: String
    private var position: Int = 0
    private var readPosition: Int = 0
    private var char: Character?
    private var line: Int = 1

    init(input: String) {
        self.input = input
        readChar()
    }
}

extension Lexer {
    func nextToken() throws -> Token {
        var tok: Token?
        skipWhitespace()
        tok = Token(type: .Identifier, lexeme: "Hello", literal: "String", line: 0, column: 0)
        readChar()
        return tok!
    }
}

extension Lexer {
    private func isLetter(char: Character) -> Bool {
        return "a" <= char && char <= "z" || "A" <= char && char <= "Z" || char == "_"
    }
    private func isDigit(char: Character) -> Bool {
        return "0" <= char && char <= "9"
    }
}

extension Lexer {
    private func readChar() -> Void {
        if readPosition > input.count {
            char = nil
        } else {
            char = input[readPosition]
        }
        position = readPosition
        readPosition += 1
    }
    private func skipWhitespace(withN: Bool = false) {
        var toSkip: [Character] = [" ", "\t", "\r"]
        if withN { toSkip.append("\n") }
        guard let char = char else {
            return
        }
        while toSkip.contains(char) {
            readChar()
        }
    }
    private func peekChar() -> Character? {
        guard readPosition < input.count else {
            return nil
        }
        return input[readPosition]
    }
}