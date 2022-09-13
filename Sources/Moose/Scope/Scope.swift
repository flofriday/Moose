//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

protocol Scope {
    /// Get type of identifier of all scopes
    func typeOf(variable: String) throws -> MooseType
    func typeOf(function: String, params: [MooseType]) throws -> MooseType
    func typeOf(op: String, opPos: OpPos, params: [MooseType]) throws -> (MooseType, OpPos)

    func returnType(op: String, opPos: OpPos, params: [MooseType]) throws -> MooseType
    func returnType(function: String, params: [MooseType]) throws -> MooseType

    func has(variable: String, includeEnclosing: Bool) -> Bool
    func has(function: String, params: [MooseType], includeEnclosing: Bool) -> Bool
    func has(op: String, opPos: OpPos, params: [MooseType]) -> Bool

    func getSimilar(function: String, params: [MooseType]) -> [(String, FunctionType)]
    // func getSimilar(variable: String) -> [(String, MooseType)]

    func isMut(variable: String) throws -> Bool

    func add(variable: String, type: MooseType, mutable: Bool) throws
    func add(op: String, opPos: OpPos, params: [ParamType], returnType: MooseType) throws
    func add(function: String, params: [ParamType], returnType: MooseType) throws

    var closed: Bool { get set }
    func isGlobal() -> Bool
}
