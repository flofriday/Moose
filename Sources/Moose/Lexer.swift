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
    func scan() -> [Token] {
        var tokens: [Token] = []
        while true {
            var token = nextToken()
            tokens.append(token)
            if token.type == .EOF {
                break
            }
        }
        return tokens
    }

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
            guard let unwrappedChar = char else {
                return genToken(.EOF)
            }

            if isOpChar(char: unwrappedChar) {
                let preChar = readChar(at: position-1)
                let op = read(isOpChar)
                let postChar = readChar(at: position)
                if let l = op.last, l == ":" {
                    let type = determineOperator(prevChar: preChar, postChar: postChar, assign: true)
                    return genToken(type, String(op.dropLast()))
                } else {
                    let type = determineOperator(prevChar: preChar, postChar: postChar, assign: false)
                    return genToken(type, op)
                }
            } else if unwrappedChar == "\"" {
                readChar() // skip start "
                let string = read({ $0 != "\"" })
                // if current char is not ending ", return invalid token
                guard let char = char, char == "\"" else {
                    return genToken(.Illegal, string, "String does not end with an closing \".")
                }
                readChar() // skip ending "
                return genToken(.String, string, string)
            } else if isLetter(char: unwrappedChar) {
                let ident = readIdentifier()
                let type = lookUpIdent(ident: ident)
                return genToken(type, ident, ident)
            } else if isDigit(char: unwrappedChar) {
                let digit = readNumber()
                if let num = Int64(digit) {
                    return genToken(.Int, num, digit)
                } else {
                    return genToken(.Illegal, nil, "\(digit) is not an integer number")
                }

            } else {
                tok = genToken(.Illegal, nil, "\(unwrappedChar) is not a valid token")
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

    private func read(_ evaluator: (Character?) -> Bool) -> String {
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
    private func readChar(at pos: Int) -> Character? {
        guard pos >= 0, pos < input.count else {
            return nil
        }
        return input[pos]
    }

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

extension Lexer {
    /// determine if operator is prefix, infix, or postfix depending on characters before and after operator
    func determineOperator(prevChar: Character?, postChar: Character?, assign: Bool) -> TokenType {
        let prevWhite = prevChar == nil ? true : prevChar!.isWhitespace || prevChar! == ";"
        let postWhite = postChar == nil ? true : postChar!.isWhitespace || postChar! == ";"
        if (prevWhite && postWhite) || (!prevWhite && !postWhite) { // such as "a+b" "a + b"
            return assign ? TokenType.AssignOperator : TokenType.Operator
        } else if prevWhite && !postWhite { // such as "+a"
            return assign ? TokenType.PrefixAssignOperator : TokenType.PrefixOperator
        } else  { // !prevWhite && postWhite, such as "a+"
            return assign ? TokenType.PostfixAssignOperator : TokenType.PostfixOperator
        }
    }
}
