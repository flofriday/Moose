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
                try i.run(program: prog)
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

    // func runInvalidTests(name: String, @StringArrayBuilder _ tests: () -> [String]) throws {
    //     try runInvalidTests(name: name, tests())
    // }
}
