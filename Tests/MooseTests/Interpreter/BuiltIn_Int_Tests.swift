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
        // At the moment of writing we only have IO functions that are hard
        // to test, so this test is empty for now.
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
                bool3 = nilInt.toBool()
                bool4 = 3245.toBool()

                float1 = 1.toFloat()
                float2 = 600.toFloat()
                float3 = nilInt.toFloat()

                str1 = 1.toString()
                str2 = 434599.toString()
                str3 = nilInt.toString()
                """,
                [
                    ("bool1", BoolObj(value: true)),
                    ("bool2", BoolObj(value: false)),
                    ("bool3", BoolObj(value: nil)),
                    ("bool4", BoolObj(value: true)),

                    ("float1", FloatObj(value: 1)),
                    ("float2", FloatObj(value: 600)),
                    ("float3", FloatObj(value: nil)),

                    ("str1", StringObj(value: "1")),
                    ("str2", StringObj(value: "434599")),
                    ("str3", StringObj(value: nil)),
                ]
            ),
            (
                """
                // Float method tests
                nilFloat: Float = nil

                int1 = 1.0.toInt()
                int2 = 3.9.toInt()
                int3 = nilFloat.toInt()

                str1 = 0.02.toString()
                str2 = 8123.32.toString()
                str3 = nilFloat.toString()
                """,
                [
                    ("int1", IntegerObj(value: 1)),
                    ("int2", IntegerObj(value: 3)),
                    ("int3", IntegerObj(value: nil)),

                    ("str1", StringObj(value: String(0.02))),
                    ("str2", StringObj(value: String(8123.32))),
                    ("str3", StringObj(value: nil)),
                ]
            ),
            (
                """
                // Bool method tests
                nilBool: Bool = nil

                int1 = true.toInt()
                int2 = false.toInt()
                int3 = nilBool.toInt()

                float1 = true.toFloat()
                float2 = false.toFloat()
                float3 = nilBool.toFloat()

                str1 = true.toString()
                str2 = false.toString()
                str3 = nilBool.toString()
                """,
                [
                    ("int1", IntegerObj(value: 1)),
                    ("int2", IntegerObj(value: 0)),
                    ("int3", IntegerObj(value: nil)),

                    ("float1", FloatObj(value: 1.0)),
                    ("float2", FloatObj(value: 0.0)),
                    ("float3", FloatObj(value: nil)),

                    ("str1", StringObj(value: "true")),
                    ("str2", StringObj(value: "false")),
                    ("str3", StringObj(value: nil)),
                ]
            ),
            (
                """
                // String method tests
                nilString: String = nil

                (int1, err1) = "123".parseInt()
                (int2, err2) = "somthing not parsable".parseInt()
                hasError2 = err2 != nil
                (int3, err3) = nilString.parseInt()
                (int4, err4) = "123hohoho still not a string".parseInt()
                hasError4 = err4 != nil

                (float5, err5) = "3.3".parseFloat()
                (float6, err6) = "notthing".parseFloat()
                hasError6 = err6 != nil
                (float7, err7) = nilString.parseFloat()

                (bool8, err8) = "false".parseBool()
                (bool9, err9) = "truetrue".parseBool()
                hasError9 = err9 != nil
                (bool10, err10) = nilString.parseBool()
                """,
                [
                    ("int1", IntegerObj(value: 123)),
                    ("err1", StringObj(value: nil)),
                    ("int2", IntegerObj(value: nil)),
                    ("hasError2", BoolObj(value: true)),
                    ("int3", IntegerObj(value: nil)),
                    ("err3", StringObj(value: nil)),
                    ("int4", IntegerObj(value: nil)),
                    ("hasError4", BoolObj(value: true)),

                    ("float5", FloatObj(value: 3.3)),
                    ("err5", StringObj(value: nil)),
                    ("float6", FloatObj(value: nil)),
                    ("hasError6", BoolObj(value: true)),
                    ("float7", FloatObj(value: nil)),
                    ("err7", StringObj(value: nil)),

                    ("bool8", BoolObj(value: false)),
                    ("err8", StringObj(value: nil)),
                    ("bool9", BoolObj(value: nil)),
                    ("hasError9", BoolObj(value: true)),
                    ("bool10", BoolObj(value: nil)),
                    ("err10", StringObj(value: nil)),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }
}
