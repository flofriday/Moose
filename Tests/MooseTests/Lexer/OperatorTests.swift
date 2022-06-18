//
// Created by Johannes Zottele on 30.05.22.
//

import XCTest
@testable  import Moose

class OperatorTests: XCTestCase {


    func test_AssignOperatorvsOperator() throws {
        let input = "$#@;$#@:"
        let ts = buildTokenList {
            (TokenType.Operator, "$#@")
            (TokenType.SemiColon, ";")
            (TokenType.AssignOperator, "$#@")
            (TokenType.EOF, " ")
        }
        try testNextToken(input, ts)
    }

    func test_standardOperators() throws {
        let input = """
                    +=
                    <=
                    >=
                    +:
                    &&
                    ||
                    4++++asd
                    ::
                    =*
                    =a
                    """
        let ts = buildTokenList {
            (TokenType.Operator, "+=")
            (TokenType.NLine, "\n")
            (TokenType.Operator, "<=")
            (TokenType.NLine, "\n")
            (TokenType.Operator, ">=")
            (TokenType.NLine, "\n")
            (TokenType.AssignOperator, "+")
            (TokenType.NLine, "\n")
            (TokenType.Operator, "&&")
            (TokenType.NLine, "\n")
            (TokenType.Operator, "||")
            (TokenType.NLine, "\n")
            (TokenType.Int, "4")
            (TokenType.Operator, "++++")
            (TokenType.Identifier, "asd")
            (TokenType.NLine, "\n")
            (TokenType.AssignOperator, ":")
            (TokenType.NLine, "\n")
            (TokenType.Operator, "=*")
            (TokenType.NLine, "\n")
            (TokenType.Assign, "=")
            (TokenType.Identifier, "a")
            (TokenType.EOF, " ")
        }

        try testNextToken(input, ts)
    }

    func testPeekToken() throws {
        let l = Lexer(input: "a = b")
        let _ = l.nextToken()
        let tt = Token(type: .Assign, lexeme: "=", literal: nil, line: 0, column: 0)
        let tok = l.peekToken()

        try assertEqualToken(tt, tok)
        try assertEqualToken(tt, l.nextToken())
    }

    func testComment() throws {
        let i = """
                let a //= das ist schön $@ : ;
                +=
                    //       
                """
        let ts = buildTokenList {
            (TokenType.Identifier, "let")
            (TokenType.Identifier, "a")
            (TokenType.Operator, "+=")
            (TokenType.NLine, "\n")
            (TokenType.EOF, " ")
        }

        try testNextToken(i, ts)
    }

    func testStrings() throws {
        let i = """
                mut a = "this is a String"
                "this // as well"
                "let b = this as well"
                "with new line
                lol"
                "invalid
                """
        let ts = buildTokenList {
            (TokenType.Mut, "mut")
            (TokenType.Identifier, "a")
            (TokenType.Assign, "=")
            (TokenType.String, "this is a String")
            (TokenType.NLine, "\n")
            (TokenType.String, "this // as well")
            (TokenType.NLine, "\n")
            (TokenType.String, "let b = this as well")
            (TokenType.NLine, "\n")
            (TokenType.String, "with new line\nlol")
            (TokenType.NLine, "\n")
            (TokenType.Illegal, "String does not end with an closing \".")
        }

        try testNextToken(i, ts)
    }

    func testOperators() throws  {
        let i = """
                -1+ + +2
                infix +- ()
                a+:b
                """
        let ts = buildTokenList {
            (TokenType.PrefixOperator, "-")
            (TokenType.Int, "1")
            (TokenType.PostfixOperator, "+")
            (TokenType.Operator, "+")
            (TokenType.PrefixOperator, "+")
            (TokenType.Int, "2")
            (TokenType.NLine, "\n")
            (TokenType.Infix, "infix")
            (TokenType.Operator, "+-")
            (TokenType.LParen, "(")
            (TokenType.RParen, ")")
            (TokenType.NLine, "\n")
            (TokenType.Identifier, "a")
            (TokenType.AssignOperator, "+")
            (TokenType.Identifier, "b")
        }

        try testNextToken(i, ts)
    }

    /// Tests if lexer gives expected tokens back
    private func testNextToken(_ input: String, _ expectedTokens: [Token]) throws {
        let lexer = Lexer(input: input)
        for (i, tt) in expectedTokens.enumerated() {
            let tok = lexer.nextToken()
            XCTAssertEqual(tt.type, tok.type,
                    "[:\(i)] - TokenType wrong. expected=\(tt.type), got=\(tok.type)")
            XCTAssertEqual(tt.lexeme, tok.lexeme,
                    "[:\(i)] - lexeme wrong. expected=\(tt.lexeme), got=\(tok.lexeme)")
        }
    }

    private func assertEqualToken(_ tt: Token, _ tok: Token?) throws {
        XCTAssertEqual(tt.type, tok!.type,
                "TokenType wrong. expected=\(tt.type), got=\(tok!.type)")
        XCTAssertEqual(tt.lexeme, tok!.lexeme,
                "lexeme wrong. expected=\(tt.lexeme), got=\(tok!.lexeme)")
    }
}