//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
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
    func visit(_ node: OperationStatement) throws
    func visit(_ node: ClassStatement) throws
}

class BaseVisitor: Visitor {
    private let errorMessage: String

    init(_ errorMessage: String? = nil) {
        self.errorMessage = errorMessage ?? "NOT IMPEMENTED: Visitor for this node not implemented!"
    }
    
    func visit(_ node: Program) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: AssignStatement) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: ReturnStatement) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: ExpressionStatement) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: BlockStatement) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: FunctionStatement) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: IfStatement) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: Identifier) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: IntegerLiteral) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: Boolean) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: StringLiteral) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: PrefixExpression) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: InfixExpression) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: PostfixExpression) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: VariableDefinition) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: Tuple) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: Nil) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: CallExpression) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: OperationStatement) throws {
        fatalError(errorMessage)
    }
    
    func visit(_ node: ClassStatement) throws {
        fatalError(errorMessage)
    }
}
