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
    private var column: Int = 0

    init(input: String) {
        self.input = input
        readChar()
    }
}

extension Lexer {
    func nextToken() -> Token {
        var tok: Token?
        skipWhitespace()
        column = position

        switch char {
        case "\n":
            line += 1
            tok = genToken(.NLine)
        case "=":
            if let t = genPeekToken(type: .Eq, ch: "=") {
                tok = t
            } else {
                tok = genToken(.Assign)
            }
        case ";":
            tok = genToken(.SemiColon)
        case ":":
            tok = genToken(.Colon)
        case "(":
            tok = genToken(.LParen)
        case ")":
            tok = genToken(.RParen)
        case ",":
            tok = genToken(.Comma)
        case "+":
            tok = genToken(.Plus)
        case "-":
            tok = genToken(.Minus)
        case "!":
            if let t = genPeekToken(type: .NotEq, ch: "=") {
                tok = t
            } else {
                tok = genToken(.Bang)
            }
        case "/":
            tok = genToken(.Slash)
        case "*":
            tok = genToken(.Asterik)
        case "<":
            if let t = genPeekToken(type: .LTE, ch: "=") {
                tok = t
            } else {
                tok = genToken(.LT)
            }
        case ">":
            if let t = genPeekToken(type: .GTE, ch: "=") {
                tok = t
            } else {
                tok = genToken(.GT)
            }
        case "{":
            tok = genToken(.LBrace)
        case "}":
            tok = genToken(.RBrace)
        case "[":
            tok = genToken(.LBracket)
        case "]":
            tok = genToken(.RBracket)
        case nil:
            tok = genToken(.EOF)
        default:
            let char = char!
            if isLetter(char: char) {
                let ident = readIdentifier()
                let type = lookUpIdent(ident: ident)
                return genToken(type, ident, ident)
            } else if isDigit(char: char) {
                let digit = readNumber()
                if let num = Int(digit) {
                    return genToken(.Int, num, digit)
                } else {
                    return genToken(.Illegal, nil, "\(digit) is not an integer number")
                }

            } else {
                tok = genToken(.Illegal, nil, "\(char) is not a valid token")
            }
        }

        readChar()
        return tok!
    }
}

extension Lexer {
    private func readIdentifier() -> String {
        let pos = position
        while let char = char, isLetter(char: char) {
            readChar()
        }
        return input[pos..<position]
    }

    private func readNumber() -> String {
        let pos = position
        while let char = char, isDigit(char: char) {
            readChar()
        }
        return input[pos..<position]
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
        if readPosition >= input.count {
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
        while let char = char, toSkip.contains(char) {
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

extension Lexer {
    private func genPeekToken(type: TokenType, ch: Character) -> Token?{
        guard ch == peekChar() else {
            return nil
        }
        let tmp = self.char
        readChar()
        return genToken(.NotEq, "\(tmp ?? " ")\(char ?? " ")")
    }

    private func genToken(_ type: TokenType) -> Token {
        genToken(type, nil, "\(char ?? " ")")
    }
    private func genToken(_ type: TokenType, _ lexeme: String) -> Token {
        genToken(type, nil, lexeme)
    }
    private func genToken(_ type: TokenType, _ lit: Any?, _ lexeme: String) -> Token {
        Token(type: type, lexeme: lexeme, literal: lit, line: line, column: column)
    }
}