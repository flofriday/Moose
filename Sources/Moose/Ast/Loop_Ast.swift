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
    let variable: Identifier
    let body: BlockStatement

    var returnDeclarations: ReturnDec = nil

    init(token: Token, variable: Identifier, list: Expression, body: BlockStatement) {
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
}

/// ast for `for mut a = 2; a > 2; a++ {}`
class ForCStyleStatement: Statement {
    let token: Token
    let preStmt: Statement?
    let condition: Expression
    let postEachStmt: Statement?
    let body: BlockStatement

    var returnDeclarations: ReturnDec = nil

    init(token: Token, preStmt: Statement?, condition: Expression, postEachSmt: Statement?, body: BlockStatement) {
        self.token = token
        self.preStmt = preStmt
        self.condition = condition
        self.postEachStmt = postEachSmt
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
}
