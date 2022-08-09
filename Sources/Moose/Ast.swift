//
// Created by Johannes Zottele on 16.06.22.
//

import Foundation

protocol Node: CustomStringConvertible {
    var token: Token { get }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R
}

protocol Statement: Node {
    typealias ReturnDec = (MooseType, Bool)? // (type of returns, if all possible branches return)
    var returnDeclarations: ReturnDec { get set }
}

protocol Expression: Node {
    var mooseType: MooseType? { get set }
}

protocol Assignable: Expression {
    var isAssignable: Bool { get }
}

protocol Declareable: Assignable {
    var idents: [Identifier] { get }
}

class Program {
    let statements: [Statement]

    init(statements: [Statement]) {
        self.statements = statements
    }
}

class AssignStatement {
    init(token: Token, assignable: Assignable, value: Expression, mutable: Bool, type: MooseType?) {
        self.token = token
        self.assignable = assignable
        self.value = value
        self.mutable = mutable
        declaredType = type
    }

    let token: Token
    let assignable: Assignable
    let value: Expression
    let mutable: Bool
    var declaredType: MooseType?
    var returnDeclarations: (MooseType, Bool)?
}

class Identifier: Assignable, Declareable {
    init(token: Token, value: String) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: String
    var mooseType: MooseType?

    var isAssignable: Bool {
        true
    }

    var idents: [Identifier] {
        [self]
    }
}

class ReturnStatement {
    init(token: Token, returnValue: Expression?) {
        self.token = token
        self.returnValue = returnValue
    }

    let token: Token
    let returnValue: Expression?
    var returnDeclarations: (MooseType, Bool)?
}

class ExpressionStatement {
    init(token: Token, expression: Expression) {
        self.token = token
        self.expression = expression
    }

    let token: Token // first token of expression
    let expression: Expression
    var returnDeclarations: (MooseType, Bool)?
}

class IntegerLiteral {
    init(token: Token, value: Int64) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: Int64
    var mooseType: MooseType?
}

class FloatLiteral {
    init(token: Token, value: Float64) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: Float64
    var mooseType: MooseType?
}

class Boolean {
    init(token: Token, value: Bool) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: Bool
    var mooseType: MooseType?
}

class StringLiteral {
    init(token: Token, value: String) {
        self.token = token
        self.value = value
    }

    let token: Token
    let value: String
    var mooseType: MooseType?
}

class Nil {
    init(token: Token) {
        self.token = token
    }

    let token: Token
    var mooseType: MooseType?
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
    var mooseType: MooseType?
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
    var mooseType: MooseType?
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
    var mooseType: MooseType?
}

class VariableDefinition {
    init(token: Token, mutable: Bool, name: Identifier, type: MooseType) {
        self.token = token
        self.mutable = mutable
        self.name = name
        declaredType = type
    }

    let token: Token
    let mutable: Bool
    let name: Identifier
    let declaredType: MooseType
    var mooseType: MooseType?
    var returnDeclaration: (MooseType, Bool) {
        (self.declaredType, true)
    }
}

class BlockStatement {
    init(token: Token, statements: [Statement]) {
        self.token = token
        self.statements = statements
    }

    let token: Token
    let statements: [Statement]
    var returnDeclarations: (MooseType, Bool)?
}

class FunctionStatement {
    init(token: Token, name: Identifier, body: BlockStatement, params: [VariableDefinition], returnType: MooseType) {
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
    let returnType: MooseType
    var mooseType: MooseType?
    var returnDeclarations: (MooseType, Bool)?
}

class OperationStatement {
    init(token: Token, name: String, position: OpPos, body: BlockStatement, params: [VariableDefinition], returnType: MooseType) {
        self.token = token
        self.name = name
        self.position = position
        self.body = body
        self.params = params
        self.returnType = returnType
    }

    let token: Token // operator token
    let name: String
    let position: OpPos
    let body: BlockStatement
    let params: [VariableDefinition]
    let returnType: MooseType
    var mooseType: MooseType?
    var returnDeclarations: (MooseType, Bool)?
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
    var mooseType: MooseType?
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
    var returnDeclarations: (MooseType, Bool)?
}

class Tuple: Assignable, Declareable {
    init(token: Token, expressions: [Expression]) {
        self.token = token
        self.expressions = expressions
    }

    let token: Token
    let expressions: [Expression]
    var mooseType: MooseType?

    var isAssignable: Bool {
        return expressions.reduce(true) { prev, exp in
            guard exp is Identifier else {
                return false
            }
            return prev && true
        }
    }

    var idents: [Identifier] {
        expressions.map {
            $0 as! Identifier
        }
    }
}

class ClassStatement {
    let token: Token
    let name: Identifier
    let properties: [VariableDefinition]
    let methods: [FunctionStatement]

    init(token: Token, name: Identifier, properties: [VariableDefinition], methods: [FunctionStatement]) {
        self.token = token
        self.name = name
        self.properties = properties
        self.methods = methods
    }

    var returnDeclarations: (MooseType, Bool)?
}

// Node implementations

extension Program: Node {
    var token: Token {
        guard let f = statements.first else {
            return Token(type: .EOF, lexeme: "", line: 1, column: 0)
        }
        return f.token
    }

    var description: String {
        statements.map {
            $0.description
        }
        .joined(separator: "\n")
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension AssignStatement: Statement {
    var description: String {
        let mut = mutable ? "mut " : ""
        let type = declaredType != nil ? ": \(declaredType?.description ?? "")" : ""
        return "\(mut)\(assignable.description)\(type) = \(value.description)"
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension Identifier: Expression {
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }

    var description: String { value }
}

extension ReturnStatement: Statement {
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }

    var description: String { "\(token.lexeme) \(returnValue?.description ?? "")" }
}

extension ExpressionStatement: Statement {
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }

    var description: String { expression.description }
}

extension IntegerLiteral: Expression {
    var description: String { token.lexeme }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension FloatLiteral: Expression {
    var description: String { token.lexeme }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension Nil: Expression {
    var description: String { "nil" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension Boolean: Expression {
    var description: String { token.lexeme }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension StringLiteral: Expression {
    var description: String { "\"\(token.lexeme)\"" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension Tuple: Expression {
    var description: String { "(\(expressions.map { $0.description }.joined(separator: ", ")))" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension PrefixExpression: Expression {
    var description: String { "(\(op)\(right.description))" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension InfixExpression: Expression {
    var description: String { "(\(left.description) \(op) \(right.description))" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension PostfixExpression: Expression {
    var description: String { "(\(left.description)\(op))" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension VariableDefinition: Node {
    var description: String { "\(mutable ? "mut " : "")\(name.value): \(declaredType.description)" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension BlockStatement: Statement {
    var description: String { "{\(statements.map { $0.description }.joined(separator: ";"))}" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension FunctionStatement: Statement {
    var description: String {
        var out = "func \(name.value)"
        out += "(\(params.map { $0.description }.joined(separator: ", ")))"
        out += " > \(returnType.description)"
        out += " \(body.description)"
        return out
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension OperationStatement: Statement {
    var description: String {
        var out = "\(position.description) \(name) "
        out += "(\(params.map { $0.description }.joined(separator: ", ")))"
        out += " > \(returnType.description)"
        out += " \(body.description)"
        return out
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension CallExpression: Expression {
    var description: String { "\(function.value)(\(arguments.map { $0.description }.joined(separator: ", ")))" }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension IfStatement: Statement {
    var description: String {
        let base = "if \(condition.description) \(consequence.description)"
        guard let alt = alternative else {
            return base
        }
        return base + "else \(alt.description)"
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension ClassStatement: Statement {
    var description: String {
        let props = properties.map { "\n \($0.description)" }.joined()
        let methods = self.methods.map { "\n \($0.description)" }.joined()
        return "class \(name.value) { \(props)\n \(methods)}"
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        return try visitor.visit(self)
    }
}
