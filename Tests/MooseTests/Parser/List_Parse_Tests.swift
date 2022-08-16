//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation
@testable import Moose
import XCTest

extension ParserTests {
    func test_listLiterals() throws {
        let input = [
            ("[1]", "[1]"),
            ("[2+5]", "[(2 + 5)]"),
            ("[true,12, xyz]", "[true, 12, xyz]"),
            ("[Test(), 12, xyz]", "[Test(), 12, xyz]"),
        ]

        try runTest(name: "List Literals", input: input) { inp in
            let prog = try startParser(input: inp.0)
            XCTAssertEqual(prog.statements.count, 1)
            let stmt = try cast(prog.statements[0], ExpressionStatement.self)
            let list = try cast(stmt.expression, List.self)
            XCTAssertEqual(list.description, inp.1)
        }
    }

    func test_indexExpressions() throws {
        let input = [
            ("a[2 ] [ 3]", "a[2][3]"),
            ("arr[ 2+2]", "arr[(2 + 2)]"),
            ("fun()[ f() ]", "fun()[f()]"),
//            ("Test().b[2]", "Test().b[2]")
        ]

        try runTest(name: "List Literals", input: input) { inp in
            let prog = try startParser(input: inp.0)
            XCTAssertEqual(prog.statements.count, 1)
            let stmt = try cast(prog.statements[0], ExpressionStatement.self)
            let indexing = try cast(stmt.expression, IndexExpression.self)
            XCTAssertEqual(indexing.description, inp.1)
        }
    }
}
