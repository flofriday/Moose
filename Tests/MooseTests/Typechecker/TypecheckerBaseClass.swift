//
//  TypecheckerBaseClass.swift
//
//
//  Created by Johannes Zottele on 22.06.22.
//

@testable import Moose
import XCTest

class TypecheckerBaseClass: XCTestCase {
    func parseProgram(_ input: String) throws -> Program {
        let l = Lexer(input: input)
        let p = Parser(tokens: try l.scan())
        return try p.parse()
    }

    func runInvalidTests(name: String, _ tests: [String]) throws {
        print("--- \(name)")
        for (i, t) in tests.enumerated() {
            print("------\nStart \(i): \n\(t)")

            do {
                let prog = try parseProgram(t)
                let tc = try Typechecker()
                XCTAssertThrowsError(try tc.check(program: prog)) { err in
                    if let err = err as? CompileError {
                        print(err.getFullReport(sourcecode: t))
                    } else if let err = err as? CompileErrorMessage {
                        print(err.getFullReport(sourcecode: t))
                    } else {
                        XCTFail(err.localizedDescription)
                    }
                }
            } catch let err as CompileError {
                XCTFail(err.getFullReport(sourcecode: t))
            }
        }
    }

    func runValidTests(name: String, _ tests: [String]) throws {
        print("--- \(name)")
        for (i, t) in tests.enumerated() {
            print("------\nStart Valid \(i): \n\(t)")

            do {
                let prog = try parseProgram(t)
                let tc = try Typechecker()
                try tc.check(program: prog)
            } catch let error as CompileError {
                XCTFail(error.getFullReport(sourcecode: t))
            } catch let error as CompileErrorMessage {
                XCTFail(error.getFullReport(sourcecode: t))
            }
        }
    }

    func runValidTests(name: String, @StringArrayBuilder _ tests: () -> [String]) throws {
        try runValidTests(name: name, tests())
    }

    func runInvalidTests(name: String, @StringArrayBuilder _ tests: () -> [String]) throws {
        try runInvalidTests(name: name, tests())
    }

    @resultBuilder
    enum StringArrayBuilder {
        static func buildBlock(_ strs: String...) -> [String] {
            strs
        }
    }
}
