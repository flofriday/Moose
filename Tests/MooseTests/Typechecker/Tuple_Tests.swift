//
//  File.swift
//
//
//  Created by Johannes Zottele on 11.08.22.
//

import Foundation

class TupleTests: TypecheckerBaseClass {
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
            //            """
            //            """,
            //            """
            //            """,
            //            """
            //            """,
        ]

        try runInvalidTests(tests)
    }

    func test_Tuples_doesRunThrough() throws {
        print("-- \(#function)")

        let tests = [
            "(a,b) = (1,2)",
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
            //            """
            //            """,
            //            """
            //            """,
            //            """
            //            """,
        ]

        try runValidTests(tests)
    }
}
