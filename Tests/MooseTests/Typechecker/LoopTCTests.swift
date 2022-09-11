//
//  File.swift
//
//
//  Created by Johannes Zottele on 17.08.22.
//

import Foundation

extension TypecheckerTests {
    func test_forEach_fails() throws {
        try runInvalidTests(name: #function) {
            """
            for i in [1,2,3] {a(i)}
            func a(i: String) {}
            """

            """
            for i in b() {a(i)}
            func a(i: String) {}
            func b() > [Int] { return [1,2,3] }
            """

            """
            mut i: Int = 1

            for i in b() {a(i)}
            func a(i: Int) {}
            func b() > [Int] { return [1,2,3] }
            """

            """
            for (i, (j, y)) in [(2, [(2,2)])] {}
            """
        }
    }

    func test_forEach_ok() throws {
        try runValidTests(name: #function) {
            """
            for i in [1,2,3] {a(i)}
            func a(i: Int) {}
            """

            """
            for i in b() {a(i)}
            func a(i: Int) {}
            func b() > [Int] { return [1,2,3] }
            """

            """
            for i in [[1],[2]] {a(i[0])}
            func a(i: Int) {}
            """

            """
            for (i, j) in [(1,"String"), (2, "Test")] {
                a(i)
            }
            func a(i: Int) {}
            """

            """
            list = [("1", true), ("2", false)]
            mut a = ""
            for (key, (val, b)) in list.enumerated() {
                a +: val
                a(key)
            }
            func a(i: Int) {}
            """
        }
    }

    func test_forCStyle_fails() throws {
        try runInvalidTests(name: #function) {
            """
            for mut b = 2;a();b +: 1 {}
            func a() > String { return "Test" }
            """

            """
            for b = 2;true;b +: 1 {}
            """

            """
            b = 2;
            for ;
                b < 2;
                b +: 1
            {

            }
            """

            """
            for mut b = 2;true;b +: 1 {}
            print(b)
            """

            """
            mut x: Int = nil
            for x = 2; 2+32; {}
            """

            """
            for 2+32 {}
            """

            """
            mut b = "Test"
            for (i, (j, b)) in [(1,"String"), (2, "Test")].enumerated() {
                a(i)
            }
            func a(i: Int) {}
            """
        }
    }

    func test_forCStyle_ok() throws {
        try runValidTests(name: #function) {
            """
            for mut b = 2;a();b +: 1 {}
            func a() > Bool { return true }
            """

            """
            for mut b = 2;true;b +: 1 {}
            """

            """
            mut b = 2;
            for ;
                b < 2;
                b +: 1
            {

            }
            """

            """
            for mut b = 2;true;b +: 1 {
                        print(b)
            }
            """

            """
            mut x: Int = nil
            for x = 2; true; {}
            """

            """
            for true {}
            """
        }
    }
}
