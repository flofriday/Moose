//
//  BuiltIn_Int_Tests.swift
//
//
//  Created by flofriday on 19.08.22.
//

import Foundation
@testable import Moose
import XCTest

extension InterpreterTests {
    func test_builtIn_operators() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                """
                // Integer arithmetic
                a = 3 + 2
                b = 3 - 2
                c = 3 * 2
                d = 3 / 2
                e = 9 / 3
                """,
                [
                    ("a", IntegerObj(value: 5)),
                    ("b", IntegerObj(value: 1)),
                    ("c", IntegerObj(value: 6)),
                    ("d", IntegerObj(value: 1)),
                    ("e", IntegerObj(value: 3)),
                ]
            ),
            (
                """
                // Integer comparison
                a =   90 > 1
                b =    3 > 3
                c =    3 > 68
                e =  90 >= 1
                f =   3 >= 3
                g =   3 >= 68
                h =  42 == 42
                i =  12 == 23
                j =  77 != 77
                k = 899 != 3
                l =    4 < 8
                m =   55 < 55
                n =  900 < 0
                o =   4 <= 8
                p =  55 <= 55
                q = 900 <= 0
                """,
                [
                    ("a", BoolObj(value: true)),
                    ("b", BoolObj(value: false)),
                    ("c", BoolObj(value: false)),
                    ("e", BoolObj(value: true)),
                    ("f", BoolObj(value: true)),
                    ("g", BoolObj(value: false)),
                    ("h", BoolObj(value: true)),
                    ("i", BoolObj(value: false)),
                    ("j", BoolObj(value: false)),
                    ("k", BoolObj(value: true)),
                    ("l", BoolObj(value: true)),
                    ("m", BoolObj(value: false)),
                    ("n", BoolObj(value: false)),
                    ("o", BoolObj(value: true)),
                    ("p", BoolObj(value: true)),
                    ("q", BoolObj(value: false)),
                ]
            ),
            (
                """
                // Float arithmetic
                // Note: it might be that these are flaky, because floating 
                //point can be difficult
                a = 1.23 + 78.9
                b = 1.23 - 78.9
                c = 1.23 * 78.9
                d = 1.23 / 78.9
                """,
                [
                    ("a", FloatObj(value: 1.23 + 78.9)),
                    ("b", FloatObj(value: 1.23 - 78.9)),
                    ("c", FloatObj(value: 1.23 * 78.9)),
                    ("d", FloatObj(value: 1.23 / 78.9)),
                ]
            ),
            (
                """
                // Float comparison
                a =     1.1 > 1.0
                b =  3.1415 > 3.1415
                c =    30.9 > 68.4
                e =   90.8 >= 1.8
                f =   3.22 >= 3.22
                g =    0.8 >= 68.99
                h =     42 == 42
                i =   12.0 == 23.0
                j =   77.0 != 77.0
                k = 899.77 != 3.77
                l =    4.90 < 8.98
                m =    55.6 < 55.6
                n =   900.6 < 0.6
                o =    4.6 <= 8.6
                p =   55.6 <= 55.6
                q =  900.9 <= 0.9
                """,
                [
                    ("a", BoolObj(value: true)),
                    ("b", BoolObj(value: false)),
                    ("c", BoolObj(value: false)),
                    ("e", BoolObj(value: true)),
                    ("f", BoolObj(value: true)),
                    ("g", BoolObj(value: false)),
                    ("h", BoolObj(value: true)),
                    ("i", BoolObj(value: false)),
                    ("j", BoolObj(value: false)),
                    ("k", BoolObj(value: true)),
                    ("l", BoolObj(value: true)),
                    ("m", BoolObj(value: false)),
                    ("n", BoolObj(value: false)),
                    ("o", BoolObj(value: true)),
                    ("p", BoolObj(value: true)),
                    ("q", BoolObj(value: false)),
                ]
            ),
            (
                """
                // Bool calculations
                T = true
                F = false
                a = T && T
                b = F && T
                c = T && F
                d = F && F
                e = T || T
                f = F || T
                g = T || F
                h = F || F
                """,
                [
                    ("a", BoolObj(value: true)),
                    ("b", BoolObj(value: false)),
                    ("c", BoolObj(value: false)),
                    ("d", BoolObj(value: false)),
                    ("e", BoolObj(value: true)),
                    ("f", BoolObj(value: true)),
                    ("g", BoolObj(value: true)),
                    ("h", BoolObj(value: false)),
                ]
            ),
            (
                """
                // Bool comparision
                a =  true == true
                b =  true == false
                c = false == true
                d = false == false
                e =  true != true
                f =  true != false
                g = false != true
                h = false != false
                """,
                [
                    ("a", BoolObj(value: true)),
                    ("b", BoolObj(value: false)),
                    ("c", BoolObj(value: false)),
                    ("d", BoolObj(value: true)),
                    ("e", BoolObj(value: false)),
                    ("f", BoolObj(value: true)),
                    ("g", BoolObj(value: true)),
                    ("h", BoolObj(value: false)),
                ]
            ),
            (
                """
                    // String comparison
                    a =   "hey" == "hey"
                    b =   "hey" == "there"
                    c = "hello" != "hello"
                    d = "hello" != "world"
                """,
                [
                    ("a", BoolObj(value: true)),
                    ("b", BoolObj(value: false)),
                    ("c", BoolObj(value: false)),
                    ("d", BoolObj(value: true)),
                ]
            ),
            (
                """
                // String calculations
                name = "Robert" + " " + "Nystrom"
                title = "Crafting" + "Interpreters"
                archer = "I had" + "" + " something for this."
                """,
                [
                    ("name", StringObj(value: "Robert Nystrom")),
                    ("title", StringObj(value: "CraftingInterpreters")),
                    ("archer", StringObj(value: "I had something for this.")),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }
}
