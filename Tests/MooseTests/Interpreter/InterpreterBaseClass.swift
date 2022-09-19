//
//  InterpreterBaseClass.swift
//
//
//  Created by flofriday on 19.08.22.
//

@testable import Moose
import XCTest

class InterpreterBaseClass: XCTestCase {
    /// This funciton prepares the input sourcecode for the
    /// interpreter. We also need it to be typechecked, because the
    /// typechecker also addds type information to the AST on which
    /// the interpreter relies on.
    func parseAndCheckProgram(_ input: String) throws -> Program {
        let l = Lexer(input: input)
        let p = Parser(tokens: try l.scan())
        let a = try p.parse()
        let t = try Typechecker()
        try t.check(program: a)
        return a
    }

    func validatePromises(env: Environment, promises: [(String, MooseObject)]) throws {
        for (variable, expected) in promises {
            let value = try env.get(variable: variable)
            guard value.equals(other: expected) else {
                throw InterpreterTestError(message: "Variable '\(variable)' should be \(expected) but was \(value).")
            }
        }
    }

    /// Runs a list of valid tests. Each test is a
    /// (String, [(String, MooseObject)])  tuple where the first string is a
    /// program, followed by a list of variable names and Mooseobejcts. After
    /// the program is executed the test checks if each variable has the value
    /// it should have.
    func runValidTests(name: String, _ tests: [(String, [(String, MooseObject)])]) throws {
        print("--- \(name)")
        for (i, t) in tests.enumerated() {
            let (source, promises) = t
            print("------\nStart Valid \(i): \n\(source)")

            do {
                let prog = try parseAndCheckProgram(source)
                let i = Interpreter.shared
                i.reset()
                try i.run(program: prog, arguments: [])
                try validatePromises(env: i.environment, promises: promises)
            } catch let error as CompileError {
                // This shouldn't happen but is really helpful if you write
                // tests that don't compile.
                XCTFail(error.getFullReport(sourcecode: source))
            } catch let error as CompileErrorMessage {
                // This shouldn't happen but is really helpful if you write
                // tests that don't compile.
                XCTFail(error.getFullReport(sourcecode: source))
            } catch let error as EnvironmentError {
                // So it might be that we want to access a variable but a
                // bug in the environment already deleted it.
                XCTFail(error.message)
            } catch let error as InterpreterTestError {
                // This are the errors we are interested in.
                XCTFail(error.message + "\n\nCode:\n" + source)
            }
        }
    }

    /// Rus a list of invalid tests that panic. Each test is a (String, Panic)
    /// tuple where the first string is the program and the second is the panic
    /// we expect when running the code.
    func runPanicTests(name: String, _ tests: [(String, Panic)]) throws {
        print("--- \(name)")
        for (i, t) in tests.enumerated() {
            let (source, expectedPanic) = t
            print("------\nStart Panic Test \(i): \n\(source)")

            do {
                let prog = try parseAndCheckProgram(source)
                let i = Interpreter.shared
                i.reset()
                try i.run(program: prog, arguments: [])
            } catch let error as CompileError {
                // This shouldn't happen but is really helpful if you write
                // tests that don't compile.
                XCTFail(error.getFullReport(sourcecode: source))
            } catch let error as CompileErrorMessage {
                // This shouldn't happen but is really helpful if you write
                // tests that don't compile.
                XCTFail(error.getFullReport(sourcecode: source))
            } catch let error as EnvironmentError {
                // So this shouldn't happen but it might because of a bug in
                // the interperter.
                XCTFail(error.message)
            } catch let actualPanic as Panic {
                if actualPanic.equals(other: expectedPanic) {
                    // everything is fine, lets continue with the next case
                    continue
                }
                XCTFail("I expected `\(expectedPanic)` but I got `\(actualPanic)`")
            }

            XCTFail("I expected `\(expectedPanic)` but the program didn't panic.")
        }
    }

    func runInValidTests(name: String, checkFor allowedErrors: Error.Type..., @InterpreterTestBuilder tests: () -> [(String, [(String, MooseObject)])]) throws {
        print("--- \(name)")
        for (i, t) in tests().enumerated() {
            let (source, promises) = t
            print("------\nStart Invalid \(i): \n\(source)")

            do {
                let prog = try parseAndCheckProgram(source)
                let i = Interpreter.shared
                i.reset()
                XCTAssertThrowsError(try i.run(program: prog, arguments: [])) { err in
                    if !allowedErrors.contains(where: { t in type(of: err) == t }) {
                        XCTFail(err.localizedDescription)
                    }
                }
                try validatePromises(env: i.environment, promises: promises)
            } catch let error as CompileError {
                // This shouldn't happen but is really helpful if you write
                // tests that don't compile.
                XCTFail(error.getFullReport(sourcecode: source))
            } catch let error as CompileErrorMessage {
                // This shouldn't happen but is really helpful if you write
                // tests that don't compile.
                XCTFail(error.getFullReport(sourcecode: source))
            } catch let error as EnvironmentError {
                // So it might be that we want to access a variable but a
                // bug in the environment already deleted it.
                XCTFail(error.message)
            } catch let error as InterpreterTestError {
                // This are the errors we are interested in.
                XCTFail(error.message + "\n\nCode:\n" + source)
            } catch let error as RuntimeError {
                XCTFail(error.message)
            }
        }
    }

    func runValidTests(name: String, @InterpreterTestBuilder _ tests: () -> [(String, [(String, MooseObject)])]) throws {
        try runValidTests(name: name, tests())
    }

    @resultBuilder
    enum InterpreterTestBuilder {
        typealias testCase = (String, [(String, MooseObject)])
        static func buildBlock(_ components: testCase...) -> [testCase] {
            components
        }
    }
}
