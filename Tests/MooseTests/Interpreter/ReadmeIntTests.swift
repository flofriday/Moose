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

                a = breakfast ?? "Melage and semmel"
                b = breakfast != nil ? breakfast : "Melage and semmel"
                """,
                [
                    ("cookie", IntegerObj(value: nil)),
                    ("strudel", IntegerObj(value: nil)),
                    ("breakfast", StringObj(value: nil)),
                    ("a", StringObj(value: "Melage and semmel")),
                    ("b", StringObj(value: "Melage and semmel")),
                ]
            ),
            (
                """
                // Lists
                wishlist: [String] = ["Computer", "Bicycle", "Teddybear"]

                // Here we changed the print for our testframework
                c = wishlist[0]  // "Computer"
                t = wishlist[-1] // "Teddybear"

                wishlist.append("car")
                //wishlist.appendAll(["Aircraftcarrier", "Worlddomination"])
                """,
                [
                    ("wishlist", ListObj(
                        type: ListType(StringType()),
                        value: [
                            StringObj(value: "Computer"),
                            StringObj(value: "Bicycle"),
                            StringObj(value: "Teddybear"),
                            StringObj(value: "car"),
                        ]
                    )),
                    ("c", StringObj(value: "Computer")),
                    ("t", StringObj(value: "Teddybear")),
                ]
            ),
            (
                """
                // Dicts
                ages: { String: Int } = {
                    "Flo": 23,
                    "Paul": 24,
                    "Clemens": 7,
                }

                a = ages["Paul"]

                // TODO: These methods still need to be implemented
                //b = ages.contains("Paul")
                //ages.remove("Paul")
                //c = ages.contains("Paul") 
                """,
                [
                    ("a", IntegerObj(value: 24)),
                    // ("b", BoolObj(value: true)),
                    // ("a", IntegerObj(value: 24)),
                ]
            ),
            (
                """
                // If Else
                age = 23
                mut a = 0
                if age > 18 {
                    a = 1
                } else if age == 18 {
                   a = 2
                } else {
                   a = 3
                }

                // Sometimes you need to discriminate against Pauls
                name = "Paul"
                mut b = false
                if (age > 12) && (name != "Paul") {
                    b = true
                }
                """,
                [
                    ("a", IntegerObj(value: 1)),
                    ("b", BoolObj(value: false)),
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

                // while style loop
                // Adopted for tests with break so it exits imediatly
                mut cnt3 = 0
                for true {
                    cnt3 +: 1
                    print("I will never terminate")
                    break
                }
                """,
                [
                    ("cnt1", IntegerObj(value: 10)),
                    ("cnt2", IntegerObj(value: 34)),
                    ("cnt3", IntegerObj(value: 1)),
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
                //Operator Functions

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
            (
                """
                // Print Objects
                class Person {
                    name: String
                    age: Int

                }

                p = Person("Alan Turing", 41)

                // TODO: at time of writing this doesn't work yet
                //s = p.represent()
                """,
                [
                    // ("s", StringObj(value: "Person")),
                ]
            ),
            (
                """
                // Inheritance
                class Person {
                    name: String
                    age: Int
                    func hello() > String {
                        return "Hey I am " + me.name
                    }
                }

                class Employee < Person {
                    work: String

                    func hello() > String {
                        return "Hi I am " + me.name + " and I work at " + me.work
                    }
                }

                catrin = Employee("Google", "Catrin", 56)
                text = catrin.hello()
                """,
                [
                    ("text", StringObj(value: "Hi I am Catrin and I work at Google")),
                ]
            ),
            (
                """
                // Extending Classes
                class Person {
                    name: String
                    age: Int
                    func hello() > String {
                        // Instead of this, Moose uses me
                        return "Hey I am " + me.name
                    }
                }

                extend Person {
                    func wasBorn() > Int {
                        return 2022 - me.age
                    }
                }

                j = Person("Johannes", 23)
                y = j.wasBorn()
                """,
                [
                    ("y", IntegerObj(value: 1999)),
                ]
            ),
            (
                """
                person = ("luis", 17, false)

                // Without unpacking
                name1 = person.0
                age1 = person.1
                married1 = person.2

                // With unpacking
                (name2, age2, married2) = person

                b1 = name1 == name2
                """,
                [
                    ("name1", StringObj(value: "luis")),
                    ("name2", StringObj(value: "luis")),
                    ("age1", IntegerObj(value: 17)),
                    ("age2", IntegerObj(value: 17)),
                    ("married1", BoolObj(value: false)),
                    ("married2", BoolObj(value: false)),
                    ("b1", BoolObj(value: true)),
                ]
            ),
            (
                """
                // Unpacking Objects
                class Person {
                    name: String
                    age: Int
                    func hello() > String {
                        // Instead of this, Moose uses me
                        return "Hey I am " + me.name
                    }
                } 

                p = Person("Alan Turing", 41)
                (name, age) = p
                """,
                [
                    ("name", StringObj(value: "Alan Turing")),
                    ("age", IntegerObj(value: 41)),
                ]
            ),
            (
                """
                // Indexing
                class Person {
                    name: String

                    func getItem(i: Int) > String {
                        return name[i]
                    }
                }

                p = Person("Alan Turing")

                a = p[0]
                """,
                [
                    ("a", StringObj(value: "A")),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }

    // TODO: invalid tests that panic

    func test_stringEscapes() throws {
        try runValidTests(name: #function) {
            (
                """
                a1 = "new\\nline"
                a2 = "new\\"line"
                a3 = "new\\rline"
                a4 = "new\\0line"
                a5 = "new\\tline"
                a6 = "new\\\\line"

                a7 = "ansi\\e{asdf}code"
                a8 = "ansi\\\\e{asdf}code"
                """, [
                    ("a1", StringObj(value: "new\nline")),
                    ("a2", StringObj(value: "new\"line")),
                    ("a3", StringObj(value: "new\rline")),
                    ("a4", StringObj(value: "new\0line")),
                    ("a5", StringObj(value: "new\tline")),
                    ("a6", StringObj(value: "new\\line")),
                    ("a7", StringObj(value: "ansi\u{001B}asdfcode")),
                    ("a8", StringObj(value: "ansi\\e{asdf}code")),
                ]
            )
        }
    }
}
