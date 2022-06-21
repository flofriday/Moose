//
// Created by Johannes Zottele on 16.06.22.
//

import Foundation

protocol Node: CustomStringConvertible {
    var tokenLiteral: Any? { get }
    var tokenLexeme: String { get }

    // string representation of node
//    var description: String { get }
}

protocol Statement: Node {}

protocol Expression: Node {}

struct Program {
    let statements: [Statement]

    init(statements: [Statement]) {
        self.statements = statements
    }
}

struct AssignStatement {
    let token: Token
    let name: Identifier
    let value: Expression
    let mutable: Bool
    var type: ValueType?
}

struct Identifier {
    let token: Token
    let value: String
}

struct ReturnStatement {
    let token: Token
    let returnValue: Expression
}

struct ExpressionStatement {
    let token: Token // first token of expression
    let expression: Expression
}

struct IntegerLiteral {
    let token: Token
    let value: Int64
}

struct Boolean {
    let token: Token
    let value: Bool
}

struct StringLiteral {
    let token: Token
    let value: String
}

struct PrefixExpression {
    let token: Token
    let op: String // operator
    var right: Expression
}

struct InfixExpression {
    let token: Token
    let left: Expression
    let op: String
    let right: Expression
}

struct PostfixExpression {
    let token: Token
    let left: Expression
    let op: String
}

struct VariableDefinition {
    let token: Token
    let mutable: Bool
    let name: Identifier
    let type: ValueType
}

struct FunctionStatement {
    let token: Token
    let name: Identifier
    let body: [Statement]
    let paremeters: [VariableDefinition]
    let returnType: ValueType?
}

// Node implementations

extension Program: Node {
    var tokenLiteral: Any? {
        guard statements.count > 0 else {
            return nil
        }
        return statements[0].tokenLiteral
    }

    var tokenLexeme: String {
        guard statements.count > 0 else {
            return ""
        }
        return statements[0].tokenLexeme
    }

    var description: String {
        statements.map { $0.description }.joined(separator: "\n")
    }
}

extension AssignStatement: Statement {
    var tokenLiteral: Any? { return token.literal }
    var tokenLexeme: String { return token.lexeme }
    var description: String {
        let mut = mutable ? "mut " : ""
        return "\(mut)\(name.description) = \(value.description)"
    }
}

extension Identifier: Expression {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { value }
}

extension ReturnStatement: Statement {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { "\(tokenLexeme) \(returnValue.description)" }
}

extension ExpressionStatement: Statement {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { expression.description }
}

extension IntegerLiteral: Expression {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { token.lexeme }
}

extension Boolean: Expression {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { token.lexeme }
}

extension StringLiteral: Expression {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { token.lexeme }
}

extension PrefixExpression: Expression {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { "(\(op)\(right.description))" }
}

extension InfixExpression: Expression {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { "(\(left.description) \(op) \(right.description))" }
}

extension PostfixExpression: Expression {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { "(\(left.description)\(op))" }
}

extension VariableDefinition: Node {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String { "\(name.value): \(type.description)" }
}

extension FunctionStatement: Statement {
    var tokenLiteral: Any? { token.literal }
    var tokenLexeme: String { token.lexeme }
    var description: String {
        var out = "func \(name.value)"
        out += "(\(paremeters.map { $0.description }.joined(separator: ", ")))"
        out += " -> \(returnType?.description ?? "Void")"
        out += " {\(body.map { $0.description }.joined(separator: ";"))"
        return out
    }
}

enum ValueType {
    case Identifier(ident: Identifier)
    case Tuple(types: [ValueType])
}

extension ValueType: CustomStringConvertible {
    var description: String {
        switch self {
        case .Identifier(ident: let i):
            return i.description
        case .Tuple(types: let ids):
            return "(\(ids.map { $0.description }.joined(separator: ", ")))"
        }
    }
}
