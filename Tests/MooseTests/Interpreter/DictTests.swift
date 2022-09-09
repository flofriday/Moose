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
}
