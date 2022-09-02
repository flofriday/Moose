//
//  BuiltIn_Int_Tests.swift
//
//
//  Created by flofriday on 2200.08.22.
//

import Foundation
@testable import Moose
import XCTest

// Here are all the examples we stuck into the readme. We want to make sure
// that these always work.
extension InterpreterTests {
    func test_readme() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                """
                // Mutable Variables
                mut a = 2
                a = 4
                a +: 1

                mut b: Int
                b = 2
                """,
                [
                    ("a", IntegerObj(value: 5)),
                    ("b", IntegerObj(value: 2)),
                ]
            ),
            (
                """
                // Immutabel Variables
                b: Int
                c: Int = 3
                """,
                [
                    ("b", IntegerObj(value: nil)),
                    ("c", IntegerObj(value: 3)),
                ]
            ),
            (
                """
                // Nil
                cookie: Int = nil
                strudel: Int
                breakfast: String = nil

                // TODO: we are missing the other two examples here but trenary
                // operator or the ?? operatore are both not implemented.
                """,
                [
                    ("cookie", IntegerObj(value: nil)),
                    ("strudel", IntegerObj(value: nil)),
                    ("breakfast", StringObj(value: nil)),
                ]
            ),
            (
                """
                // Lists
                wishlist: [String] = ["Computer", "Bicycle", "Teddybear"]

                // Here we changed the print for our testframework
                c = wishlist[0]  // "Computer"
                t = wishlist[-1] // "Teddybear"

                // TODO: we cannot append to lists at the moment
                //wishlist.append("car")
                //wishlist.appendAll(["Aircraftcarrier", "Worlddomination"])
                """,
                [
                    ("wishlist", ListObj(
                        type: ListType(StringType()),
                        value: [
                            StringObj(value: "Computer"),
                            StringObj(value: "Bicycle"),
                            StringObj(value: "Teddybear"),
                        ]
                    )),
                    ("c", StringObj(value: "Computer")),
                    ("t", StringObj(value: "Teddybear")),
                ]
            ),
            (
                """
                // Dicts
                // TODO: add them, but at the moment they are not implemented
                """,
                [
                ]
            ),
            (
                """
                // If Else
                age = 23
                if age > 18 {
                    print("Please enter")
                // TODO: implement else if 
                //} else if age == 18 {
                //    print("Finally you can enter")
                } else {
                    print("I am sorry come back in a year")
                }

                // Sometimes you need to discriminate against Pauls
                name = "Paul"
                if (age > 12) && (name != "Paul") {
                    print("Welcome to the waterpark")
                }
                """,
                [
                    ("age", IntegerObj(value: 23)),
                    ("name", StringObj(value: "Paul")),
                ]
            ),
            (
                """
                // For

                // For-each style
                mut cnt1 = 0
                for i in range(10) {
                    cnt1 +: 1
                }

                // C-style loop
                mut cnt2 = 0
                for mut i = 0; i < 100; i +: 3 {
                    cnt2 +: 1
                }

                // TODO: So since there is no break, we cannot test this in 
                // finite time.
                // while style loop
                // for true {
                //    print("I will never terminate")
                // } 
                """,
                [
                    ("cnt1", IntegerObj(value: 10)),
                    ("cnt2", IntegerObj(value: 34)),
                ]
            ),
            (
                """
                // Classic Function
                func myFunction(age: Int, name: String) > String {
                    return "Hi I am " + name + " " + age.toString()
                }

                p = myFunction(42, "Alan Turing") 
                """,
                [
                    ("p", StringObj(value: "Hi I am Alan Turing 42")),
                ]
            ),
            (
                """
                // What if JS was right with adding numbers to strings?
                infix + (a: String, b: Int) > String {
                    return a + b.toString()
                }

                // A prefix + makes numbers positive
                prefix + (a: Int) > Int {
                    if a < 0 {
                        return a * -1
                    }
                    return a
                }

                a = "4"
                b = 12

                c = a + b
                print(c) // 412

                // Adapted here for testsuite
                mut d = -2
                d = +d
                print(d) // 2
                """,
                [
                    ("c", StringObj(value: "412")),
                    ("d", IntegerObj(value: 2)),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }
}
