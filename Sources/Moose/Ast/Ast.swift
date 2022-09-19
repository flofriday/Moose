//
// Created by Johannes Zottele on 16.06.22.
//

import Foundation

protocol Node: CustomStringConvertible {
    var token: Token { get }
    var location: Location { get }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R
}

protocol Statement: Node {
    typealias ReturnDec = (MooseType, Bool)? // (type of returns, if all possible branches return)
    var returnDeclarations: ReturnDec { get set }
}

protocol Expression: Node {
    var mooseType: MooseType? { get set }
}

/// All nodes that can be on the left side of an assignment.
///
/// E.g. `ident =`, `arr[0] =`, `obj.prop =`
protocol Assignable: Expression {
    var isAssignable: Bool { get }
    var assignables: [Assignable] { get }
}

class Program {
    let statements: [Statement]

    init(statements: [Statement]) {
        self.statements = statements
    }
}

class AssignStatement {
    init(token: Token, location: Location, assignable: Assignable, value: Expression, mutable: Bool, type: MooseType?) {
        self.token = token
        self.location = location
        self.assignable = assignable
        self.value = value
        self.mutable = mutable
        declaredType = type
    }

    let token: Token
    let location: Location
    let assignable: Assignable
    let value: Expression
    let mutable: Bool
    var declaredType: MooseType?
    var returnDeclarations: (MooseType, Bool)?
}

class Identifier: Assignable {
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

    var assignables: [Assignable] {
        [self]
    }
}

/// Represents the `me` keyword (same as `this` in java or `self` in swift)
class Me {
    let token: Token
    var mooseType: MooseType?

    init(token: Token) {
        self.token = token
    }
}

class Is {
    let token: Token
    let expression: Expression
    let type: Identifier

    var mooseType: MooseType?

    init(token: Token, expression: Expression, type: Identifier) {
        self.token = token
        self.expression = expression
        self.type = type
    }
}

class Break {
    let token: Token
    var returnDeclarations: ReturnDec

    init(token: Token) {
        self.token = token
        returnDeclarations = nil
    }
}

class Continue {
    let token: Token
    var returnDeclarations: ReturnDec

    init(token: Token) {
        self.token = token
        returnDeclarations = nil
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

class TernaryExpression {
    let token: Token
    let condition: Expression
    let consequence: Expression
    let alternative: Expression
    var mooseType: MooseType?

    init(token: Token, condition: Expression, consequence: Expression, alternative: Expression) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }
}

class VariableDefinition {
    init(token: Token, location: Location, mutable: Bool, name: Identifier, type: ParamType) {
        self.token = token
        self.location = location
        self.mutable = mutable
        self.name = name
        declaredType = type
    }

    let token: Token
    let location: Location
    let mutable: Bool
    let name: Identifier
    let declaredType: ParamType
    var mooseType: MooseType?
    var returnDeclaration: (MooseType, Bool) {
        (self.declaredType, true)
    }
}

class BlockStatement {
    init(token: Token, location: Location, statements: [Statement]) {
        self.token = token
        self.location = location
        self.statements = statements
    }

    let token: Token
    let location: Location
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
    init(token: Token, location: Location, function: Identifier, arguments: [Expression]) {
        self.token = token
        self.location = location
        self.function = function
        self.arguments = arguments
    }

    let token: Token
    let location: Location
    let function: Identifier
    let arguments: [Expression]
    var mooseType: MooseType?

    /// Is changed by typechecker if it is constructor call
    var isConstructorCall: Bool = false
}

class IfStatement {
    init(token: Token, condition: Expression, consequence: BlockStatement, alternative: Statement?) {
        self.token = token
        self.condition = condition
        self.consequence = consequence
        self.alternative = alternative
    }

    let token: Token
    let condition: Expression
    let consequence: BlockStatement
    let alternative: Statement?
    var returnDeclarations: (MooseType, Bool)?
}

class Tuple: Assignable {
    init(token: Token, location: Location, expressions: [Expression]) {
        self.token = token
        self.location = location
        self.expressions = expressions
    }

    let token: Token
    let location: Location
    let expressions: [Expression]
    var mooseType: MooseType?

    var isAssignable: Bool {
        return expressions.reduce(true) { prev, exp in
            guard let exp = exp as? Assignable else {
                return false
            }
            return prev && exp.isAssignable
        }
    }

    var assignables: [Assignable] {
        expressions.compactMap {
            ($0 as? Assignable)?.assignables
        }.flatMap { $0 }
    }
}

class ClassStatement {
    let token: Token
    let location: Location
    let name: Identifier
    let properties: [VariableDefinition]
    let methods: [FunctionStatement]
    let extends: Identifier?

    init(token: Token, location: Location, name: Identifier, properties: [VariableDefinition], methods: [FunctionStatement], extends: Identifier? = nil) {
        self.token = token
        self.location = location
        self.name = name
        self.properties = properties
        self.methods = methods
        self.extends = extends
    }

    var returnDeclarations: (MooseType, Bool)?

    var hasRepresentMethod: Bool {
        return methods.contains { $0.name.value == Settings.REPRESENT_FUNCTIONNAME }
    }
}

class ExtendStatement {
    let token: Token
    let location: Location
    let name: Identifier
    let methods: [FunctionStatement]

    init(token: Token, location: Location, name: Identifier, methods: [FunctionStatement]) {
        self.token = token
        self.location = location
        self.name = name
        self.methods = methods
    }

    var returnDeclarations: (MooseType, Bool)?
}

/// This class represents the `.` in `object.propertie`
class Dereferer: Assignable {
    let token: Token
    var mooseType: MooseType?

    let obj: Expression
    let referer: Expression

    init(token: Token, obj: Expression, referer: Expression) {
        self.token = token
        self.obj = obj
        self.referer = referer
    }

    var isAssignable: Bool {
        guard let referer = referer as? Assignable else {
            return false
        }
        return referer.isAssignable
    }

    var assignables: [Assignable] {
        return [self]
    }
}

// Node implementations

extension Program: Node {
    var token: Token {
        guard let f = statements.first else {
            return Token(type: .EOF, lexeme: "", location: Location(col: 1, endCol: 1, line: 1, endLine: 1))
        }
        return f.token
    }

    var location: Location {
        guard let first = statements.first, let last = statements.last else {
            return Location(col: 0, endCol: 0, line: 0, endLine: 0)
        }

        return Location(first.location, last.location)
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
    var description: String { value }

    var location: Location {
        token.location
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension Me: Expression {
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }

    var description: String { "me" }

    var location: Location {
        token.location
    }
}

extension Is: Expression {
    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }

    var description: String { "(\(expression) is \(type))" }

    var location: Location {
        return token.location
    }
}

extension Break: Statement {
    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }

    var description: String { "break" }

    var location: Location {
        return token.location
    }
}

extension Continue: Statement {
    func accept<V, R>(_ visitor: V) throws -> R where V: Visitor, R == V.VisitorResult {
        try visitor.visit(self)
    }

    var description: String { "break" }

    var location: Location {
        return token.location
    }
}

extension ReturnStatement: Statement {
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }

    var description: String { "\(token.lexeme) \(returnValue?.description ?? "")" }

    var location: Location {
        let tokenLocation = token.location
        guard let expr = returnValue else {
            return tokenLocation
        }

        return Location(tokenLocation, expr.location)
    }
}

extension ExpressionStatement: Statement {
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }

    var description: String { expression.description }

    var location: Location { expression.location }
}

extension IntegerLiteral: Expression {
    var description: String { token.lexeme }

    var location: Location { token.location }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension FloatLiteral: Expression {
    var description: String { token.lexeme }

    var location: Location { token.location }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension Nil: Expression {
    var description: String { "nil" }

    var location: Location { token.location }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension Boolean: Expression {
    var description: String { token.lexeme }

    var location: Location { token.location }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension StringLiteral: Expression {
    var description: String { "\"\(token.lexeme)\"" }

    var location: Location { token.location }

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

    var location: Location { Location(token.location, right.location) }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension InfixExpression: Expression {
    var description: String { "(\(left.description) \(op) \(right.description))" }

    var location: Location { Location(left.location, right.location) }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension PostfixExpression: Expression {
    var description: String { "(\(left.description)\(op))" }
    var location: Location { Location(left.location, token.location) }
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension TernaryExpression: Expression {
    var description: String { "\(condition.description) ? \(consequence.description) : \(alternative.description)" }

    var location: Location { Location(condition.location, alternative.location) }

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

    var location: Location {
        Location(token.location, body.location)
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

    var location: Location {
        Location(token.location, body.location)
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

    var location: Location {
        let tokenLocation = token.location
        if let alternative = alternative {
            return Location(tokenLocation, alternative.location)
        } else {
            return Location(tokenLocation, consequence.location)
        }
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        try visitor.visit(self)
    }
}

extension ClassStatement: Statement {
    var description: String {
        let props = properties.map { "\n \($0.description)" }.joined()
        let methods = self.methods.map { "\n \($0.description)" }.joined()
        let ext = extends != nil ? " < \(extends!.value)" : ""
        return "class \(name.value)\(ext) { \(props)\n \(methods)}"
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        return try visitor.visit(self)
    }
}

extension ExtendStatement: Statement {
    var description: String {
        let methods = self.methods.map { "\n \($0.description)" }.joined()
        return "extend \(name.value) { \(methods) }"
    }

    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        return try visitor.visit(self)
    }
}

extension Dereferer: Expression {
    func accept<V: Visitor, R>(_ visitor: V) throws -> R where V.VisitorResult == R {
        return try visitor.visit(self)
    }

    var description: String {
        "\(obj.description).\(referer.description)"
    }

    var location: Location {
        return Location(obj.location, referer.location)
    }
}
