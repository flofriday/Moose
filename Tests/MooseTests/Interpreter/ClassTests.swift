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
            (
                """
                // Nested classes
                class Door {
                    mut open: Bool
                }

                class House {
                    mut door: Door
                }

                // Create a closed house
                h = House(Door(false))
                a = h.door.open

                // Open the door
                h.door.open = true
                b = h.door.open
                """,
                [
                    ("a", BoolObj(value: false)),
                    ("b", BoolObj(value: true)),
                ]
            ),
        ]

        try runValidTests(name: #function, tests)
    }

    // TODO: add inheritance tests

    func test_methodInheritance() throws {
        try runValidTests(name: #function) {
            ("""
            class A < B { func a(a: String) > String {return "A"}}
            class C { func a(a: String) > String {return "C"}}
            class B < C { func a(a: Int) > String {return "B"}}

            cC = C().a("T")
            bC = B().a("T")
            bB = B().a(2)
            aB = A().a(2)
            aA = A().a("T")
            """, [
                ("cC", StringObj(value: "C")),
                ("bC", StringObj(value: "C")),
                ("bB", StringObj(value: "B")),
                ("aB", StringObj(value: "B")),
                ("aA", StringObj(value: "A")),
            ])

            // The only difference to the test above is
            // that the class definitions are after the constructor calls
            // we have to test this since it is the reason why we need the
            // dependency resolver pass
            ("""
            cC = C().a("T")
            bC = B().a("T")
            bB = B().a(2)
            aB = A().a(2)
            aA = A().a("T")

            class A < B { func a(a: String) > String {return "A"}}
            class C { func a(a: String) > String {return "C"}}
            class B < C { func a(a: Int) > String {return "B"}}
            """, [
                ("cC", StringObj(value: "C")),
                ("bC", StringObj(value: "C")),
                ("bB", StringObj(value: "B")),
                ("aB", StringObj(value: "B")),
                ("aA", StringObj(value: "A")),
            ])

            // The only difference to the test above is
            // that it uses a constructor inside a method
            ("""
            cC = C().a("T")
            bC = B().a("T")
            bB = B().a(2)
            aB = A().a(2)
            aC = A().a("T")

            class A < B { func a(a: String) > String {return C().a("T")}}
            class C { func a(a: String) > String {return "C"}}
            class B < C { func a(a: Int) > String {return "B"}}
            """, [
                ("cC", StringObj(value: "C")),
                ("bC", StringObj(value: "C")),
                ("bB", StringObj(value: "B")),
                ("aB", StringObj(value: "B")),
                ("aC", StringObj(value: "C")),
            ])

            // Tests that function with nearest params to class type is chosen
            ("""
            mut a: String = nil
            t(A())

            func t(x: C) { a = "C"}
            func t(x: B) { a = "B"}
            class A < B {}
            class B < C {}
            class C {}
            """, [
                ("a", StringObj(value: "B")),
            ])

            // Tests that the function of any is before a unkown function
            ("""
            mut a: String = "Unchanged"
            print(A())

            func print(b: C) { a = "Changed" }
            class A {}
            class C {}
            """, [
                ("a", StringObj(value: "Unchanged")),
            ])

            // Tests that the function with a class subtype is chosen over the any of print
            ("""
            mut a: String = "Unchanged"
            print(A())

            func print(b: C) { a = "Changed" }
            class A < C {}
            class C {}
            """, [
                ("a", StringObj(value: "Changed")),
            ])

            // Tests that the function with a class subtype is chosen over the any of print
            ("""
            mut a: String = "Unchanged"
            ++A()

            prefix ++ (b: B) { a = "Changed"}
            class A < B{}
            class B{}
            """, [
                ("a", StringObj(value: "Changed")),
            ])
        }
    }

    func test_propertyInheritance() throws {
        try runValidTests(name: #function) {
            // Tests basic property inheritance
            ("""
            a = A("AValue", "BValue")
            aA = a.a
            aB = a.b

            class A < B { a: String}
            class B { b: String }
            """, [
                ("aA", StringObj(value: "AValue")),
                ("aB", StringObj(value: "BValue")),
            ])

            // tests property reference over multiple superclasses
            ("""
            a = A("AValue", "BValue").a()

            class A < B { a: String; func a() > String { return b } }
            class B < C {}
            class C { b: String }
            """, [
                ("a", StringObj(value: "BValue")),
            ])

            // tests me reference to property over multiple superclasses
            ("""
            a = A("AValue", "BValue").a("InvalidString")

            class A < B { a: String; func a(b: String) > String { return me.b } }
            class B < C {}
            class C { b: String }
            """, [
                ("a", StringObj(value: "BValue")),
            ])
        }
    }
}