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
        skipComment()
        column = position

        switch (char, peekChar()) {
        case ("\n", _):
            line += 1
            tok = genToken(.NLine)
        case ("=", let peek) where !isOpChar(char: peek):
            tok = genToken(.Assign)
        case (";", _):
            tok = genToken(.SemiColon)
        case (":", let peek) where !isOpChar(char: peek):
            tok = genToken(.Colon)
        case ("<", let peek) where !isOpChar(char: peek):
            tok = genToken(.InheritsFrom)
        case (">", let peek) where !isOpChar(char: peek):
            tok = genToken(.ToType)
        case ("(", _):
            tok = genToken(.LParen)
        case (")", _):
            tok = genToken(.RParen)
        case (",", _):
            tok = genToken(.Comma)
        case ("{", _):
            tok = genToken(.LBrace)
        case ("}", _):
            tok = genToken(.RBrace)
        case ("[", _):
            tok = genToken(.LBracket)
        case ("]", _):
            tok = genToken(.RBracket)
        default:
            guard let char = char else { return genToken(.EOF)}

            if isOpChar(char: char) {
                let op = readString(isOpChar)
                if let l = op.last, l == ":" {
                    return genToken(.AssignOperator, String(op.dropLast()))
                } else {
                    return genToken(.Operator, op)
                }
            } else if isLetter(char: char) {
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

    private func readString(_ evaluator: (Character?) -> Bool) -> String {
        let pos = position
        while let char = char, evaluator(char) {
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

    private func isOpChar(char: Character?) -> Bool {
        guard let char = char else {
            return false
        }
        return "!#$@%*/?&+-–><=:~|".contains(char)
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
        if withN {
            toSkip.append("\n")
        }
        while let char = char, toSkip.contains(char) {
            readChar()
        }
    }

    /// skipChars until we receive char. If with = true, skip char to
    private func skipUntil(ch: Character, inclusively: Bool = true) {
        while let char = char, char != ch {
            readChar()
        }
        if char != nil, inclusively {
            readChar()
        }
    }
    private func skipComment() {
        guard let char = char, char == "/", peekChar() == "/" else {
            return
        }
        skipUntil(ch: "\n")
    }

    private func peekChar() -> Character? {
        guard readPosition < input.count else {
            return nil
        }
        return input[readPosition]
    }
}

extension Lexer {

    /// genToken with lexeme " "
    private func genToken(_ type: TokenType) -> Token {
        genToken(type, nil, "\(char ?? " ")")
    }

    /// genToken with lexeme and literal nil
    private func genToken(_ type: TokenType, _ lexeme: String) -> Token {
        genToken(type, nil, lexeme)
    }

    private func genToken(_ type: TokenType, _ lit: Any?, _ lexeme: String) -> Token {
        Token(type: type, lexeme: lexeme, literal: lit, line: line, column: column)
    }
}

extension Lexer {
    func peekToken() -> Token? {
        let pos_backup = position
        let read_pos_backup = readPosition
        let char = self.char
        let line = self.line
        let column = self.column

        let token = nextToken()

        position = pos_backup
        readPosition = read_pos_backup
        self.char = char
        self.line = line
        self.column = column
        return token
    }
}