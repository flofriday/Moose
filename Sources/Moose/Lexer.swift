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
    private var errors: [CompileErrorMessage] = []

    init(input: String) {
        self.input = input
        readChar() // TODO: WHY this line?
    }
}

extension Lexer {
    func scan() throws -> [Token] {
        var tokens: [Token] = []
        while true {
            do {
                let token = try nextToken()
                tokens.append(token)
                if case .EOF = token.type {
                    break
                }
            } catch let e as CompileErrorMessage {
                errors.append(e)
            }
        }
        return tokens
    }

    func nextToken() throws -> Token {
        var tok: Token?
        skipWhitespace()
        while skipComment() {}

        switch (char, peekChar()) {
        case ("\n", _):
            readChar()
            tok = genToken(.NLine)
        case let ("=", peek) where !isOpChar(char: peek):
            readChar()
            tok = genToken(.Assign)
        case (";", _):
            readChar()
            tok = genToken(.SemiColon)
        case let (":", peek) where !isOpChar(char: peek):
            readChar()
            tok = genToken(.Colon)
        case ("(", _):
            readChar()
            tok = genToken(.LParen)
        case (")", _):
            readChar()
            tok = genToken(.RParen)
        case (",", _):
            readChar()
            tok = genToken(.Comma)
        case ("{", _):
            readChar()
            tok = genToken(.LBrace)
        case ("}", _):
            readChar()
            tok = genToken(.RBrace)
        case ("[", _):
            readChar()
            tok = genToken(.LBracket)
        case ("]", _):
            readChar()
            tok = genToken(.RBracket)
        case (".", _):
            readChar()
            tok = genToken(.Dot)
        case let ("?", peek) where !isOpChar(char: peek):
            readChar()
            tok = genToken(.QuestionMark)
        case ("?", "?"):
            readChar()
            readChar()
            tok = genToken(.DoubleQuestionMark, "??")
        default:
            guard let unwrappedChar = char else {
                return genToken(.EOF)
            }

            if isOpChar(char: unwrappedChar) {
                let preChar = readChar(at: position - 1)
                let op = read(isOpChar)
                let postChar = readChar(at: position)
                if let l = op.last, l == ":" {
                    let type = determineOperator(prevChar: preChar, postChar: postChar, assign: true)
                    return genToken(type, String(op.dropLast()))
                } else {
                    let type = determineOperator(prevChar: preChar, postChar: postChar, assign: false)
                    return genToken(type, op)
                }
                // lex string
            } else if unwrappedChar == "\"" {
                let (lexeme, literal) = try readString()
                return genToken(.String, literal, lexeme)
            } else if isLetter(char: unwrappedChar) {
                let ident = readIdentifier()
                let type = lookUpIdent(ident: ident)
                var lit: Any = ident
                if case let .Boolean(val) = type {
                    lit = val
                }
                return genToken(type, lit, ident)
            } else if isDigit(char: unwrappedChar) {
                var digit = readNumber()

                if char == Character("."), peekChar()?.isNumber ?? false {
                    readChar()
                    digit += "."
                    digit += readNumber()

                    if let num = Float64(digit) {
                        return genToken(.Float, num, digit)
                    } else {
                        throw error(message: "I thought I was reading a number, but \(digit) is not a float number")
                    }
                }

                if let num = Int64(digit) {
                    return genToken(.Int, num, digit)
                } else {
                    throw error(message: "I thought I was reading a number, but \(digit) is not an integer number")
                }

            } else {
                throw error(message: "I got confused while reading your code, \(unwrappedChar) is not a valid token")
            }
        }

        return tok!
    }
}

extension Lexer {
    private func readIdentifier() -> String {
        let pos = position
        while let char = char, isLetter(char: char) || isDigit(char: char) {
            readChar()
        }
        return input[pos ..< position]
    }

    private func readNumber() -> String {
        let pos = position
        while let char = char, isDigit(char: char) {
            readChar()
        }
        return input[pos ..< position]
    }

    private func read(_ evaluator: (Character) -> Bool) -> String {
        let pos = position
        while let char = char, char.isASCII, evaluator(char) {
            readChar()
        }
        return input[pos ..< position]
    }

    private func readString() throws -> (lexem: String, literal: String) {
        var str = ""
        let pos = position
        readChar()
        while let chr = char, chr != "\"" {
            if chr == "\\" {
                readChar()
                guard let chr = char else { continue }
                str += escapeString(char: chr)
                readChar()
                continue
            }
            str += String(chr)
            readChar()
        }

        guard char == "\"" else { throw error(message: "String does not end with an closint \".") }
        readChar()
        return (input[pos ..< position], str)
    }

    private func escapeString(char: Character) -> String {
        switch char {
        case "\\":
            return "\\"
        case "0":
            return "\0"
        case "t":
            return "\t"
        case "n":
            return "\n"
        case "r":
            return "\r"
        case "\"":
            return "\""
        default:
            return "\\\(char)"
        }
    }
}

extension Lexer {
    private func isLetter(char: Character) -> Bool {
        return char >= "a" && char <= "z" || char >= "A" && char <= "Z" || char == "_"
    }

    private func isDigit(char: Character) -> Bool {
        return char >= "0" && char <= "9"
    }

    private func isOpChar(char: Character?) -> Bool {
        guard let char = char else {
            return false
        }
        return "!^#$@%*/?&+-–><=:~|".contains(char)
    }
}

extension Lexer {
    private func readChar(at pos: Int) -> Character? {
        guard pos >= 0, pos < input.count else {
            return nil
        }
        return input[pos]
    }

    private func readChar() {
        if readPosition >= input.count {
            char = nil
        } else {
            char = input[readPosition]

            if readPosition > 0, input[readPosition - 1].isNewline {
                line += 1
                column = 0
            }
        }
        position = readPosition
        column += 1
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

    private func skipComment() -> Bool {
        guard let char = char, char == "/", peekChar() == "/" else {
            return false
        }
        skipUntil(ch: "\n", inclusively: false)
        return true
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
        let lastChar = input[readPosition - 2]
        return genToken(type, nil, "\(lastChar)")
    }

    /// genToken with lexeme and literal nil
    private func genToken(_ type: TokenType, _ lexeme: String) -> Token {
        genToken(type, nil, lexeme)
    }

    /// Generate the specified token.
    /// Note: When calling this function the last character of the token should
    /// already be consumed and the column pointer should point to the next
    /// column.
    private func genToken(_ type: TokenType, _ lit: Any?, _ lexeme: String) -> Token {
        var lexeme = lexeme

        // TODO: This is wrong for newlines
        var startCol = column - lexeme.count

        // String literals need to be adjusted for two qutationmarks
        if type == .String {
            startCol -= 2
        } else if type == .EOF {
            lexeme = " "
        }

        let t = Token(type: type, lexeme: lexeme, literal: lit, line: line, column: startCol)
        return t
    }
}

extension Lexer {
    func peekToken() throws -> Token? {
        let pos_backup = position
        let read_pos_backup = readPosition
        let char = self.char
        let line = self.line
        let column = self.column

        let token = try nextToken()

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
        let prevWhite = prevChar == nil ? true : prevChar!.isWhitespace || [";", "(", "{", "[", ","].contains(prevChar!)
        let postWhite = postChar == nil ? true : postChar!.isWhitespace || [";", ")", "}", "]", ","].contains(postChar!)
        if (prevWhite && postWhite) || (!prevWhite && !postWhite) { // such as "a+b" "a + b"
            return TokenType.Operator(pos: .Infix, assign: assign)
        } else if prevWhite, !postWhite { // such as "+a"
            return TokenType.Operator(pos: .Prefix, assign: assign)
        } else { // !prevWhite && postWhite, such as "a+"
            return TokenType.Operator(pos: .Postfix, assign: assign)
        }
    }
}

extension Lexer {
    func error(message: String) -> CompileErrorMessage {
        let location = Location(col: column, endCol: column, line: line, endLine: line)
        return CompileErrorMessage(location: location, message: message)
    }
}
