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
        }
    }
}
