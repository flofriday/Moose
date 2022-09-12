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

            """
            a = A()
            b = 2
            x = 3
            T().test()

            func set(a: Int) > Int { return a }
            class A {}
            class T {
                func test () {
                    me.call( a.set(x), b)
                }
                func call(a: Int, b: Int) { print((a, b)) }
            }
            """

            """
            func three() > Int {
                return 3
            }

            return
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

            """
            a = A()
            b = 2
            x = 3
            T().test()

            class A {
                func set(a: Int) > Int { return a }
            }
            class T {
                func test () {
                    me.call( a.set(x), b)
                }
                func call(a: Int, b: Int) { print((a, b)) }
            }
            """
        }
    }
}
