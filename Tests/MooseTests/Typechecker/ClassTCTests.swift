//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation

extension TypecheckerTests {
    func test_derefering_ok() throws {
        try runValidTests(name: #function) {
            """
            print(2.toString() + " two")
            """
            """
            class A { a:Int }
            b: Int = A(1).a
            """
            """
            class A { a:[Int] }
            b: Int = A([2]).a[0]
            """
            """
            class A { a:[B] }
            class B { b:String }
            b: B = A([B("Hello")]).a[0]
            """
            """
            class A { a:[B] }
            class B { mut b:String }
            b = B("Hello")
            a = A([b])
            a.a[0].b = "World"
            """
            """
            class A { a:[B] }
            class B { mut b:String }
            b = B("Hello")
            a = A([b])
            (a.a[0].b, c) = ("World", 3)
            """
            """
            class A { b:Int; func a() > Int { return me.b } }
            a = A(2)
            b: Int = a.a()
            """

            """
            class A {
                b:Int;
                func a(b: String) > Int { return me.b }
            }
            b: Int = A(2).a("Test")
            """

            """
            [A(2)][0].a()

            class A {
                b: Int;
                func a() {}
            }
            """
        }
    }

    func test_derefering_fails() throws {
        try runInvalidTests(name: #function) {
            """
            class A { a:Int }
            b: String = A(1).a
            """
            """
            class A { a:[Int] }
            b: String = A([2]).a[0]
            """
            """
            class A { a:[B] }
            class B { b:String }
            b: Bool = A([B("Hello")]).a[0]
            """
            """
            class A { a:[B] }
            class B { mut b:String }
            b = B("Hello")
            a = A([b])
            a.a[0].b = true
            """
            """
            class A { a:[B] }
            class B { mut b:String }
            b = B("Hello")
            a = A([b])
            (a.a[0].b, c) = (true, 3)
            """

            """
            class A { b:Int; func a() > String { return me.b } }
            """

            """
            class A { b:Int; func a(b: String) > String { return me.b } }
            """

            """
            b = "Test"
            class A { func a() > String { return me.b } }
            """

            """
            class A { }
            func f() { }
            A().f()
            """

            """
            class A { func a() { me.f() } }
            func f() { }
            """
        }
    }

    func test_classDependency_fails() throws {
        try runInvalidTests(name: #function) {
            """
            class A < B {}
            class B < A {}
            """

            """
            class A < B {}
            class B < C {}
            """

            """
            class A < B {}
            class B < C {}
            class C < A {}
            """

            """
            class A < B {}
            class B { a: Int }
            a = A()
            """

            """
            class A < B { a: Int }
            class B { a: Int }
            """

            """
            class A < B { a: String }
            class B < C { }
            class C { a: Int }
            """

            """
            class A < B { func a() > String { return "String" } }
            class B { func a() > Int {return 2} }
            """

            """
            class A < B { func a() > String { return "String" } }
            class B < C { }
            class C { func a() > Int {return 2} }
            """

            """
            class A { a: C }
            """
        }
    }

    func test_classDependency_ok() throws {
        try runValidTests(name: #function) {
            """
            class A < B {}
            class B {}
            """

            """
            class A < B {}
            class B < C {}
            class C {}
            """

            """
            class A < B {}
            class B { a: Int }
            a = A(2)
            print(a.a)
            """

            """
            a = A(2)
            print(a.a)
            class C { a: Int }
            class A < B {}
            class B < C {}
            """

            """
            class A < B { func a(a: String) {}}
            class C { func a(a: String) {}}
            class B < C { func a(a: Int) {}}
            """
        }
    }

    func test_classTyping_fail() throws {
        try runInvalidTests(name: #function) {
            """
            a: A = B()

            class A < B {}
            class B {}
            """

            """
            a: B = A(2)
            print(a.a)

            class A < B {a: Int}
            class B {}
            """

            """
            C(B())

            class A < B {a: Int}
            class B {}
            class C {c: A}
            """
        }
    }

    func test_classTyping_ok() throws {
        try runValidTests(name: #function) {
            """
            a: B = A()

            class A < B {}
            class B {}
            """

            """
            C(A(2))

            class A < B {a: Int}
            class B {}
            class C {c: B}
            """

            """
            a(A())

            func a(a: B) {}
            class A < B{}
            class B{}
            """

            """
            ++A()

            prefix ++ (a: B) {}
            class A < B{}
            class B{}
            """
        }
    }
}
