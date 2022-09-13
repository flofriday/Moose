//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.09.22.
//

import Foundation
@testable import Moose

extension InterpreterTests {
    func test_tupleAccess() throws {
        try runValidTests(name: #function, [
            (
                """
                a = (1,2,3,4)
                a1 = a.0
                a2 = a.1
                """,
                [
                    ("a1", IntegerObj(value: 1)),
                    ("a2", IntegerObj(value: 2))
                ]
            ),

            (
                """
                a: (Int, String) = (1, "String")
                b: String = a.1
                """,
                [
                    ("b", StringObj(value: "String"))
                ]
            ),

            (
                """
                a: (A, A) = (A(1,2), A(3,4))
                b = a.1.a

                class A < B {a: Int}
                class B {b: Int}
                """,
                [
                    ("b", IntegerObj(value: 3))
                ]
            )

        ])
    }
}
