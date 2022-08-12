//
//  File.swift
//
//
//  Created by Johannes Zottele on 11.08.22.
//

import Foundation

extension TypecheckerTests {
    func test_Tuples_throwsErrors() throws {
        print("-- \(#function)")

        let tests = [
            "(a,b) = 1",
            """
            a = 3
            (a,b) = (1,3)
            """,
            """
            (a,b): (Bool, Int) = ("String", 3)
            """,
            """
            (a,b,a) = (1,3,2)
            """,
            """
            (a,b): String = (1,2)
            """,
            """
            mut a = 3
            mut (a, b) = (1,2)
            """,

            """
            class Test { a: Bool; }
            (a, b) = Test(true)
            """,
            """
            mut a = 3
            class Test { a: Bool; b: Int}
            (a, b) = Test(true, 1)
            """,
            """
            class Test { a: Bool; b: Int}
            (a, b): (Int, Int) = Test(true, 1)
            """,
            //            """
            //            """,
        ]

        try runInvalidTests(tests)
    }

    func test_Tuples_doesRunThrough() throws {
        print("-- \(#function)")

        let tests = [
            //            "(a,b) = (1,2)",
            """
            mut a = 3
            (a,b) = (1,3)
            """,
            """
            (a,b): (String, Int) = ("String", 3)
            """,
            """
            mut (b,a) = (1,3)
            b = 2
            a = 3
            """,
            """
            (a,b,c) = (1,"String",2,true)
            """,
            """
            (a,b): (Int, Float) = (1,1.32)
            """,
            """
            mut a = 3
            (a, b) = (1 + 4,2 * 4)
            """,
            """
            a = (1,3)
            (b,c) = a
            """,
            """
            a = (1,3,4,5)
            (b,c) = a
            """,
            """
            class test { a: Int; b: Int }
            (b,c) = test(1,3)
            """,
            """
            class test { a: Int; b: Bool }
            a = test(12+3, true)
            (b,c) = a
            """,
            """
            class test { a: Bool; b: Int; c: String }
            a = test(true, 2, "Test")
            (b,c): (Bool, Int) = a
            """,
            """
            mut a = 3
            class Test { a: Int; b: Int}
            (a, b) = Test(1, 3)
            """,
            """
            ((c,d), b) = ((1, 3), 2)
            """,
            """
            (a, b) = (((true,"Hello"), 3), 2)
            ((x,y),d): ((Bool, String), Int) = a
            """,
            """
            class Test { a: (Bool, Int); b: Int}
            a = Test((true, 3), 3)
            ((bol, str), b) = a
            """,
            """
            (a, b) = (((true,"Hello"), 3), 2)
            mut x = false
            ((x,y),d): ((Bool, String), Int) = a
            """,
//            """
//            """,
        ]

        try runValidTests(tests)
    }
}
