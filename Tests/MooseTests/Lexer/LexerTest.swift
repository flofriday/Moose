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
            let tok = lexer.nextToken()
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
                    mut a = 2
                    """
        let tokenList = buildTokenList {
            (TokenType.Identifier, "a")
        }
        addTest(input, tokenList, 0, toTestSuite: testSuite)

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