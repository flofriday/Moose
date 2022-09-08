//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

protocol Visitor {
    associatedtype VisitorResult

    func visit(_ node: Program) throws -> VisitorResult
    func visit(_ node: AssignStatement) throws -> VisitorResult
    func visit(_ node: ReturnStatement) throws -> VisitorResult
    func visit(_ node: ExpressionStatement) throws -> VisitorResult
    func visit(_ node: BlockStatement) throws -> VisitorResult
    func visit(_ node: FunctionStatement) throws -> VisitorResult
    func visit(_ node: IfStatement) throws -> VisitorResult

    func visit(_ node: Identifier) throws -> VisitorResult
    func visit(_ node: IntegerLiteral) throws -> VisitorResult
    func visit(_ node: FloatLiteral) throws -> VisitorResult
    func visit(_ node: Boolean) throws -> VisitorResult
    func visit(_ node: StringLiteral) throws -> VisitorResult
    func visit(_ node: PrefixExpression) throws -> VisitorResult
    func visit(_ node: InfixExpression) throws -> VisitorResult
    func visit(_ node: PostfixExpression) throws -> VisitorResult
    func visit(_ node: VariableDefinition) throws -> VisitorResult
    func visit(_ node: Tuple) throws -> VisitorResult
    func visit(_ node: Nil) throws -> VisitorResult
    func visit(_ node: Me) throws -> VisitorResult
    func visit(_ node: Is) throws -> VisitorResult
    func visit(_ node: Break) throws -> VisitorResult
    func visit(_ node: Continue) throws -> VisitorResult
    func visit(_ node: CallExpression) throws -> VisitorResult
    func visit(_ node: OperationStatement) throws -> VisitorResult
    func visit(_ node: ClassStatement) throws -> VisitorResult
    func visit(_ node: Dereferer) throws -> VisitorResult
    func visit(_ node: List) throws -> VisitorResult
    func visit(_ node: Dict) throws -> VisitorResult
    func visit(_ node: IndexExpression) throws -> VisitorResult
    func visit(_ node: ForEachStatement) throws -> VisitorResult
    func visit(_ node: ForCStyleStatement) throws -> VisitorResult
}

class BaseVisitor: Visitor {
    private let errorMessage: String

    init(_ errorMessage: String? = nil) {
        self.errorMessage = errorMessage ?? "NOT IMPEMENTED: Visitor for this node not implemented!"
    }

    func visit(_: Program) throws {
        fatalError(errorMessage)
    }

    func visit(_: AssignStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: ReturnStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: ExpressionStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: BlockStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: FunctionStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: IfStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: Identifier) throws {
        fatalError(errorMessage)
    }

    func visit(_: IntegerLiteral) throws {
        fatalError(errorMessage)
    }

    func visit(_: FloatLiteral) throws {
        fatalError(errorMessage)
    }

    func visit(_: Boolean) throws {
        fatalError(errorMessage)
    }

    func visit(_: StringLiteral) throws {
        fatalError(errorMessage)
    }

    func visit(_: PrefixExpression) throws {
        fatalError(errorMessage)
    }

    func visit(_: InfixExpression) throws {
        fatalError(errorMessage)
    }

    func visit(_: PostfixExpression) throws {
        fatalError(errorMessage)
    }

    func visit(_: VariableDefinition) throws {
        fatalError(errorMessage)
    }

    func visit(_: Tuple) throws {
        fatalError(errorMessage)
    }

    func visit(_: Nil) throws {
        fatalError(errorMessage)
    }

    func visit(_: Me) throws {
        fatalError(errorMessage)
    }

    func visit(_: Is) throws {
        fatalError(errorMessage)
    }

    func visit(_: Break) throws {
        fatalError(errorMessage)
    }

    func visit(_: Continue) throws {
        fatalError(errorMessage)
    }

    func visit(_: CallExpression) throws {
        fatalError(errorMessage)
    }

    func visit(_: OperationStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: Dereferer) throws {
        fatalError(errorMessage)
    }

    func visit(_: ClassStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: List) throws {
        fatalError(errorMessage)
    }

    func visit(_: Dict) throws {
        fatalError(errorMessage)
    }

    func visit(_: IndexExpression) throws {
        fatalError(errorMessage)
    }

    func visit(_: ForEachStatement) throws {
        fatalError(errorMessage)
    }

    func visit(_: ForCStyleStatement) throws {
        fatalError(errorMessage)
    }
}
