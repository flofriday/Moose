//
// Created by Johannes Zottele on 19.05.22.
//

import XCTest
import Foundation

class LexerTest: XCTestCase {

    private var input: String?
    private var expectedTokens: [String]?

    // MARK: Test Methods

    /// Tests if lexer gives expected tokens back
    func testNextToken() {
        let actualTokens = input!.split(separator: ",")
        XCTAssertEqual(expectedTokens!.count, actualTokens.count)
        for (index, item) in actualTokens.enumerated() {
            XCTAssertEqual(expectedTokens![index], String(item))
        }
    }


    // MARK: Dynamic Test Creation

    override open class var defaultTestSuite: XCTestSuite {
        let testSuite = XCTestSuite(name: NSStringFromClass(self))

        addTest("", [], toTestSuite: testSuite)
        addTest("Brian", ["Brian"], toTestSuite: testSuite)
        addTest("Brian,Coyner", ["Brian", "Coyner"], toTestSuite: testSuite)
        addTest("Brian,Coyner,Was", ["Brian", "Coyner", "Was"], toTestSuite: testSuite)
        addTest("Brian,Coyner,Was,Here", ["Brian", "Coyner", "Was", "Here"], toTestSuite: testSuite)
        return testSuite
    }
    private class func addTest(_ input: String, _ expectedTokens: [String], toTestSuite testSuite: XCTestSuite) {
        testInvocations.forEach { invocation in
            let testCase = LexerTest(invocation: invocation)
            testCase.input = input
            testCase.expectedTokens = expectedTokens
            testSuite.addTest(testCase)
        }
    }


}