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
}
