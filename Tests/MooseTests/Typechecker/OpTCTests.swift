//
//  File.swift
//
//
//  Created by Johannes Zottele on 01.09.22.
//

import Foundation

extension TypecheckerTests {
    func test_equal_operator_ok() throws {
        try runValidTests(name: #function) {
            """
            "String" == "String"
            """

            """
            2 == "String"
            """

            """
            2 == 4
            """

            """
            class A {}
            2 == A()
            """

            """
            class A {}
            class B {}
            A() == B()
            """

            """
            true == 2
            """

            """
            true == nil
            """
        }
    }

    func test_equal_operator_fail() throws {
        try runInvalidTests(name: #function) {
            """
            A() == 2
            """
        }
    }
}
