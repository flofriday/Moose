//
// Created by Johannes Zottele on 17.06.22.
//

import Foundation
@testable import Moose
import XCTest

class ParserTests: BaseClass {
    /// - Todo: Fix test! test are not processed
    func test_assignStatements() throws {
        print("-- \(#function)")

        let inputs: [(String, String, Any, Bool, String?)] = [
            ("a = 3", "a", Int64(3), false, nil),
            ("mut b = 1", "b", Int64(1), true, nil),
            ("a = ident;", "a", "ident", false, nil),
            ("mut b = ident", "b", "ident", true, nil),
            ("var = true", "var", true, false, nil),
            ("mut var = false\n", "var", false, true, nil),
            ("mut var: Bool = false\n", "var", false, true, "Bool"),
            ("var: String = 2;", "var", Int64(2), false, "String"),
            ("var: String = ident", "var", "ident", false, "String"),
            ("var: (String) = ident", "var", "ident", false, "(String)"),
            ("var: ( String ,  Int) = ident", "var", "ident", false, "(String, Int)"),
            ("mut var: ( String, Int  ) = ident", "var", "ident", true, "(String, Int)"),
            ("var: ( (Val, Bool), (Int, String)  ) = true", "var", true, false, "((Val, Bool), (Int, String))")
        ]

        for (index, i) in inputs.enumerated() {
            print("Start test \(index): \(i)")

            let prog = try startParser(input: i.0)

            XCTAssertEqual(prog.statements.count, 1)
            let a = try test_assignStatement(stmt: prog.statements[0], name: i.1, mut: i.3, typ: i.4)
            XCTAssert(a.0, a.1)

            let stmt = prog.statements[0] as! AssignStatement
            try test_literalExpression(exp: stmt.value, expected: i.2)
        }
    }

    func test_assignStatement_WithExpression() throws {
        print("-- \(#function)")
        typealias ExpOp = (String, String, Any)

        let tests: [(String, String, ExpOp)] = [
            ("a +: 3\n", "a", ("a", "+", 3)),
            ("a ^&: true;", "a", ("a", "^&", true)),
            ("a = b - c", "a", ("b", "-", "c"))
        ]

        for (i, t) in tests.enumerated() {
            print("Start test \(i): \(t)")

            let prog = try startParser(input: t.0)

            XCTAssertEqual(prog.statements.count, 1)
            let a = try test_assignStatement(stmt: prog.statements[0], name: t.1, mut: false, typ: nil)
            XCTAssert(a.0, a.1)

            let stmt = prog.statements[0] as! AssignStatement
            let expr = try cast(stmt.value, InfixExpression.self)
            try test_literalExpression(exp: expr.left, expected: t.2.0)
            XCTAssertEqual(expr.op, t.2.1)
            try test_literalExpression(exp: expr.right, expected: t.2.2)
        }
    }

    func test_returnStatements() throws {
        print("-- \(#function)")

        let tests: [(String, Any)] = [
            ("return 5;", Int64(5)),
            ("return true", true),
            ("return x", "x"),
            ("return x\n", "x"),
            ("return x;", "x")
        ]

        for (i, t) in tests.enumerated() {
            print("Start test \(i): \(t)")

            let prog = try startParser(input: t.0)

            XCTAssertEqual(prog.statements.count, 1)
            try test_returnStatement(s: prog.statements[0])
            let stmt = prog.statements[0] as! ReturnStatement
            try test_literalExpression(exp: stmt.returnValue, expected: t.1)
        }
    }

    func test_parsingPrefixExpr() throws {
        print("-- \(#function)")

        let tests: [(String, String, Any)] = [
            ("!5;", "!", 5),
            ("^-15\n", "^-", 15),
            ("+&true", "+&", true)
        ]

        for (i, t) in tests.enumerated() {
            print("Start test \(i): \(t)")

            let prog = try startParser(input: t.0)

            XCTAssertEqual(prog.statements.count, 1)
            let stmt = try cast(prog.statements[0], ExpressionStatement.self)
            let exp = try cast(stmt.expression, PrefixExpression.self)
            guard exp.op == t.1 else {
                throw TestErrors.parseError("operator is not \(t.1). got=\(exp.op)")
            }
            try test_literalExpression(exp: exp.right, expected: t.2)
        }
    }

    func test_parsingInfixExpression() throws {
        print("-- \(#function)")

        let tests: [(String, Any, String, Any)] = [
            ("5 + true\n", 5, "+", true),
            ("1231 ^^ 12;", 1231, "^^", 12),
            ("true#false", true, "#", false),
            ("1@2", 1, "@", 2),
            ("1<<2", 1, "<<", 2)
        ]

        for (i, t) in tests.enumerated() {
            print("Start test \(i): \(t)")

            let prog = try startParser(input: t.0)

            XCTAssertEqual(prog.statements.count, 1)
            let stmt = try cast(prog.statements[0], ExpressionStatement.self)
            let exp = try cast(stmt.expression, InfixExpression.self)
            try test_literalExpression(exp: exp.left, expected: t.1)
            guard exp.op == t.2 else {
                throw TestErrors.parseError("operator is not \(t.2). got=\(exp.op)")
            }
            try test_literalExpression(exp: exp.right, expected: t.3)
        }
    }

    func test_operatorPrecendeceParsing() throws {
        print("-- \(#function)")

        let tests = [
            ("a + b * c", "(a + (b * c))"),
            ("a +: b * c", "a = (a + (b * c))"),
            ("a * b + c", "((a * b) + c)"),
            ("a *: b + c", "a = (a * (b + c))"),
            ("a *: b + c * 2", "a = (a * (b + (c * 2)))"),
            ("a == b &^ c < d + g", "((a == b) &^ (c < (d + g)))"),
            ("-c+", "(-(c+))"),
            ("a+ =+ c", "((a+) =+ c)"),
            ("a+ :+ :$c%", "((a+) :+ (:$(c%)))"),
            ("a +: :$c%", "a = (a + (:$(c%)))")
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let prog = try startParser(input: t.0)
            XCTAssertEqual(t.1, prog.description)
        }
    }
}
