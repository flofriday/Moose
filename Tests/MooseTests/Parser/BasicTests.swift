//
// Created by Johannes Zottele on 17.06.22.
//

import Foundation
import XCTest
@testable import Moose

class BasicTests: XCTest {

    /// - Todo: Fix test! test are not processed
    func test_assignStatements() throws {
        XCTAssertTrue(false)
        let inputs = [
            ("a = 3", "a", "3", false),
            ("mut b = 1", "b", "1", true)
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
            XCTAssertEqual(stmt.value.tokenLexeme, i.2)
        }
    }
}

extension BasicTests {
    func test_assignStatement(stmt: Statement, name: String, mut: Bool) -> (Bool, String) {
        guard stmt.tokenLexeme == "mut" || stmt.tokenLexeme == name else {
            return (false, "TokenLiteral is neither 'mut' nor '\(name)'. got=\(stmt.tokenLexeme)")
        }
        guard let stmt = stmt as? AssignStatement else {
            return (false, "Statement is not of type AssignStatement. got=\(String(describing: type(of: stmt)))")
        }
        guard name == stmt.name.value else {
            return (false, "stmt.name.value not '\(name)'. got='\(stmt.name)'")
        }
        guard name == stmt.name.tokenLexeme else {
            return (false, "stmt.name.tokenLexeme not '\(name)'. got='\(stmt.name.tokenLexeme)'")
        }
        guard mut == stmt.mutable else {
            return (false, "stmt.mutable is not \(mut)")
        }
        return (true, "")
    }
}