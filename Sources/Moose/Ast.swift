//
// Created by Johannes Zottele on 16.06.22.
//

import Foundation

protocol Visitor {
    func visit(_ node: Program) throws
    func visit(_ node: AssignStatement) throws
    func visit(_ node: ReturnStatement) throws
    func visit(_ node: ExpressionStatement) throws
    func visit(_ node: BlockStatement) throws
    func visit(_ node: FunctionStatement) throws
    func visit(_ node: IfStatement) throws

    func visit(_ node: Identifier) throws
    func visit(_ node: IntegerLiteral) throws
    func visit(_ node: Boolean) throws
    func visit(_ node: StringLiteral) throws
    func visit(_ node: PrefixExpression) throws
    func visit(_ node: InfixExpression) throws
    func visit(_ node: PostfixExpression) throws
    func visit(_ node: VariableDefinition) throws
    func visit(_ node: Tuple) throws
    func visit(_ node: Nil) throws
    func visit(_ node: CallExpression) throws
    func visit(_ node: ValueType) throws
}

protocol Node: CustomStringConvertible {
    var tokenLiteral: Any? { get }
    var tokenLexeme: String { get }

    func accept(_ visitor: Visitor) throws

    // string representation of node
//    var description: String { get }
}

protocol Statement: Node {
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
    var mooseType: MooseType?
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
    var mooseType: MooseType?
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
        statements.map {
                    $0.description
                }
                .joined(separator: "\n")
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension AssignStatement: Statement {
    var tokenLiteral: Any? {
        return token.literal
    }
    var tokenLexeme: String {
        return token.lexeme
    }
    var description: String {
        let mut = mutable ? "mut " : ""
        let type = type != nil ? ": \(type?.description ?? "")" : ""
        return "\(mut)\(assignable.description)\(type) = \(value.description)"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension Identifier: Expression {

    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        value
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension ReturnStatement: Statement {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "\(tokenLexeme) \(returnValue.description)"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension ExpressionStatement: Statement {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        expression.description
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension IntegerLiteral: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        token.lexeme
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension Nil: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "nil"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension Boolean: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        token.lexeme
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension StringLiteral: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "\"\(token.lexeme)\""
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension Tuple: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "(\(expressions.map { $0.description }.joined(separator: ", ")))"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension PrefixExpression: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "(\(op)\(right.description))"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension InfixExpression: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "(\(left.description) \(op) \(right.description))"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension PostfixExpression: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "(\(left.description)\(op))"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension VariableDefinition: Node {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "\(name.value): \(type.description)"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension BlockStatement: Statement {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "{\(statements.map { $0.description }.joined(separator: ";"))}"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension FunctionStatement: Statement {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        var out = "func \(name.value)"
        out += "(\(params.map { $0.description }.joined(separator: ", ")))"
        out += " > \(returnType?.description ?? "Void")"
        out += " \(body.description)"
        return out
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension CallExpression: Expression {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        "\(function.value)(\(arguments.map { $0.description }.joined(separator: ", ")))"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}

extension IfStatement: Statement {
    var tokenLiteral: Any? {
        token.literal
    }
    var tokenLexeme: String {
        token.lexeme
    }
    var description: String {
        let base = "if \(condition.description) \(consequence.description)"
        guard let alt = alternative else {
            return base
        }
        return base + "else \(alt.description)"
    }

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
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

    func accept(_ visitor: Visitor) throws {
        try visitor.visit(self)
    }
}
