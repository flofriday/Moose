//
//  File.swift
//
//
//  Created by Johannes Zottele on 17.08.22.
//

import Foundation
@testable import Moose
import XCTest

extension ParserTests {
    func test_forEachLoops() throws {
        let input = [
            ("for a  in b\n   {}", "for a in b {}"),
            ("for a  in a[2]\n   {}", "for a in a[2] {}"),
            ("for a  in fun(2)\n   {}", "for a in fun(2) {}"),
        ]

        try runTest(name: "Test for each loops", input: input) { inp in
            let prog = try startParser(input: inp.0)
            XCTAssertEqual(prog.statements.count, 1)
            let loop = try cast(prog.statements[0], ForEachStatement.self)
            XCTAssertEqual(loop.description, inp.1)
        }
    }

    func test_forCStyleLoops() throws {
        let input: [(String, String?, String, String?)] = [
            ("for ;a;\n{}", nil, "a", nil),
            ("for a=22+2;x < 2;a++\n{}", "a = (22 + 2)", "(x < 2)", "(a++)"),
            ("for 22 > 23\n{}", nil, "(22 > 23)", nil),
        ]

        try runTest(name: "Test for c-style loops", input: input) { inp in
            let prog = try startParser(input: inp.0)
            XCTAssertEqual(prog.statements.count, 1)
            let loop = try cast(prog.statements[0], ForCStyleStatement.self)
            XCTAssertEqual(loop.preStmt?.description, inp.1)
            XCTAssertEqual(loop.condition.description, inp.2)
            XCTAssertEqual(loop.postEachStmt?.description, inp.3)
        }
    }
}
