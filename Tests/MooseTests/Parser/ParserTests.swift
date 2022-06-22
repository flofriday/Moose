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

        // (input, ident, value, isMutable, Type)
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
            ("var: ( String ,  Int) = ident", "var", "ident", false, "(String, Int)"),
            ("mut var: ( string, Int  ) = ident", "var", "ident", true, "(string, Int)"),
            ("var: ( (Val, Bool), (Int, String)  ) = true", "var", true, false, "((Val, Bool), (Int, String))"),
            ("(var): Int = 2", "var", 2, false, "Int")
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

        let tests: [(String, String, Any, Bool)] = [
            ("!5;", "!", 5, false),
            ("^-15\n", "^-", 15, false),
            ("+&true", "+&", true, false),
            ("+:true", "+", true, true),
            ("=:12", "=", 12, true),
            ("::12", ":", 12, true)
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

            if t.3 {
                guard case .Operator(pos: .Prefix, true) = exp.token.type else {
                    throw TestErrors.parseError("token of stmt should be prefix assign operator. got=\(stmt.token.type)")
                }
            } else {
                guard case .Operator(pos: .Prefix, false) = exp.token.type else {
                    throw TestErrors.parseError("token of stmt should be prefix non-assign operator. got=\(stmt.token.type)")
                }
            }
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

    func test_parsingPostfixExpr() throws {
        print("-- \(#function)")

        let tests: [(String, String, Any, Bool)] = [
            ("5!;", "!", 5, false),
            ("15^-\n", "^-", 15, false),
            ("true+&", "+&", true, false),
            ("true+:", "+", true, true),
            ("12=:", "=", 12, true),
            ("12::", ":", 12, true)
        ]

        for (i, t) in tests.enumerated() {
            print("Start test \(i): \(t)")

            let prog = try startParser(input: t.0)

            XCTAssertEqual(prog.statements.count, 1)
            let stmt = try cast(prog.statements[0], ExpressionStatement.self)
            let exp = try cast(stmt.expression, PostfixExpression.self)
            guard exp.op == t.1 else {
                throw TestErrors.parseError("operator is not \(t.1). got=\(exp.op)")
            }
            try test_literalExpression(exp: exp.left, expected: t.2)

            if t.3 {
                guard case .Operator(pos: .Postfix, true) = exp.token.type else {
                    throw TestErrors.parseError("token of stmt should be prefix assign operator. got=\(stmt.token.type)")
                }
            } else {
                guard case .Operator(pos: .Postfix, false) = exp.token.type else {
                    throw TestErrors.parseError("token of stmt should be prefix non-assign operator. got=\(stmt.token.type)")
                }
            }
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

    func test_lightFunctions() throws {
        print("-- \(#function)")

        let tests = [
            ("func a (b: String) > Int {}", "func a(b: String) > Int {}"),
            ("func a (b: String, c: Int) {}", "func a(b: String, c: Int) > () {}"),
            ("func AS() {x}", "func AS() > () {x}"),
            ("func AS()>Int{x}", "func AS() > Int {x}"),
            ("func AS()> Int{x}", "func AS() > Int {x}"),
            ("func AS() >Int{x}", "func AS() > Int {x}"),
            ("asd(1, 3+ + 3 * 1)", "asd(1, ((3+) + (3 * 1)))"),
            ("a = asd(1)\n", "a = asd(1)"),
            ("mut a: String = asd((1, b(2)))\n", "mut a: String = asd((1, b(2)))"),
            ("mut a: String = asd()\n", "mut a: String = asd()"),
            ("mut a: String = asd(\"testString\")\n", "mut a: String = asd(\"testString\")")
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let prog = try startParser(input: t.0)
            XCTAssertEqual(t.1, prog.description)
        }
    }

    func test_functionStatements() throws {
        print("-- \(#function)")

        let input =
            """
            func fn(x: Int, y: (String, String)) > ReturnType
            {

            x + y
            mut a: Stirng = x;

            {
            mut a: String = 2;

            }

            return a


            }


            a = b


            """

        let prog = try startParser(input: input)
        XCTAssertEqual(prog.statements.count, 2)
        let fn = try cast(prog.statements[0], FunctionStatement.self)
        XCTAssertEqual(fn.params.count, 2)
        try test_literalExpression(exp: fn.params[0].name, expected: "x")
        try test_valueType(type: fn.params[0].declaredType, value: "Int")

        try test_literalExpression(exp: fn.params[1].name, expected: "y")
        try test_valueType(type: fn.params[1].declaredType, value: "(String, String)")

        try test_valueType(type: fn.returnType, value: "ReturnType")

        XCTAssertEqual(fn.body.statements.count, 4)
        let expr = try cast(fn.body.statements[0], ExpressionStatement.self)
        try test_infixExpression(exp: expr.expression, left: "x", op: "+", right: "y")
        _ = try cast(fn.body.statements[1], AssignStatement.self)

        let block = try cast(fn.body.statements[2], BlockStatement.self)
        XCTAssertEqual(block.statements.count, 1)
        _ = try cast(block.statements[0], AssignStatement.self)

        _ = try cast(fn.body.statements[3], ReturnStatement.self)
    }

    func test_valueTypeParsing() throws {
        print("-- \(#function)")

        let tests = [
            ("a: Test = 1", "Test"),
            ("a: (Test, Test) = 1", "(Test, Test)"),
            ("a: () > Void = 1", "() > ()"),
            ("a: () > () = 1", "() > ()"),
            ("a: (Int) > String = 1", "(Int) > String"),
            ("a: (Int, String) > String = 1", "(Int, String) > String"),
            ("a: (Int, () > (String)) > String = 1", "(Int, () > String) > String"),
            ("a: (Int) > (String, () > Error) > Bool = 1", "(Int) > (String, () > Error) > Bool"),
            ("a: () > ((Int) > String) = 1", "() > (Int) > String"),
            ("a: (() > Int) > String = 1", "(() > Int) > String")
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let prog = try startParser(input: t.0)
            XCTAssertEqual(prog.statements.count, 1)
            let ass = try cast(prog.statements[0], AssignStatement.self)
            try test_valueType(type: ass.declaredType!, value: t.1)
        }
    }

    func test_tupleAssignment() throws {
        print("-- \(#function)")
        let tests = [
            ("(a,a) = 1", true),
            ("(1,a) = 1", false),
            ("(a,1) = 1", false),
            ("(a,a,1) = 1", false),
            ("(a,a,a) = 1", true),
            ("(a,a,a) = nil", false),
            ("(a,a): Int = nil", false),
            ("(a,a): Int = (nil)", false)
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let l = Lexer(input: t.0)
            let p = Parser(tokens: try l.scan())

            if !t.1 {
                return XCTAssertThrowsError(try p.parse())
            }

            let prog = try p.parse()
            XCTAssertEqual(prog.statements.count, 1)
            let ass = try cast(prog.statements[0], AssignStatement.self)
            let assignable = try cast(ass.assignable, Tuple.self)
            XCTAssertTrue(assignable.isAssignable)
        }
    }

    func test_assertThrows() throws {
        let tests = [
            "(a+1) = 1",
            "a = nil",
            "a = (nil)",
            "prefix += (a: Int, b: Int) > String {}",
            "infix += (a: Int b: Int) > String {}"
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let l = Lexer(input: t)
            let p = Parser(tokens: try l.scan())

            XCTAssertThrowsError(try p.parse()) {
                if let err = $0 as? CompileError {
                    print(err.getFullReport(sourcecode: t))
                } else {
                    print($0)
                }
            }
        }
    }

    func test_passTests() throws {
        let tests = [
            "func a() > (String) > (String) > String {}"
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let l = Lexer(input: t)
            do {
                let p = Parser(tokens: try l.scan())
                _ = try p.parse()
            } catch let err as CompileError {
                XCTFail(err.getFullReport(sourcecode: t))
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func test_operatorDefintionParsing() throws {
        let tests = [
            ("infix += (a: Int, b: Int) > String {}", "+=", OpPos.Infix, 2, MooseType.String),
            ("prefix +: (a: Int) {}", "+:", OpPos.Prefix, 1, MooseType.Void),
            ("postfix++^ (a: Int) > CustomType {}", "++^", OpPos.Postfix, 1, MooseType.Class("CustomType")),
            ("infix +=(a: Int, b: (Tuple, Tuple)) > (String) > (Int) { a = b; return g}", "+=", OpPos.Infix, 2, MooseType.Function([.String], .Int))
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let prog = try startParser(input: t.0)
            XCTAssertEqual(prog.statements.count, 1)
            try test_operator(stmt: prog.statements[0], name: t.1, pos: t.2, argumentCount: t.3, returnType: t.4)
        }
    }
}
