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
    func test_builtIn_function() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                """
                // Range function
                l1 = range(1)
                l2 = range(4)
                l3 = range(0)
                """, [
                    ("l1", ListObj(type: ListType(IntType()), value: [0].map { IntegerObj(value: $0) })),
                    ("l2", ListObj(type: ListType(IntType()), value: [0, 1, 2, 3].map { IntegerObj(value: $0) })),
                    ("l3", ListObj(type: ListType(IntType()), value: [])),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }

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
                f = -67
                """,
                [
                    ("a", IntegerObj(value: 5)),
                    ("b", IntegerObj(value: 1)),
                    ("c", IntegerObj(value: 6)),
                    ("d", IntegerObj(value: 1)),
                    ("e", IntegerObj(value: 3)),
                    ("f", IntegerObj(value: -67)),
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

    func test_nil_comparison() throws {
        try runValidTests(name: #function) {
            (
                """
                t1 = nil == nil

                a: Int = nil
                t2 = a == nil
                t3 = nil == a
                """, [
                    ("t1", BoolObj(value: true)),
                    ("t2", BoolObj(value: true)),
                    ("t3", BoolObj(value: true)),
                ]
            )

            (
                """
                f1 = nil != nil

                a: Int = nil
                f2 = a != nil
                f3 = nil != a
                """, [
                    ("f1", BoolObj(value: false)),
                    ("f2", BoolObj(value: false)),
                    ("f3", BoolObj(value: false)),
                ]
            )
        }
    }

    func test_builtIn_math_functions() throws {
        try runValidTests(name: #function, [
            (
                // min float and integer
                """
                f1 = min(0.023, 0.23)
                f2 = min(23.3, 23.0)
                f3 = min(-0.03, 2.3)

                f4 = [0.2, -0.003, 0.0].min()

                i1 = min(2, 12)
                i2 = min(13, 1)
                i3 = min(-12,-2)

                i4 = [1,-2,0].min()
                """, [
                    ("i1", IntegerObj(value: 2)),
                    ("i2", IntegerObj(value: 1)),
                    ("i3", IntegerObj(value: -12)),
                    ("i4", IntegerObj(value: -2)),
                    ("f1", FloatObj(value: 0.023)),
                    ("f2", FloatObj(value: 23.0)),
                    ("f3", FloatObj(value: -0.03)),
                    ("f4", FloatObj(value: -0.003)),
                ]
            ),

            (
                // max float and integer
                """
                f1 = max(0.023, 0.23)
                f2 = max(23.3, 23.0)
                f3 = max(-0.03, 2.3)

                f4 = [0.2, -0.003, 0.0].max()

                i1 = max(2, 12)
                i2 = max(13, 1)
                i3 = max(-12,-2)

                i4 = [1,-2,0].max()

                """, [
                    ("i1", IntegerObj(value: 12)),
                    ("i2", IntegerObj(value: 13)),
                    ("i3", IntegerObj(value: -2)),
                    ("i4", IntegerObj(value: 1)),
                    ("f1", FloatObj(value: 0.23)),
                    ("f2", FloatObj(value: 23.3)),
                    ("f3", FloatObj(value: 2.3)),
                    ("f4", FloatObj(value: 0.2)),
                ]
            ),

            (
                // abs float and integer
                """
                f1 = abs(0.023)
                f2 = abs(-0.023)
                f3 = abs(0.0)

                f4 = (-0.023).abs()

                i1 = abs(2)
                i2 = abs(-2)
                i3 = abs(0)

                i4 = (-2).abs()

                """, [
                    ("i1", IntegerObj(value: 2)),
                    ("i2", IntegerObj(value: 2)),
                    ("i3", IntegerObj(value: 0)),
                    ("i4", IntegerObj(value: 2)),
                    ("f1", FloatObj(value: 0.023)),
                    ("f2", FloatObj(value: 0.023)),
                    ("f3", FloatObj(value: 0.0)),
                    ("f4", FloatObj(value: 0.023)),
                ]
            ),

            (
                // abs float and integer
                """
                i1 = 2%3
                i2 = 5 % 1

                """, [
                    ("i1", IntegerObj(value: 2)),
                    ("i2", IntegerObj(value: 0)),
                ]
            ),

        ])
    }

    func test_builtIn_methods() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                """
                // List method tests
                a = [1].length()
                l1: [Int] = []
                b = l1.length()
                c = [1, 234, 234, 3, 5].length()
                """,
                [
                    ("a", IntegerObj(value: 1)),
                    ("b", IntegerObj(value: 0)),
                    ("c", IntegerObj(value: 5)),
                ]
            ),
            (
                """
                // Int method tests
                nilInt: Int = nil

                bool1 = 1.toBool()
                bool2 = 0.toBool()
                bool4 = 3245.toBool()

                float1 = 1.toFloat()
                float2 = 600.toFloat()

                str1 = 1.toString()
                str2 = 434599.toString()
                """,
                [
                    ("bool1", BoolObj(value: true)),
                    ("bool2", BoolObj(value: false)),
                    ("bool4", BoolObj(value: true)),

                    ("float1", FloatObj(value: 1)),
                    ("float2", FloatObj(value: 600)),

                    ("str1", StringObj(value: "1")),
                    ("str2", StringObj(value: "434599")),
                ]
            ),
            (
                """
                // Float method tests
                int1 = 1.0.toInt()
                int2 = 3.9.toInt()

                str1 = 0.02.toString()
                str2 = 8123.32.toString()
                """,
                [
                    ("int1", IntegerObj(value: 1)),
                    ("int2", IntegerObj(value: 3)),

                    ("str1", StringObj(value: String(0.02))),
                    ("str2", StringObj(value: String(8123.32))),
                ]
            ),
            (
                """
                // Bool method tests
                int1 = true.toInt()
                int2 = false.toInt()

                str1 = true.toString()
                str2 = false.toString()
                """,
                [
                    ("int1", IntegerObj(value: 1)),
                    ("int2", IntegerObj(value: 0)),

                    ("str1", StringObj(value: "true")),
                    ("str2", StringObj(value: "false")),
                ]
            ),
            (
                """
                // String method tests
                (int1, err1) = "123".parseInt()
                (int2, err2) = "somthing not parsable".parseInt()
                hasError2 = err2 != nil
                (int4, err4) = "123hohoho still not a string".parseInt()
                hasError4 = err4 != nil

                (float5, err5) = "3.3".parseFloat()
                (float6, err6) = "notthing".parseFloat()
                hasError6 = err6 != nil

                (bool8, err8) = "false".parseBool()
                (bool9, err9) = "truetrue".parseBool()
                hasError9 = err9 != nil

                int10 = "".length()
                int11 = "flotschi".length()

                str12 = "halo".capitalize()
                str13 = "WORLD".capitalize()
                str14 = "\tHey there \n  ".strip()
                str15 = "Nothing should change".strip()
                str16 = "Scream fire".upper()
                str17 = "You need to whisper: FIRE".lower()

                list18 = "flo,23,vienna,developer".split(",")
                list19 = "Dear mum,\nI hope you find this letter well.\nMunich was way colder than expected.\n\nYour flo".lines()

                bool20 = "hello".contains("world")
                bool21 = "hello world nice".contains("world")
                bool22 = "Flotschi".contains("flo")
                bool23 = "Flotschi".lower().contains("flo")
                """,
                [
                    ("int1", IntegerObj(value: 123)),
                    ("err1", StringObj(value: nil)),
                    ("int2", IntegerObj(value: nil)),
                    ("hasError2", BoolObj(value: true)),
                    ("int4", IntegerObj(value: nil)),
                    ("hasError4", BoolObj(value: true)),

                    ("float5", FloatObj(value: 3.3)),
                    ("err5", StringObj(value: nil)),
                    ("float6", FloatObj(value: nil)),
                    ("hasError6", BoolObj(value: true)),

                    ("bool8", BoolObj(value: false)),
                    ("err8", StringObj(value: nil)),
                    ("bool9", BoolObj(value: nil)),
                    ("hasError9", BoolObj(value: true)),

                    ("int10", IntegerObj(value: 0)),
                    ("int11", IntegerObj(value: 8)),

                    ("str12", StringObj(value: "Halo")),
                    ("str13", StringObj(value: "World")),
                    ("str14", StringObj(value: "Hey there")),
                    ("str15", StringObj(value: "Nothing should change")),
                    ("str16", StringObj(value: "SCREAM FIRE")),
                    ("str17", StringObj(value: "you need to whisper: fire")),

                    ("list18", ListObj(
                        type: StringType(),
                        value: ["flo", "23", "vienna", "developer"].map { StringObj(value: $0) }
                    )),
                    ("list19", ListObj(
                        type: StringType(),
                        value: [
                            "Dear mum,", "I hope you find this letter well.", "Munich was way colder than expected.", "", "Your flo",
                        ].map { StringObj(value: $0) }
                    )),

                    ("bool20", BoolObj(value: false)),
                    ("bool21", BoolObj(value: true)),
                    ("bool22", BoolObj(value: false)),
                    ("bool23", BoolObj(value: true)),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }
}
