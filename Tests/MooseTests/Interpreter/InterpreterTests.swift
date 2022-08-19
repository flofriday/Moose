//
//  InterpreterTests.swift
//
//
//  Created by flofriday on 19.08.22.
//

import Foundation
@testable import Moose
import XCTest

class InterpreterTests: InterpreterBaseClass {
    func test_assignment() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                // Extrem basic example to find the worst bugs first
                "a = 3",
                [("a", IntegerObj(value: 3))]
            ),
            (
                // Mutablity of objects
                """
                mut a = 3
                a = 42
                """,
                [("a", IntegerObj(value: 42))]
            ),
            (
                // Make sure that assigning variables to each other doesn't
                // link their values
                """
                mut a = 13
                mut b = a
                b = 9000
                """,
                [
                    ("a", IntegerObj(value: 13)),
                    ("b", IntegerObj(value: 9000)),
                ]
            ),
            (
                """
                i = 1
                f = 1.2
                b = false
                s = "hey there"
                t = (true, "no")
                l = [9, 8, 12]
                """,
                [
                    ("i", IntegerObj(value: 1)),
                    ("f", FloatObj(value: 1.2)),
                    ("b", BoolObj(value: false)),
                    ("s", StringObj(value: "hey there")),
                    ("t", TupleObj(
                        type: .Tuple([.Bool, .String]),
                        value: [BoolObj(value: true), StringObj(value: "no")]
                    )),
                    ("l", ListObj(
                        type: .List(.Int),
                        value: [9, 8, 12].map { IntegerObj(value: $0) }
                    )),
                ]
            ),
            (
                """
                (a, b) = (1, false)
                mut (x, y) = ("flotschi", 99)
                y = 42
                """,
                [
                    ("a", IntegerObj(value: 1)),
                    ("b", BoolObj(value: false)),
                    ("x", StringObj(value: "flotschi")),
                    ("y", IntegerObj(value: 42)),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }
}
