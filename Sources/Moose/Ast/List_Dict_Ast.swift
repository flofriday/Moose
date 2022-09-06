//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation

class List {
    let token: Token
    let location: Location
    let expressions: [Expression]
    var mooseType: MooseType?

    init(token: Token, location: Location, expressions: [Expression]) {
        self.token = token
        self.location = location
        self.expressions = expressions
    }
}

class Dict {
    typealias dictPairs = [(key: Expression, value: Expression)]

    let token: Token
    let location: Location
    let pairs: dictPairs

    var mooseType: MooseType?

    init(token: Token, location: Location, pairs: dictPairs) {
        self.token = token
        self.location = location
        self.pairs = pairs
    }
}

class IndexExpression: Assignable {
    let token: Token
    let location: Location
    let indexable: Expression // left
    let index: Expression
    var mooseType: MooseType?

    init(token: Token, location: Location, indexable: Expression, index: Expression) {
        self.token = token
        self.location = location
        self.indexable = indexable
        self.index = index
    }

    var isAssignable: Bool {
        true
    }

    var assignables: [Assignable] {
        return [self]
    }
}

extension List: Expression {
    var description: String { "[\(expressions.map { $0.description }.joined(separator: ", "))]" }
    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }
}

extension Dict: Expression {
    var description: String {
        "{\(pairs.map { "\($0.key.description): \($0.value.description)" }.joined(separator: ", "))}"
    }

    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }
}

extension IndexExpression: Expression {
    var description: String { "\(indexable.description)[\(index)]" }
    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }
}
