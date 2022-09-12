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
    func test_controllflow() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                """
                // If tests
                mut a = 1
                mut b = 1
                mut c = 0
                mut x = 666

                // If with else
                if true {
                    a = 12
                } else {
                    b = 33
                }

                // If without else
                if true {
                    c = 42
                }

                // Else gets executed
                if false {} else {
                    x = 13
                }
                """,
                [
                    ("a", IntegerObj(value: 12)),
                    ("b", IntegerObj(value: 1)),
                    ("c", IntegerObj(value: 42)),
                    ("x", IntegerObj(value: 13)),
                ]
            ),
            (
                """
                // Long else-if chain test
                name = "Paul"
                mut number = 0

                if name == "Flo" {
                    number = 2
                } else if name == "Luis" {
                    number = 3
                } else if name == "Jojo" {
                    number = 4
                } else if name == "Elenor" {
                    number = 5
                } else if name == "Paul" {
                    number = 42
                } else if name == "Ada" {
                    number = 6
                }
                """,
                [
                    ("number", IntegerObj(value: 42)),
                ]
            ),
            (
                """
                // C-style for loop tests
                mut phrase = "Na"
                for mut i = 0; i < 6; i +: 1 {
                    phrase +: "na"
                }
                phrase +: " batman!"

                mut cnt = 0
                for cnt < 5 {
                    cnt +: 1
                }

                mut perfect = 42
                for ;false; {
                    perfect = 0
                }
                """,
                [
                    ("phrase", StringObj(value: "Nanananananana batman!")),
                    ("cnt", IntegerObj(value: 5)),
                    ("perfect", IntegerObj(value: 42)),
                ]
            ),
            (
                """
                // For each loop tests
                days = ["Mo", "Tue", "Thur", "Fri"]
                mut all = ""
                for day in days {
                    all +: day + " "
                }

                empty: [Int] = [ ]
                mut perfect = 42
                for nothing in empty {
                    perfect = 0
                }
                """,
                [
                    ("all", StringObj(value: "Mo Tue Thur Fri ")),
                    ("perfect", IntegerObj(value: 42)),
                ]
            ),
            (
                """
                // Break and continue at c-style for loops tests
                mut cnt = 0

                for mut i = 0; i < 100; i +: 1 {
                    cnt +: 1

                    if cnt == 3 {
                        break
                    }

                    continue
                    // should never run
                    cnt = 1000
                }

                // Check that the post-statement gets exectued correct
                mut j = 0
                for ; j < 100; j +: 1 {
                    if j == 10 {
                        break
                    }
                }

                """,
                [
                    ("cnt", IntegerObj(value: 3)),
                    ("j", IntegerObj(value: 10)),
                ]
            ),
            (
                """
                // Break and continue at c-style for loops tests
                mut chosen = ""

                members = ["Paul", "Flo", "Lukas", "Anna", "Vanessa"]

                for member in members {
                    chosen +: member + " "

                    if member == "Flo" {
                        break
                    }

                    continue
                    // should never run
                    chosen = "devil"

                }
                """,
                [
                    ("chosen", StringObj(value: "Paul Flo ")),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }

    func test_ternaryOp() throws {
        try runValidTests(name: #function) {
            (
                """
                a1 = true ? 1 : 2
                a2 = false ? 1 : 2
                a3 = 3 + 2 == 1 ? 1 * 3 + 12 : 2 * 3 / 2

                nil ? 2 : 3
                """,
                [
                    ("a1", IntegerObj(value: 1)),
                    ("a2", IntegerObj(value: 2)),
                    ("a3", IntegerObj(value: 3)),
                ]
            )
        }
    }
}
