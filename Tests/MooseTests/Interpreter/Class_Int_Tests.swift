//
//  BuiltIn_Int_Tests.swift
//
//
//  Created by flofriday on 2200.08.22.
//

import Foundation
@testable import Moose
import XCTest

extension InterpreterTests {
    func test_class() throws {
        let tests: [(String, [(String, MooseObject)])] = [
            (
                """
                // Simple class with single property
                class Person {
                    name: String
                }

                p = Person("Annabel")
                n = p.name
                """,
                [
                    ("n", StringObj(value: "Annabel")),
                ]
            ),
            (
                """
                // Class with multiple properties
                class Hero {
                    name: String
                    age: Int
                    reason: String
                    fictional: Bool
                }

                p = Hero("Brian Kernighan", 2022 - 1942, "Essential to Unix", false)
                a = p.name
                b = p.age
                c = p.reason
                d = p.fictional
                """,
                [
                    ("a", StringObj(value: "Brian Kernighan")),
                    ("b", IntegerObj(value: 80)),
                    ("c", StringObj(value: "Essential to Unix")),
                    ("d", BoolObj(value: false)),
                ]
            ),
            (
                """
                // Class with getter method
                class Number {
                    value: Int

                    func getValue() > Int {
                        environment()
                        return value
                    }
                }

                a = Number(42).getValue()
                """,
                [
                    ("a", IntegerObj(value: 42)),
                ]

            ),
            (
                """
                // Class with method
                class HappyPerson {
                    name: String

                    func greet(to: String) > String {
                        mut text = "Hi "
                        text +: to
                        text +: ", I am "
                        text +: name
                        text +: ", it is so delightful to meet you :)"
                        return text
                    }
                }

                mira = HappyPerson("Mira")
                spoken = mira.greet("Johannes")
                """,
                [
                    ("spoken", StringObj(value: "Hi Johannes, I am Mira, it is so delightful to meet you :)")),
                ]
            ),
            (
                """
                // Argument and member name colission
                class Car {
                    mut speed: Int

                    func setSpeed(mut speed: Int) {
                        me.speed = speed
                        speed = 9000    // This should not affect the member
                    }
                }

                brumbrum = Car(3)
                brumbrum.setSpeed(24)
                a = brumbrum.speed
                """,
                [
                    ("a", IntegerObj(value: 24)),
                ]
            ),
            // TODO: Nested classes
        ]

        try runValidTests(name: #function, tests)
    }
}
