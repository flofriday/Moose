//
// Created by Johannes Zottele on 17.06.22.
//

import Foundation
@testable import Moose
import XCTest

class BasicTests: BaseClass {
    /// - Todo: Fix test! test are not processed
    func test_assignStatements() throws {
        print("-- Test assign statements")

        let inputs: [(String, String, Any, Bool)] = [
            ("a = 3", "a", Int64(3), false),
            ("mut b = 1", "b", Int64(1), true),
            ("a = ident;", "a", "ident", false),
            ("mut b = ident", "b", "ident", true),
            ("var = true", "var", true, false),
            ("mut var = false\n", "var", false, true)
        ]

        for (index, i) in inputs.enumerated() {
            print("Start test \(index): \(i)")
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

    func test_returnStatements() throws {
        print("-- Test return statements")
        let tests: [(String, Any)] = [
            ("return 5;", Int64(5)),
            ("return true", true),
            ("return x", "x"),
            ("return x\n", "x"),
            ("return x;", "x")
        ]

        for (i, t) in tests.enumerated() {
            print("Start test \(i): \(t)")

            let l = Lexer(input: t.0)
            let p = Parser(l)
            let prog = p.parseProgram()
            XCTAssertEqual(p.errors.count, 0, "Got parse errors: \n- \(p.errors.map { String(describing: $0) }.joined(separator: "\n- "))")
            XCTAssertEqual(prog.statements.count, 1)
            try test_returnStatement(s: prog.statements[0])
            let stmt = prog.statements[0] as! ReturnStatement
            try test_literalExpression(exp: stmt.returnValue, expected: t.1)
        }
    }

    func test_parsingPrefixExpr() throws {
        let tests: [(String, String, Any)] = [
            ("!5;", "!", 5),
            ("^-15\n", "^-", 15),
            ("+&true", "+&", true)
        ]

        for (i, t) in tests.enumerated() {
            print("Start test \(i): \(t)")

            let l = Lexer(input: t.0)
            let p = Parser(l)
            let prog = p.parseProgram()
            try test_parseErrors(p)

            XCTAssertEqual(prog.statements.count, 1)
            let stmt = try cast(prog.statements[0], ExpressionStatement.self)
            let exp = try cast(stmt.expression, PrefixExpression.self)
            guard exp.op == t.1 else {
                throw TestErrors.parseError("operator is not \(t.1). got=\(exp.op)")
            }
            try test_literalExpression(exp: exp.right, expected: t.2)
        }
    }
}
