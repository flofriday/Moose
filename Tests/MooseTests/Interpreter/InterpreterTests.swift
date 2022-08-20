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
                        type: TupleType([BoolType(), StringType()]),
                        value: [BoolObj(value: true), StringObj(value: "no")]
                    )),
                    ("l", ListObj(
                        type: ListType(IntType()),
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

    func test_functions() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                """
                // Simple function
                func one() > Int {
                    return 1
                }

                a = one()
                """,
                [("a", IntegerObj(value: 1))]
            ),
            (
                """
                // Function with arguments
                func add(n: Int, m: Int) > Int {
                    return n + m
                }

                a = add(42, 90)
                """,
                [("a", IntegerObj(value: 132))]
            ),
            (
                """
                // Side effect function
                mut ugly = 777
                func effect() {
                    ugly = 42
                }

                effect()
                """,
                [("ugly", IntegerObj(value: 42))]
            ),
            (
                """
                // Useless function (never called)
                mut perfect = 13
                func useless() {
                    perfect = 666
                }
                """,
                [("perfect", IntegerObj(value: 13))]
            ),
            (
                """
                // Recursive power function
                func pow(base: Int, power: Int) > Int {
                    if power <= 1 {
                        return base
                    }
                    return base * pow(base, power - 1)
                }

                a = pow(2, 2)
                b = pow(2, 3)
                c = pow(3, 3)
                d = pow(2, 32)
                """,
                [
                    ("a", IntegerObj(value: 4)),
                    ("b", IntegerObj(value: 8)),
                    ("c", IntegerObj(value: 27)),
                    ("d", IntegerObj(value: 4_294_967_296)),
                ]
            ),
            (
                """
                // Nested calling
                func zero() > Int {
                    return 0
                }

                func addOne(n: Int) > Int {
                    return n + 1
                }

                a = addOne(addOne(addOne(addOne(zero()))))
                """,
                [
                    ("a", IntegerObj(value: 4)),
                ]
            ),
            // TODO: This should work but doesn't
            // https://github.com/flofriday/Moose/issues/12
            /*
                (
                    """
                    // Variable name collision

                    func inner() {
                        x = 8000
                    }

                    func outer() > Int {
                        x = 3
                        inner()
                        return x
                    }

                    a = outer()
                    """,
                    [
                        ("a", IntegerObj(value: 3)),
                    ]
                ),
                */
        ]

        try runValidTests(name: #function, tests)
    }
}
