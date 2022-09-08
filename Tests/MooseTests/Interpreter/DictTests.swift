//
//  File.swift
//
//
//  Created by Johannes Zottele on 06.09.22.
//

import Foundation
@testable import Moose

extension InterpreterTests {
    func test_dict() throws {
        try runValidTests(name: #function) {
            ("""
            a: {Int:String} = {
                1: "Hello",
                2: "World"
            }
            """, [
                ("a", DictObj(type: DictType(IntType(), StringType()),
                              pairs: [(IntegerObj(value: 1), StringObj(value: "Hello")), (IntegerObj(value: 2), StringObj(value: "World"))])),
            ])

            ("""
            a: {Int:B} = {
                1: A(1,2),
                2: A(3,4)
            }

            a2 = a[1].a
            a4 = a[2].a

            class A < B {c: Int}
            class B {a: Int}
            """, [
                ("a2", IntegerObj(value: 2)),
                ("a4", IntegerObj(value: 4)),
            ])
        }
    }
}
