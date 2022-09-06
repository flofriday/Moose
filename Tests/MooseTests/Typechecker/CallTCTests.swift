//
//  File.swift
//
//
//  Created by Johannes Zottele on 16.08.22.
//

import Foundation

extension TypecheckerTests {
    func test_functionCall_fails() throws {
        try runInvalidTests(name: #function) {
            """
            func test() {}
            test(nil)
            """

            """
            func test(a: String) {}
            func test(a: Int) {}
            test(nil)
            """

            """
            func test(a: String, b: Int) {}
            func test(a: Int, b: Int) {}
            test(nil, 2)
            """
        }
    }

    func test_functionCall_ok() throws {
        try runValidTests(name: #function) {
            """
            func test(a: String) {}
            test(nil)
            """

            """
            func test(a: String, b: Int) {}
            func test(a: Int, b: String) {}
            test(nil, 2)
            test("Test", nil)
            """
        }
    }
}
