//
// Created by flofriday on 28.06.22.
//

import Foundation


// A simple class that finds the position of an expression
// Note: This is not an optimal solution and will have a lot of off by one errors
// but it is an improvement over just one token from an expression.
// The correct solution would be to include positions into the AST nodes.
class AstLocator: Visitor {

    var location: Location
    let node: Node

    init(node: Node) {
        location = Location(
                col: node.token.column,
                endCol: node.token.column + node.token.lexeme.count,
                line: node.token.line,
                endLine: node.token.line
        )
        self.node = node
    }

    func getLocation() -> Location {
        // In this class it can never throw.
        do {
            try node.accept(self)
        } catch {
        }

        return location
    }

    func update(_ node: Node) {
        let token = node.token
        let newCol = token.column
        let newEndCol = token.column + token.lexeme.count
        let newLine = token.line

        if newLine <= location.line, newCol < location.col {
            location.col = newCol
        }

        if newLine >= location.endLine, newEndCol > location.endCol {
            location.endCol = newEndCol
        }

        location.line = min(location.line, newLine)
        location.endLine = min(location.endLine, newLine)
    }

    func visit(_ node: Program) throws {
        guard node.statements.count > 0 else {
            return
        }

        try node.statements.first!.accept(self)
        try node.statements.last!.accept(self)
    }

    func visit(_ node: AssignStatement) throws {
        try node.assignable.accept(self)
        try node.value.accept(self)
    }

    func visit(_ node: ReturnStatement) throws {
        update(node)

        if let returnValue = node.returnValue {
            try returnValue.accept(self)
        }
    }

    func visit(_ node: ExpressionStatement) throws {
        try node.expression.accept(self)
    }

    func visit(_ node: BlockStatement) throws {
        guard node.statements.count > 0 else {
            return
        }

        try node.statements.first!.accept(self)
        try node.statements.last!.accept(self)
    }

    func visit(_ node: FunctionStatement) throws {
        update(node)

        for param in node.params {
            try param.accept(self)
        }
        try node.body.accept(self)
    }

    func visit(_ node: IfStatement) throws {
        update(node)

        try node.condition.accept(self)
        try node.consequence.accept(self)
        if let alternative = node.alternative {
            try alternative.accept(self)
        }
    }

    func visit(_ node: Identifier) throws {
        update(node)
    }

    func visit(_ node: IntegerLiteral) throws {
        update(node)
    }

    func visit(_ node: Boolean) throws {
        update(node)
    }

    func visit(_ node: StringLiteral) throws {
        update(node)
    }

    func visit(_ node: PrefixExpression) throws {
        update(node)
        try node.right.accept(self)
    }

    func visit(_ node: InfixExpression) throws {
        try node.left.accept(self)
        try node.right.accept(self)
    }

    func visit(_ node: PostfixExpression) throws {
        update(node)
        try node.left.accept(self)
    }

    func visit(_ node: VariableDefinition) throws {
        update(node)
        try node.name.accept(self)
    }

    func visit(_ node: Tuple) throws {
        update(node)

        for expr in node.expressions {
            try expr.accept(self)
        }

        for id in node.idents {
            try id.accept(self)
        }
    }

    func visit(_ node: Nil) throws {
        update(node)
    }

    func visit(_ node: CallExpression) throws {
        update(node)

        for expr in node.arguments {
            try expr.accept(self)
        }
    }

    func visit(_ node: OperationStatement) throws {
        update(node)

        for param in node.params {
            try param.accept(self)
        }

        try node.body.accept(self)
    }
    
    func visit(_ node: ClassStatement) throws {
        update(node)
        
        //TODO: implement for rest of class statement
    }

}
