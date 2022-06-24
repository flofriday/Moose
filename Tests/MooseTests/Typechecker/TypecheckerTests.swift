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
            "a: String = 3",
            """
            mut a = 3
            mut a = 2
            """,
            """
            mut a = 3
            a: Int = 2
            """,
            """
            mut a = 3
            a = "String"
            """,
            """
            a = 3
            a = 2
            """,
            "prefix * (i: Int) > Int { return true }",
            "prefix * (i: Int) { return true }",
            """
            func a() > Int {
                return true
                return 2
            }
            """,
            """
            func a() > Int {
            {
                return true
            }
                return 2
            }
            """,
            """
            func a() > Int {
            if true {
            return 2
            }
            """,
            """
            func a() > Int {
            if true {
            3
            } else {
            return 2
            }
            }
            """,
            """
            func a() > Int {
            if true {
            return 3
            } else {
            }
            }
            """,
            """
            func a() > Int {
            if true {
            return 3
            } else {
            }
            }
            """,
            """
            if true {
            return 3
            } else {
            }
            """,
            """
            func a() > Void {
            if true {
            return
            } else {
            }
            }
            """,
            """
            func a() > Void {
            if true {
            2
            } else {
            3
            }
            }
            """
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            do {
                let prog = try parseProgram(t)
                let tc = Typechecker()
                XCTAssertThrowsError(try tc.check(program: prog)) { err in
                    if let err = err as? CompileError {
                        print(err.getFullReport(sourcecode: t))
                    } else if let err = err as? CompileErrorMessage {
                        print(err.getFullReport(sourcecode: t))
                    } else {
                        XCTFail(err.localizedDescription)
                    }
                }
            } catch let err as CompileError {
                XCTFail(err.getFullReport(sourcecode: t))
            }
        }
    }

    func test_pass() throws {
        print("-- \(#function)")

        let tests = [
            """
            prefix * (i: Int) > Int {return 1}
            """,
            """
            prefix* (i: Int) > Int {return 1}
            """,
            """
            infix *(i: Int, a: Int) > Int {return 1}
            """,
            """
            postfix *(i: Int)
            { 1

            }
            """,
            """
            func a() > Int {
            {
                return 2
            }
            }
            """,
            "a: Int = 3",
            "a = 3",
//            "a: Int +: 1",
//            "a +: 1",
            """
            if true {
            2
            } else {
            3
            }
            }
            """,
            """
            func a() > Int {
            if true {
            return 3
            } else {
            return 2
            }
            }
            """,
            """
            func a() > Int {
            if true {
            } else {
            return 2
            }
            return 3
            }
            """,
            """
            func a() > Int {
            if true {
            return 2
            }
            return 3
            }
            """
        ]

        for (i, t) in tests.enumerated() {
            print("Start \(i): \(t)")

            do {
                let prog = try parseProgram(t)
                let tc = Typechecker()
                try tc.check(program: prog)
            } catch let error as CompileError {
                XCTFail(error.getFullReport(sourcecode: t))
            } catch let error as CompileErrorMessage {
                XCTFail(error.getFullReport(sourcecode: t))
            }
        }
    }
}
