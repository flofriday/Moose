//
// Created by Johannes Zottele on 16.06.22.
//

import Foundation

protocol Node: CustomStringConvertible {
//    var tokenLiteral: Token { get }
    var getToken: Token { get }
}

protocol Statement: Node {}

protocol Expression: Node {}

protocol Assignable: Expression {
    var isAssignable: Bool { get }
}

class Program {
    let statements: [Statement]

    init(statements: [Statement]) {
        self.statements = statements
    }
}

class AssignStatement {
    init(token: Token, assignable: Expression, value: Expression, mutable: Bool, type: ValueType?) {
        self.token = token
        self.assignable = assignable
        self.value = value
        self.mutable = mutable
        self.type = type
    }

    let token: Token
    let assignable: Expression
    let value: Expression
    let mutable: Bool
    var type: ValueType?
}

class Identifier: Assignable {
    init(token: Token, value: String) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: String

    var isAssignable: Bool { true }
}

class ReturnStatement {
    init(token: Token, returnValue: Expression) {
        self.token = token
        self.returnValue = returnValue
    }

    let token: Token
    let returnValue: Expression
}

class ExpressionStatement {
    init(token: Token, expression: Expression) {
        self.token = token
        self.expression = expression
    }

    let token: Token // first token of expression
    let expression: Expression
}

class IntegerLiteral {
    init(token: Token, value: Int64) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: Int64
}

class Boolean {
    init(token: Token, value: Bool) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: Bool
}

class StringLiteral {
    init(token: Token, value: String) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: String
}

class Nil {
    init(token: Token) {
        self.token = token
    }

    let token: Token
}

class PrefixExpression {
    init(token: Token, op: String, right: Expression) {
        self.token = token
        self.op = op
        self.right = right
    }

    let token: Token
    let op: String // operator
    var right: Expression
}

class InfixExpression {
    init(token: Token, left: Expression, op: String, right: Expression) {
        self.token = token
        self.left = left
        self.op = op
        self.right = right
    }

    let token: Token
    let left: Expression
    let op: String
    let right: Expression
}

class PostfixExpression {
    init(token: Token, left: Expression, op: String) {
        self.token = token
        self.left = left
        self.op = op
    }

    let token: Token
    let left: Expression
    let op: String
}

class VariableDefinition {
    init(token: Token, mutable: Bool, name: Identifier, type: ValueType) {
        self.token = token
        self.mutable = mutable
        self.name = name
        self.type = type
    }

    let token: Token
    let mutable: Bool
    let name: Identifier
    let type: ValueType
}

class BlockStatement {
    init(token: Token, statements: [Statement]) {
        self.token = token
        self.statements = statements
    }

    let token: Token
    let statements: [Statement]
}

class FunctionStatement {
    init(token: Token, name: Identifier, body: BlockStatement, params: [VariableDefinition], returnType: ValueType?) {
        self.token = token
        self.name = name
        self.body = body
        self.params = params
        self.returnType = returnType
    }

    let token: Token
    let name: Identifier
    let body: BlockStatement
    let params: [VariableDefinition]
    let returnType: ValueType?
}

class CallExpression {
    init(token: Token, function: Identifier, arguments: [Expression]) {
        self.token = token
        self.function = function
        self.arguments = arguments
    }

    let token: Token
    let function: Identifier
    let arguments: [Expression]
}

class IfStatement {
    init(token: Token, condition: Expression, consequence: BlockStatement, alternative: BlockStatement?) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }

    let token: Token
    let condition: Expression
    let consequence: BlockStatement
    let alternative: BlockStatement?
}

class Tuple: Assignable {
    init(token: Token, expressions: [Expression]) {
        self.token = token
        self.expressions = expressions
    }

    let token: Token
    let expressions: [Expression]

    var isAssignable: Bool {
        return expressions.reduce(true) { prev, exp in
            guard exp is Identifier else {
                return false
            }
            return prev && true
        }
    }
}

// Node implementations

extension Program: Node {
    var getToken: Token {
        guard let f = statements.first else {
            return Token(type: .EOF, lexeme: "", line: 1, column: 0)
        }
        return f.getToken
    }

    var description: String {
        statements.map { $0.description }.joined(separator: "\n")
    }
}

extension AssignStatement: Statement {
    var getToken: Token { return token }
    var description: String {
        let mut = mutable ? "mut " : ""
        let type = type != nil ? ": \(type?.description ?? "")" : ""
        return "\(mut)\(assignable.description)\(type) = \(value.description)"
    }
}

extension Identifier: Expression {
    var getToken: Token { token }
    var description: String { value }
}

extension ReturnStatement: Statement {
    var getToken: Token { token }
    var description: String { "\(token.lexeme) \(returnValue.description)" }
}

extension ExpressionStatement: Statement {
    var getToken: Token { token }
    var description: String { expression.description }
}

extension IntegerLiteral: Expression {
    var getToken: Token { token }
    var description: String { token.lexeme }
}

extension Nil: Expression {
    var getToken: Token { token }
    var description: String { "nil" }
}

extension Boolean: Expression {
    var getToken: Token { token }
    var description: String { token.lexeme }
}

extension StringLiteral: Expression {
    var getToken: Token { token }
    var description: String { "\"\(token.lexeme)\"" }
}

extension Tuple: Expression {
    var getToken: Token { token }
    var description: String { "(\(expressions.map { $0.description }.joined(separator: ", ")))" }
}

extension PrefixExpression: Expression {
    var getToken: Token { token }
    var description: String { "(\(op)\(right.description))" }
}

extension InfixExpression: Expression {
    var getToken: Token { token }
    var description: String { "(\(left.description) \(op) \(right.description))" }
}

extension PostfixExpression: Expression {
    var getToken: Token { token }
    var description: String { "(\(left.description)\(op))" }
}

extension VariableDefinition: Node {
    var getToken: Token { token }
    var description: String { "\(name.value): \(type.description)" }
}

extension BlockStatement: Statement {
    var getToken: Token { token }
    var description: String { "{\(statements.map { $0.description }.joined(separator: ";"))}" }
}

extension FunctionStatement: Statement {
    var getToken: Token { token }
    var description: String {
        var out = "func \(name.value)"
        out += "(\(params.map { $0.description }.joined(separator: ", ")))"
        out += " > \(returnType?.description ?? "Void")"
        out += " \(body.description)"
        return out
    }
}

extension CallExpression: Expression {
    var getToken: Token { token }
    var description: String { "\(function.value)(\(arguments.map { $0.description }.joined(separator: ", ")))" }
}

extension IfStatement: Statement {
    var getToken: Token { token }
    var description: String {
        let base = "if \(condition.description) \(consequence.description)"
        guard let alt = alternative else {
            return base
        }
        return base + "else \(alt.description)"
    }
}

// ---- Value Type -----

indirect enum ValueType {
    case Identifier(ident: Identifier)
    case Tuple(types: [ValueType])
    case Function(params: [ValueType], returnType: ValueType)
    case Void
}

extension ValueType: CustomStringConvertible {
    var description: String {
        switch self {
        case .Identifier(ident: let i):
            return i.description
        case .Tuple(types: let ids):
            return "(\(ids.map { $0.description }.joined(separator: ", ")))"
        case .Function(params: let params, returnType: let returnType):
            return "(\(params.map { $0.description }.joined(separator: ", "))) > \(returnType.description)"
        case .Void:
            return "()"
        }
    }
}
