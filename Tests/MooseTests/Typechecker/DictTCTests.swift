//
//  File.swift
//
//
//  Created by Johannes Zottele on 05.09.22.
//

import Foundation

extension TypecheckerTests {
    func test_DictConstructor_fails() throws {
        try runInvalidTests(name: #function) {
            """
            {1: true, true: 1}
            """

            """
            {true: 2, 2: 1}
            """

            """
            {true: "Test", false: 1}
            """

            """
            {A(): "Test", B(): "String"}

            class A {}
            class B {}
            """

            """
            {"Test": A(), "String": B()}

            class A {}
            class B {}
            """

            """
            {"Test": A(), "String": B(), "T": C()}

            class A < B {}
            class B {}
            class C {}
            """
        }
    }

    func test_DictConstructor_ok() throws {
        try runValidTests(name: #function) {
            """
            {false: 2, true: 1}
            """

            """
            {true: "Test", false: "String"}
            """

            """
            {A(): "Test", B(): "String"}

            class A < B {}
            class B {}
            """

            """
            {"Test": A(), "String": B()}

            class A < B {}
            class B {}
            """
        }
    }

    func test_DictAssignment_fails() throws {
        try runInvalidTests(name: #function) {
            """
            a: {Int:String} = {"A": "String", "B": "String"}
            """
            """
            a: {String:Int} = {"A": "String", "B": "String"}
            """
            """
            a: {A:String} = {A(): "String", B(): "String"}

            class A < B {}
            class B {}
            """
            """
            a: {String:A} = {"String": A(), "String": B()}

            class A < B {}
            class B {}
            """
            """
            a: {A:A} = {C(): A(), C(): B()}

            class A < B {}
            class B {}
            class C {}
            """
        }
    }

    func test_DictAssignment_ok() throws {
        try runValidTests(name: #function) {
            """
            a: {String:String} = {"A": "String", "B": "String"}
            """
            """
            a: {B:String} = {A(): "String", B(): "String"}

            class A < B {}
            class B {}
            """
            """
            a: {String:B} = {"String": A(), "String": B()}

            class A < B {}
            class B {}
            """
            """
            a: {C:B} = {C(): A(), C(): B()}

            class A < B {}
            class B {}
            class C {}
            """

            """
            a: {C:C} = {C(): A(), C(): B()}

            class A < B {}
            class B < C{}
            class C {}
            """
        }
    }
}
