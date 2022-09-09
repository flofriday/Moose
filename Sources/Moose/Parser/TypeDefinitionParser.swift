//
//  File.swift
//
//
//  Created by Johannes Zottele on 05.09.22.
//

import Foundation

extension Parser {
    /// returns type of `> Type`. If there was no `>` nil is returned
    func parseReturnTypeDefinition() throws -> MooseType? {
        if !check(type: .LBrace) {
            let toTok = advance() // > token as infix prefix or postfix op
            guard
                case .Operator(pos: _, assign: false) = toTok.type,
                toTok.lexeme == ">"
            else {
                throw error(message: "expected > in function signature to define type, but got \(toTok.lexeme) instead", token: toTok)
            }
            return try parseValueTypeDefinition()
        }

        return nil
    }

    // -----------------------
    // ---- TypeDefinition ---

    func parseValueTypeDefinition() throws -> MooseType {
        switch peek().type {
        case .Void:
            return try parseVoidTypeDefinition()
        case .Identifier:
            let ident = try parseIdentifier()
            return MooseType.toType(ident.value)
        case .LParen:
            return try parseTupleGroupFunction_TypeDefinition()
        case .LBracket:
            return try parseListTypeDefinition()
        case .LBrace:
            return try parseDictTypeDefinition()
        default:
            throw error(message: "Could not find type definition parsing method for token \(peek().type)", token: peek())
        }
    }

    func parseVoidTypeDefinition() throws -> MooseType {
        let _ = try consume(type: .Void, message: "expected 'Void', but got \(peek().lexeme) instead")
        return VoidType()
    }

    func parseListTypeDefinition() throws -> MooseType {
        _ = try consume(type: .LBracket, message: "Expected a starting '[', but got \(peek().lexeme) instead.")
        let typeToken = peek()
        let type = try parseValueTypeDefinition()
        _ = try consume(type: .RBracket, message: "Expected a closing ']', but got \(peek().lexeme) instead.")
        guard let type = type as? ParamType else {
            throw error(message: "List of type `\(type)` is not allowed.", token: typeToken)
        }
        return ListType(type)
    }

    func parseDictTypeDefinition() throws -> MooseType {
        _ = try consume(type: .LBrace, message: "Expected a starting `{`, but got \(peek().lexeme) instead.")
        let keyToken = peek()
        let key = try parseValueTypeDefinition()
        _ = try consume(type: .Colon, message: "Expected a seperating ':', but got \(peek().lexeme) instead.")
        guard let key = key as? ParamType else {
            throw error(message: "Dict with keys of type `\(key)` is not allowed.", token: keyToken)
        }
        let valueToken = peek()
        let value = try parseValueTypeDefinition()
        _ = try consume(type: .RBrace, message: "Expected a closing '}', but got \(peek().lexeme) instead.")
        guard let value = value as? ParamType else {
            throw error(message: "Dict with values of type `\(value)` is not allowed.", token: valueToken)
        }
        return DictType(key, value)
    }

    func parseFunctionTypeDefinition(params: [ParamType]) throws -> MooseType {
        guard case .Operator(pos: _, false) = peek().type, peek().lexeme == ">" else {
            throw error(message: "Expected a '>' for function defintion, but got \(peek().lexeme) instead.", token: peek())
        }
        _ = advance()

        let resultType = try parseValueTypeDefinition()
        return FunctionType(params: params, returnType: resultType)
    }

    func parseTupleGroupFunction_TypeDefinition() throws -> MooseType {
        let token = try consume(type: .LParen, message: "Expected a starting '(', but got \(peek().lexeme) instead.")
        let types = try parseTypeDefinitionList(seperator: .Comma, end: .RParen)
            .map { (t: MooseType) -> ParamType in
                guard let type = t as? ParamType else {
                    throw error(message: "Type `\(t)` is not allowed here. Value Types only.", token: token)
                }
                return type
            }

        // if next token is '>', it is a function type, else its a void, tuple or group (Int) that is mapped to Int
        if case .Operator(pos: _, false) = peek2().type, peek2().lexeme == ">" {
            _ = try consume(type: .RParen, message: "expected closing ) at end of function parameter definition, got \(peek().lexeme)")
            return try parseFunctionTypeDefinition(params: types)
        } else if types.isEmpty {
            _ = try consume(type: .RParen, message: "expected closing ) at end of Void definition, got \(peek().lexeme)")
            return VoidType()
        } else if types.count == 1 {
            _ = try consume(type: .RParen, message: "expected closing ) at end of group defintion, got \(peek().lexeme)")
            return types[0]
        } else {
            _ = try consume(type: .RParen, message: "expected closing ) at end of tuple, got \(peek().lexeme)")
            return TupleType(types)
        }
    }

    func parseTypeDefinitionList(seperator: TokenType, end: TokenType) throws -> [MooseType] {
        var list = [MooseType]()

        guard !check(type: end) else {
            return list
        }

        list.append(try parseValueTypeDefinition())
        while match(types: seperator) {
            list.append(try parseValueTypeDefinition())
        }
        return list
    }

    /// Parses strongly typed variable definitions, currently used by parameter and class property definitions
    func parseVariableDefinition() throws -> VariableDefinition {
        let startToken = peek()
        let mut = match(types: .Mut)
        let ident = try parseIdentifier()
        let token = try consume(type: .Colon, message: "expected : to define type, but got \(peek().lexeme) instead")
        let type = try parseValueTypeDefinition()
        let endToken = previous()
        guard let type = type as? ParamType else {
            throw error(message: "Variable cannot be of type \(type).", token: token)
        }

        let location = mergeLocations(startToken, endToken)
        return VariableDefinition(token: ident.token, location: location, mutable: mut, name: ident, type: type)
    }

    func parseAllVariableDefinitions() throws -> [VariableDefinition] {
        var definitions = [VariableDefinition]()
        while check(oneOf: .Mut, .Identifier) {
            definitions.append(try parseVariableDefinition())
            try consumeStatementEnd()
        }
        return definitions
    }
}
