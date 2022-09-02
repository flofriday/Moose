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
                """, [
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

                // TODO: At the moment this creating empty list literals don't 
                // compile.
                // https: // github.com/flofriday/Moose/issues/9
                //empty: [Int] = [ ]
                //mut perfect = 42
                //for nothing in emtpy {
                //    perfect = 0
                //}
                """, [
                    ("all", StringObj(value: "Mo Tue Thur Fri ")),
                    // ("perfect", IntegerObj(value: 42)),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }
}
