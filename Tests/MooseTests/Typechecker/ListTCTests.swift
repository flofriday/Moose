//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation

extension TypecheckerTests {
    func test_List_throwsError() throws {
        try runInvalidTests(name: #function) {
            "[1,true]"
            """
            a: Int = 3
            func test() > String { return "String" }
            b = [a, test(), 123, true]
            """
            "func arr () > [String] { return [1,3,4] }"
            """
            arrOne = [true,false,true]
            arrTwo = [1,2,3,4]
            arr = [arrOne, arrTwo]
            """

            """
            [A(), B()]
            class A {}
            class B {}
            """

            """
            a: [A] = [A(), B()]
            class A < B {}
            class B {}
            """
        }
    }

    func test_List_runsThrough() throws {
        try runValidTests(name: #function) {
            "[1,2]"

            """
            a: String = "One"
            func test() > String { return "String" }
            b = [a, test()]
            """

            """
            arrOne = [1,2,3]
            arrTwo = [1,2,3,4]
            arr = [arrOne, arrTwo]
            """

            """
            [A(), B()]
            class A < B {}
            class B {}
            """

            """
            a: [B] = [A(), A()]
            class A < B {}
            class B {}
            """

            """
            a: [B] = [A(), B()]
            class A < B {}
            class B {}
            """
        }
    }

    func test_indexing_throwsError() throws {
        try runInvalidTests(name: #function) {
            """
            a = 123
            a[0]
            """
            """
            a = [1,3,4]
            a["hello"]
            """
            """
            func arr () > [Int] { return [1,3,4] }
            [1,2,3,4][arr()]
            """
            """
            func index () > String { return "Test" }
            arr = [true,false,true]
            arr[index()]
            """
            """
            mut a: String = [1,2,3][1] + 2
            """
            """
            a = [1,2,4]
            a[0] = true
            """
            """
            a = "Hello"
            a[0] = 2
            """
            """
            a = [1,2,3]
            a[0]: String = 2
            """
            """
            b[0] = 2
            """
        }
    }

    func test_indexing_runThrough() throws {
        try runValidTests(name: #function) {
            """
            a = [1,2,3]
            a[0]
            """
            """
            func arr () > [Int] { return [1,3,4] }
            arr()[2]
            """
            """
            mut a: Int = [1,2,3][1] + 2
            """
            """
            a = [1,2,4]
            a[0] = 2
            """
        }
    }
}
