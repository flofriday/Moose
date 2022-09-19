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

            ("""
            a: {Int:B} = {
                1: A(1,2),
                2: B(3)
            }

            a[1] = B(5)
            a[2] = A(1,6)
            a[10] = A(1,7)
            a5 = a[1].a
            a6 = a[2].a
            a7 = a[10].a

            class A < B {c: Int}
            class B {a: Int}
            """, [
                ("a5", IntegerObj(value: 5)),
                ("a6", IntegerObj(value: 6)),
                ("a7", IntegerObj(value: 7)),
            ])

            ("""
            a: {Int:B} = {
                1: A(1,2),
                2: B(3)
            }

            ((a[1], a[2]), a[10]) = ((B(5), A(1,6)), A(1,7))
            a5 = a[1].a
            a6 = a[2].a
            a7 = a[10].a

            class A < B {c: Int}
            class B {a: Int}
            """, [
                ("a5", IntegerObj(value: 5)),
                ("a6", IntegerObj(value: 6)),
                ("a7", IntegerObj(value: 7)),
            ])

            ("""
            a: {Int:B} = {
                1: A(1,2),
                2: B(3)
            }


            classWrap = C(D(B(5), A(1,6)), A(1,7))
            ((a[1], a[2]), a[10]) = classWrap
            a5 = a[1].a
            a6 = a[2].a
            a7 = a[10].a


            class C { d: D; a: A }
            class D { a: B; b: A }
            class A < B {c: Int}
            class B {a: Int}
            """, [
                ("a5", IntegerObj(value: 5)),
                ("a6", IntegerObj(value: 6)),
                ("a7", IntegerObj(value: 7)),
            ])
        }
    }

    func test_dict_methods() throws {
        try runValidTests(name: #function, [
            ("""
            a: {Int:String} = {
                500: "Internal server error",
                200: "OK",
                403: "Access forbidden",
                404: "File not found"
            }

            str = a.represent()
            print(str)
            e500 = a[500]
            strT = [e500].represent()
            """, [
                ("e500", StringObj(value: "Internal server error")),
                ("strT", StringObj(value: "[\"Internal server error\"]")),
            ]),

            ("""
            a: {Int:String} = {
                500: "Internal server error",
                200: "OK",
                403: "Access forbidden",
                404: "File not found"
            }

            len = a.length()

            mut lastKey: Int
            mut lastVal: String
            mut lastIndex: Int
            for (i, (key, value)) in a.flat().enumerated() {
                lastKey = key
                lastVal = value
                lastIndex = i
            }

            """, [
                ("len", IntegerObj(value: 4)),
                ("lastKey", IntegerObj(value: 404)),
                ("lastIndex", IntegerObj(value: 3)),
                ("lastVal", StringObj(value: "File not found")),
            ]),
        ])
    }

    func test_list() throws {
        try runValidTests(name: #function) {
            ("""
            mut test = "Unchanged"
            a = ["a", "b", "c"]
            test = a[0 + 2]

            """, [
                ("test", StringObj(value: "c")),
            ])

            ("""
            mut test = "Unchanged"
            a = ["a", "b", "c"]
            test = a.getItem(0 + 2)

            """, [
                ("test", StringObj(value: "c")),
            ])

            ("""
            mut test = "Unchanged"
            a = ["a", "b", "c"]
            test = a.getItem(0 + 2)

            """, [
                ("test", StringObj(value: "c")),
            ])

            ("""
            mut test1Var = "Unchanged"
            mut test2Var = "Unchanged"

            a = A(["a","b","c","d"])
            a.test1()
            a.test2()

            func outer(a: Int) > Int { return a }
            class A {
                a: [String]
                func test1() { test1Var = me.a[outer(1) + inner(2)] }
                func test2() { test2Var = a[outer(1) * me.inner(1)] }
                func inner(a: Int) > Int { return a }
            }

            """, [
                ("test1Var", StringObj(value: "d")),
                ("test2Var", StringObj(value: "b")),
            ])

            ("""
            a: [B] = [A(1), A(2), A(3)]
            b = a[1].a

            class A < B {}
            class B { a: Int }
            """, [
                ("b", IntegerObj(value: 2)),
            ])

            ("""
            a = [A(1), B(2), C(3), F(4)]

            b = a[1].a
            mut t = 0
            if a[0] is D { t = 1 }

            class A < C {}
            class B < C {}
            class C < D {}
            class F < D {}
            class D { a: Int }
            """, [
                ("b", IntegerObj(value: 2)),
                ("t", IntegerObj(value: 1)),
            ])

            ("""
            a = [1,2,4]
            a[0] = 2
            b = a[0]
            """, [
                ("b", IntegerObj(value: 2)),
            ])

            ("""
            a: [B] = [A(1), A(2), A(3)]
            t2 = a[1].a
            a[1] = B(4)
            t4 = a[1].a
            a[0] = A(12)
            t12 = a[0].a
            class A < B {}
            class B { a: Int }
            """, [
                ("t2", IntegerObj(value: 2)),
                ("t4", IntegerObj(value: 4)),
                ("t12", IntegerObj(value: 12)),
            ])
        }
    }

    func test_list_methods() throws {
        try runValidTests(name: #function, [
            ("""
            a = [1,2,3]
            b = [5,6,7]
            l3 = a.length()
            a.append(4)
            l4 = a.length()
            a.append(b)
            l7 = a.length()
            """, [
                ("l3", IntegerObj(value: 3)),
                ("l4", IntegerObj(value: 4)),
                ("l7", IntegerObj(value: 7)),
            ]),

            ("""
            a: [B] = [A(1),A(2),A(3)]
            b = [B(5),B(6),B(7)]
            l3 = a.length()
            a.append(A(4))
            l4 = a.length()
            a.append(b)
            l7 = a.length()

            class A < B {
                func represent() > String { return a.represent() }
            }
            class B {
                a: Int
            }

            print("")
            print("Output: " + a.represent())
            print("")
            """, [
                ("l3", IntegerObj(value: 3)),
                ("l4", IntegerObj(value: 4)),
                ("l7", IntegerObj(value: 7)),
            ]),

            ("""
            a = [1,2,3]

            mut lastIndex: Int = nil
            mut lastVal: Int = nil
            for (index, value) in a.enumerated() {
                lastIndex = index
                lastVal = value
            }

            """, [
                ("lastIndex", IntegerObj(value: 2)),
                ("lastVal", IntegerObj(value: 3)),
            ]),

            (
                """
                list = [("1", true), ("2", false)]
                mut a = ""
                for (key, (val, b)) in list.enumerated() {
                    a +: val
                    a(key)
                }
                func a(i: Int) {}
                """, [
                    ("a", StringObj(value: "12")),
                ]
            ),

            (
                """
                list = [1,2,3,4]
                same = list.reversed()

                t1 = list[0]
                t2 = same[0]

                t3 = t1 != t2
                """, [
                    ("t1", IntegerObj(value: 1)),
                    ("t2", IntegerObj(value: 4)),
                    ("t3", BoolObj(value: true)),
                ]
            ),

            (
                """
                list = [1,2,3,4]
                same = list.reverse()
                t1 = list[0]
                """, [
                    ("t1", IntegerObj(value: 4)),
                ]
            ),

            (
                """
                list = [1,2,3,4]
                t1 = list.reversed().joined()
                t2 = list.reversed().joined(" ")
                """, [
                    ("t1", StringObj(value: "4321")),
                    ("t2", StringObj(value: "4 3 2 1")),
                ]
            ),
        ])
    }

    func test_list_panics() throws {
        let tests: [(String, Panic)] = [
            (
                """
                // Index out of bounds test
                l = [1]
                a = l[1]
                """,
                OutOfBoundsPanic(length: 1, attemptedIndex: 1)
            ),
            (
                """
                // Index out of bounds write test
                l = [1, 2]
                l[100] = 42
                """,
                OutOfBoundsPanic(length: 2, attemptedIndex: 100)
            ),
            (
                """
                // Nil indexing test
                l: [Int] = nil
                a = l[1]
                """,
                NilUsagePanic()
            ),
            (
                """
                // Nil method test
                l: [Int] = nil
                a = l.length()
                """,
                NilUsagePanic()
            ),
        ]

        try runPanicTests(name: #function, tests)
    }

    func test_string_indexing() throws {
        try runValidTests(name: #function, [
            (
                """
                a = "AbC"

                len = a.length()
                aA = a[0]
                ab = a[1]
                aC = a[2]

                """, [
                    ("aA", StringObj(value: "A")),
                    ("ab", StringObj(value: "b")),
                    ("aC", StringObj(value: "C")),
                    ("len", IntegerObj(value: 3)),
                ]
            ),
        ])
    }
}
