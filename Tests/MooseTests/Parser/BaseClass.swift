//
// Created by Johannes Zottele on 18.06.22.
//

import Foundation
@testable import Moose
import XCTest

class BaseClass: XCTestCase {
    func test_assignStatement(stmt: Statement, name: String, mut: Bool, typ: String?) throws -> (Bool, String) {
        guard let stmt = stmt as? AssignStatement else {
            return (false, "Statement is not of type AssignStatement. got=\(String(describing: type(of: stmt)))")
        }
        XCTAssertTrue(stmt.getToken.type == .Assign || stmt.getToken.type == .Operator(pos: .Infix, assign: true),
                      "Token is neither .Assign nor .Operator. got=\(stmt.getToken.lexeme)")
        let assignable = try cast(stmt.assignable, Identifier.self)
        guard name == assignable.value else {
            return (false, "stmt.name.value not '\(name)'. got='\(assignable)'")
        }
        guard name == assignable.getToken.lexeme else {
            return (false, "stmt.name.token.lexeme not '\(name)'. got='\(assignable.getToken.lexeme)'")
        }
        guard mut == stmt.mutable else {
            return (false, "stmt.mutable is not \(mut)")
        }

        if let refType = typ {
            guard let stmtType = stmt.type else {
                return (false, "stmt.type is nil but should be identifier with value '\(refType)'")
            }
            try test_valueType(type: stmtType, value: refType)
        } else {
            XCTAssertTrue(stmt.type == nil, "stmt.type is not nil. got=\(String(describing: stmt.type))")
        }
        return (true, "")
    }

    func test_returnStatement(s: Statement) throws {
        XCTAssertEqual(s.getToken.lexeme, "return", "s.tokenLiteral not 'return'. got=\(s.getToken.lexeme)")
        guard s is ReturnStatement else {
            throw TestErrors.parseError("s is not ReturnStatement. gpt=\(type(of: s))")
        }
    }

    func test_identifier(exp: Expression, value: String) throws {
        guard let ident = exp as? Identifier else {
            throw TestErrors.parseError("exp not Identifier. got=\(type(of: exp))")
        }
        XCTAssertEqual(ident.value, value)
        XCTAssertEqual(ident.token.lexeme, value)
    }

    func test_valueType(type: ValueType, value: String) throws {
        XCTAssertEqual(type.description, value)
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

    func cast<T>(_ val: Any, _ t: T.Type) throws -> T {
        guard let val = val as? T else {
            throw TestErrors.parseError("\(val) not \(T.self). got=\(type(of: val))")
        }
        return val
    }

    func startParser(input: String) throws -> Program {
        let l = Lexer(input: input)
        do {
            let p = Parser(tokens: try l.scan())
            return try p.parse()
        } catch let error as CompileError {
            XCTFail("Could not parse program without error:\n \(error.getFullReport(sourcecode: input))")
            throw error
        }
    }
}
