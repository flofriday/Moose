//
// Created by Johannes Zottele on 17.06.22.
//

import Foundation
@testable import Moose
import XCTest

class BasicTests: BaseClass {
    /// - Todo: Fix test! test are not processed
    func test_assignStatements() throws {
        let inputs: [(String, String, Any, Bool)] = [
            ("a = 3", "a", Int64(3), false),
            ("mut b = 1", "b", Int64(1), true),
            ("a = ident", "a", "ident", false),
            ("mut b = ident", "b", "ident", true),
            ("var = true", "var", true, false),
            ("mut var = false", "var", false, true)
        ]

        for i in inputs {
            let l = Lexer(input: i.0)
            let p = Parser(l)
            let prog = p.parseProgram()
            XCTAssertTrue(p.errors.isEmpty)
            XCTAssertEqual(prog.statements.count, 1)
            let a = test_assignStatement(stmt: prog.statements[0], name: i.1, mut: i.3)
            XCTAssert(a.0, a.1)

            let stmt = prog.statements[0] as! AssignStatement
            try test_literalExpression(exp: stmt.value, expected: i.2)
        }
    }
}
