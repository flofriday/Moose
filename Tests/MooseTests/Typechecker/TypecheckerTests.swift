//
//  File.swift
//
//
//  Created by Johannes Zottele on 22.06.22.
//

import Foundation
@testable import Moose
import XCTest

class TypecheckerTests: TypecheckerBaseClass {
    func test_throwsErrors() throws {
        print("-- \(#function)")

        let tests = [
            "a = 3",
            "a +: 1",
            "a: String = 3"
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let prog = try parseProgram(t)
            let tc = Typechecker()
            XCTAssertThrowsError(try tc.check(program: prog)) { err in
                print(err.localizedDescription)
            }
        }
    }

    func test_pass() throws {
        print("-- \(#function)")

        let tests = [
            "a: Int = 3",
            "a: Int +: 1"
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            let prog = try parseProgram(t)
            let tc = Typechecker()
            do {
                try tc.check(program: prog)
            } let error as CompileError {
                error.f
            }
        }
    }
}
