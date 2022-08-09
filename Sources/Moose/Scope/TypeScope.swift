//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

class TypeScope: Scope {
    private var variables: [String: (type: MooseType, mut: Bool)] = [:]
    private var funcs: [String: [MooseType]] = [:]
    private var ops: [String: [(MooseType, OpPos)]] = [:]

    private var classes: [String: TypeScope] = [:]

    let enclosing: TypeScope?

    init(enclosing: TypeScope? = nil) {
        self.enclosing = enclosing
    }
}

// Define all variable specific operations
extension TypeScope {
    func typeOf(variable: String) throws -> MooseType {
        if let type = variables[variable] {
            return type.0
        }
        guard let enclosing = enclosing else {
            throw ScopeError(message: "'\(variable)' isn't visible in the current scope.")
        }
        return try enclosing.typeOf(variable: variable)
    }

    func has(variable: String, includeEnclosing: Bool = true) -> Bool {
        if variables.keys.contains(variable) {
            return true
        }
        guard includeEnclosing, let enclosing = enclosing else {
            return false
        }
        return enclosing.has(variable: variable, includeEnclosing: includeEnclosing)
    }

    func isMut(variable: String) throws -> Bool {
        if let type = variables[variable] {
            return type.1
        }
        guard let enclosing = enclosing else {
            throw ScopeError(message: "'\(variable)' isn't visible in the current scope.")
        }
        return try enclosing.isMut(variable: variable)
    }

    func add(variable: String, type: MooseType, mutable: Bool) throws {
        guard !variables.contains(where: { name, store in
            name == variable && store.0 == type
        })
        else {
            throw ScopeError(message: "'\(variable)' with type '\(type)' is already in scope.")
        }
        variables[variable] = (type, mutable)
    }
}

// Define all op specific function
extension TypeScope {
    private func isOpBy(pos: OpPos, params: [MooseType], other: (MooseType, OpPos)) -> Bool {
        if case .Function(params, _) = other.0, pos == other.1 {
            return true
        }
        return false
    }

    private func currentContains(op: String, opPos: OpPos, params: [MooseType]) -> Bool {
        guard let hits = ops[op] else {
            return false
        }
        return hits.contains {
            isOpBy(pos: opPos, params: params, other: $0)
        }
    }

    func typeOf(op: String, opPos: OpPos, params: [MooseType]) throws -> (MooseType, OpPos) {
        if let type = ops[op]?
            .first(where: { isOpBy(pos: opPos, params: params, other: $0) })
        {
            return type
        }
        guard let enclosing = enclosing else {
            throw ScopeError(message: "Operator '\(op)' with params (\(params.map { $0.description }.joined(separator: ","))) isn't defined.")
        }
        return try enclosing.typeOf(op: op, opPos: opPos, params: params)
    }

    func returnType(op: String, opPos: OpPos, params: [MooseType]) throws -> MooseType {
        guard case let .Function(_, retType) = try typeOf(op: op, opPos: opPos, params: params).0 else {
            fatalError("INTERNAL ERROR: MooseType is not of type .Function")
        }
        return retType
    }

    func has(op: String, opPos: OpPos, params: [MooseType], includeEnclosing: Bool = true) -> Bool {
        if currentContains(op: op, opPos: opPos, params: params) {
            return true
        }
        guard includeEnclosing, let enclosing = enclosing else {
            return false
        }
        return enclosing.has(op: op, opPos: opPos, params: params, includeEnclosing: includeEnclosing)
    }

    func add(op: String, opPos: OpPos, params: [MooseType], returnType: MooseType) throws {
        let inCurrent = currentContains(op: op, opPos: opPos, params: params)
        guard !inCurrent else {
            throw ScopeError(message: "Operator '\(op)' with params (\(params.map { $0.description }.joined(separator: ","))) is alraedy defined.")
        }

        var list = (ops[op] ?? [])
        list.append((MooseType.Function(params, returnType), opPos))
        ops.updateValue(list, forKey: op)
    }
}

extension TypeScope {
    private func isFuncBy(params: [MooseType], other: MooseType) -> Bool {
        if case .Function(params, _) = other {
            return true
        }
        return false
    }

    private func currentContains(function: String, params: [MooseType]) -> Bool {
        guard let hits = funcs[function] else {
            return false
        }
        return hits.contains {
            isFuncBy(params: params, other: $0)
        }
    }

    func typeOf(function: String, params: [MooseType]) throws -> MooseType {
        if let type = funcs[function]?
            .first(where: { isFuncBy(params: params, other: $0) })
        {
            return type
        }
        guard let enclosing = enclosing else {
            throw ScopeError(message: "Function '\(function)' with params (\(params.map { $0.description }.joined(separator: ","))) isn't defined.")
        }
        return try enclosing.typeOf(function: function, params: params)
    }

    func returnType(function: String, params: [MooseType]) throws -> MooseType {
        guard case let .Function(_, retType) = try typeOf(function: function, params: params) else {
            fatalError("INTERNAL ERROR: MooseType is not of type .Function")
        }
        return retType
    }

    func has(function: String, params: [MooseType], includeEnclosing: Bool = true) -> Bool {
        if currentContains(function: function, params: params) {
            return true
        }
        guard includeEnclosing, let enclosing = enclosing else {
            return false
        }
        return enclosing.has(function: function, params: params, includeEnclosing: includeEnclosing)
    }

    func add(function: String, params: [MooseType], returnType: MooseType) throws {
        let inCurrent = currentContains(function: function, params: params)
        guard !inCurrent else {
            throw ScopeError(message: "Function '\(function)' with params (\(params.map { $0.description }.joined(separator: ","))) is already defined.")
        }
        var list = (funcs[function] ?? [])
        list.append(MooseType.Function(params, returnType))
        funcs.updateValue(list, forKey: function)
    }
}

extension TypeScope {
    func isGlobal() -> Bool {
        return enclosing == nil
    }
}
