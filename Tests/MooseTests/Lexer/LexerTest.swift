//
// Created by Johannes Zottele on 19.05.22.
//

import XCTest
@testable import Moose

class LexerTest: XCTestCase {

    private var testNumber: Int!
    private var input: String!
    private var expectedTokens: [Token]!

    // MARK: Test Methods

    /// Tests if lexer gives expected tokens back
    func testNextToken() throws {
        let lexer = Lexer(input: input)
        for (i, tt) in expectedTokens.enumerated() {
            let tok = try lexer.nextToken()
            XCTAssertEqual(tt.type, tok.type,
                    "Test[\(testNumber!):\(i)] - TokenType wrong. expected=\(tt.type), got=\(tok.type)")
            XCTAssertEqual(tt.lexeme, tok.lexeme,
                    "Test[\(testNumber!):\(i)] - lexeme wrong. expected=\(tt.lexeme), got=\(tok.lexeme)")
        }
    }


    // MARK: Dynamic Test Creation

    override open class var defaultTestSuite: XCTestSuite {
        let testSuite = XCTestSuite(name: NSStringFromClass(self))

        let input = """
                    mut albert = 2

                    """
        let tokenList = buildTokenList {
            (TokenType.Mut, "mut")
            (TokenType.Identifier, "albert")
            (TokenType.Assign, "=")
            (TokenType.Int, "2")
            (TokenType.NLine, "\n")
            (TokenType.EOF, " ")
        }
        addTest(input, tokenList, 0, toTestSuite: testSuite)


//        let input2 = """
//                    $test
//                    """
//        let tokenList2 = buildTokenList{
//            (TokenType.Illegal, "$ is not a valid token")
//        }
//        addTest(input2, tokenList2, 1, toTestSuite: testSuite)


        return testSuite
    }
    private class func addTest(_ input: String, _ expectedTokens: [Token], _ testNumber: Int,toTestSuite testSuite: XCTestSuite) {
        testInvocations.forEach { invocation in
            let testCase = LexerTest(invocation: invocation)
            testCase.input = input
            testCase.expectedTokens = expectedTokens
            testCase.testNumber = testNumber
            testSuite.addTest(testCase)
        }
    }


}