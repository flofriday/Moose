//
// Created by flofriday on 31.05.22.
//

import Foundation

class Interpreter: Visitor {
    var errors: [RuntimeError] = []
    var environment: Environment

    init() {
        environment = Environment()
        addBuiltIns()
    }

    private func addBuiltIns() {}

    func run(program: Program) throws {
        try visit(program)
    }

    func visit(_: Program) throws {}

    func visit(_: AssignStatement) throws {}

    func visit(_: ReturnStatement) throws {}

    func visit(_: ExpressionStatement) throws {}

    func visit(_: BlockStatement) throws {}

    func visit(_: FunctionStatement) throws {}

    func visit(_: ClassStatement) throws {}

    func visit(_: IfStatement) throws {}

    func visit(_: Identifier) throws {}

    func visit(_: IntegerLiteral) throws {}

    func visit(_: Boolean) throws {}

    func visit(_: StringLiteral) throws {}

    func visit(_: PrefixExpression) throws {}

    func visit(_: InfixExpression) throws {}

    func visit(_: PostfixExpression) throws {}

    func visit(_: VariableDefinition) throws {}

    func visit(_: Tuple) throws {}

    func visit(_: Nil) throws {}

    func visit(_: CallExpression) throws {}

    func visit(_: OperationStatement) throws {}
}
