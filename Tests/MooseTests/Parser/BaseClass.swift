//
// Created by Johannes Zottele on 18.06.22.
//

import Foundation
@testable import Moose
import XCTest

class BaseClass: XCTestCase {
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

    func test_returnStatement(s: Statement) throws {
        XCTAssertEqual(s.tokenLexeme, "return", "s.tokenLiteral not 'return'. got=\(s.tokenLexeme)")
        guard s is ReturnStatement else {
            throw TestErrors.parseError("s is not ReturnStatement. gpt=\(type(of: s))")
        }
    }

    func test_identifier(exp: Expression, value: String) throws {
        guard let ident = exp as? Identifier else {
            throw TestErrors.parseError("exp not Identifier. got=\(type(of: exp))")
        }
        XCTAssertEqual(ident.value, value)
        XCTAssertEqual(ident.tokenLexeme, value)
    }

    func test_integerLiteral(exp: Expression, value: Int64) throws {
        guard let intlit = exp as? IntegerLiteral else {
            throw TestErrors.parseError("exp not Int64. got=\(type(of: exp))")
        }
        XCTAssertEqual(intlit.value, value)
    }

    func test_booleanLiteral(exp: Expression, value: Bool) throws {
        guard let bool = exp as? Boolean else {
            throw TestErrors.parseError("exp not Boolean. got=\(type(of: exp))")
        }
        XCTAssertEqual(bool.value, value)
    }

    func test_literalExpression(exp: Expression, expected: Any) throws {
        switch expected {
        case let i as Int:
            try test_integerLiteral(exp: exp, value: Int64(i))
        case let i as Int64:
            try test_integerLiteral(exp: exp, value: i)
        case let b as Bool:
            try test_booleanLiteral(exp: exp, value: b)
        case let s as String:
            try test_identifier(exp: exp, value: s)
        default:
            throw TestErrors.testError("type of exp not handled. got=\(type(of: expected))")
        }
    }

    func test_infixExpression(exp: Expression, left: Any, op: String, right: Any) throws {
        guard let opExp = exp as? InfixExpression else {
            throw TestErrors.parseError("exp not InfixExpression. got=\(type(of: exp))")
        }
        try test_literalExpression(exp: opExp.left, expected: left)
        guard opExp.op == op else {
            throw TestErrors.parseError("opExp.op is not '\(op)'. got=\(opExp.op)")
        }
        try test_literalExpression(exp: opExp.right, expected: right)
    }

    func test_parseErrors(_ p: Parser) throws {
        XCTAssertEqual(p.errors.count, 0, "Got parse errors: \n- \(p.errors.map { String(describing: $0) }.joined(separator: "\n- "))")
    }

    func cast<T>(_ val: Any, _ t: T.Type) throws -> T {
        guard let val = val as? T else {
            throw TestErrors.parseError("\(val) not \(T.self). got=\(type(of: val))")
        }
        return val
    }

}
