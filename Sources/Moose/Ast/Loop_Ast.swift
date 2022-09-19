//
//  File.swift
//
//
//  Created by Johannes Zottele on 16.08.22.
//

import Foundation

/// ast for `for a in arr {}`
class ForEachStatement: Statement {
    let token: Token
    let list: Expression
    // the variable could be a simple variable or an tuple.
    // We need to check that the tuple only contains variables
    let variable: Assignable
    let body: BlockStatement

    var returnDeclarations: ReturnDec = nil

    init(token: Token, variable: Assignable, list: Expression, body: BlockStatement) {
        self.token = token
        self.list = list
        self.variable = variable
        self.body = body
    }

    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }

    var description: String {
        return "for \(variable.description) in \(list.description) \(body)"
    }

    var location: Location {
        return Location(token.location, body.location)
    }
}

/// ast for `for mut a = 2; a > 2; a++ {}`
class ForCStyleStatement: Statement {
    let token: Token
    let preStmt: Statement?
    let condition: Expression
    let postEachStmt: Statement?
    let body: BlockStatement

    var returnDeclarations: ReturnDec = nil

    init(token: Token, preStmt: Statement?, condition: Expression, postEachStmt: Statement?, body: BlockStatement) {
        self.token = token
        self.preStmt = preStmt
        self.condition = condition
        self.postEachStmt = postEachStmt
        self.body = body
    }

    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }

    var description: String {
        let preStmt = (preStmt != nil) ? "\(preStmt!); " : ""
        let postStmt = (postEachStmt != nil) ? "; \(postEachStmt!)" : ""
        return "for \(preStmt)\(condition)\(postStmt) \(body)"
    }

    var location: Location {
        return Location(token.location, body.location)
    }
}
