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
            func a() > Int {
            if true {
            return
            } else {
            }
            }
            """,
            """
            func a() > Int {
            if true {
            2
            } else {
            3
            }
            }
            """,
            "a +: 1", // should throw because a is not declared yet
            "a: Int +: 1", // should throw because a is not declared yet
            """
            a: Int = 2
            a +: 1
            """, // a is not mutable
        ]

        try runInvalidTests(name: #function, tests)
    }

    func test_pass() throws {
        let tests = [
            """
            prefix * (i: Int) > Int {return 1}
            """,
            """
            prefix* (i: Int) > Int {return 1}
            """,
            """
            infix **(i: Int, a: Int) > Int {return 1}
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
            """
            mut a: Int = 2
            a +: 1
            """,
            """
            if true {
            2
            } else {
            3
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
            """,
            """
            func a() {
            if true {
            return
            } else {
            3
            }
            }
            """,
            "func a (b:Int) { b + 2 }",
            """
            b = 3
            func a (b:Int) { b + 2 }
            """,
            "prefix +++ (b:Int) { b + 2 }",
            """
            b = 3
            prefix +++ (b:Int) { b + 2 }
            """,
            """
            a = 2
            class test {
                c: Int
                func c() > Int { return a }
                func b() { c }
            }
            """,
        ]

        try runValidTests(name: #function, tests)
    }
}
