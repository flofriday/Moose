//
// Created by flofriday on 21.06.22.
//

import Foundation

class Scope {
    var mooseVars: [String: MooseType] = [:]
    var mooseConsts: Set<String> = []
    var mooseFuncs: [String: ([MooseType], MooseType)] = [:] // TODO: this could also be much faster O(1) instead of O(n), however, this is probably most of the time O(1)
    var mooseClasses: Set<String> = []
    var mooseOps: [String: [(OpPos, [MooseType], MooseType)]] = [:] // TODO: this is mostly really ineficient O(n) while it could be O(1)
    var enclosing: Scope?

    init() {}

    func getIdentifierType(name: String) throws -> MooseType {
        if mooseVars.keys.contains(name) {
            return mooseVars[name]!
        }

        if mooseClasses.contains(name) {
            return .Class(name)
        }

        if mooseFuncs.keys.contains(name) {
            let (args, retType) = mooseFuncs[name]!
            return .Function(args, retType)
        }

        throw ScopeError(message: "'\(name)' is not visible in the current scope")
    }

    func hasVar(name: String, includeEnclosing: Bool = true) -> Bool {
        if mooseVars.keys.contains(name) {
            return true
        }

        guard enclosing != nil, includeEnclosing else {
            return false
        }

        return enclosing!.hasVar(name: name)
    }

    func isVarMut(name: String, includeEnclosing: Bool) -> Bool {
        if mooseConsts.contains(name) {
            return false
        }

        guard enclosing != nil, includeEnclosing else {
            return false
        }

        return enclosing!.isVarMut(name: name, includeEnclosing: includeEnclosing)
    }

    func getVarType(name: String) throws -> MooseType {
        if let type = mooseVars[name] {
            return type
        }

        guard enclosing != nil else {
            throw ScopeError(message: "'\(name)' isn't visible in the current scope.")
        }

        return try enclosing!.getVarType(name: name)
    }

    func addVar(name: String, type: MooseType, mutable: Bool) throws {
        if mooseVars.keys.contains(name) {
            throw ScopeError(message: "'\(name)' was already defined.")
        }

        if !mutable {
            mooseConsts.insert(name)
        }

        mooseVars.updateValue(type, forKey: name)
    }

    func getFuncType(name: String) throws -> MooseType {
        guard let f = mooseFuncs[name] else {
            if let enclosing = enclosing {
                return try enclosing.getFuncType(name: name)
            }

            // TODO: format this error correctly
            throw ScopeError(message: "There is no function with the name '\(name)'")
        }

        throw ScopeError(message: "NOT IMPLEMENTED")
    }

    func addFunc(name: String, args: [MooseType], returnType: MooseType) throws {
        /* if let others = mooseFuncs[name] {
             for other in others {
                 let (otherArgs, _) = other
                 if otherArgs == args {
                     throw ScopeError(message: "There is already another function with the name '\(name)' and the arguments \(args)")
                 }
             }
         }

         if !mooseFuncs.keys.contains(name) {
             mooseFuncs.updateValue([], forKey: name)
         }

         mooseFuncs[name]!.insert((args, returnType), at: 0)

          */
        throw ScopeError(message: "NOT IMPLEMENTED")
    }

    func hasOp(name: String, opPos: OpPos, args: [MooseType], includeEnclosing: Bool) -> Bool {
        guard mooseOps.keys.contains(name) else {
            return false
        }

        // We need to iterate over all operations with the same name cause the datastructure is stupid and I hadn't
        // enough time to write it properly.
        // So year we iterate overall and then find the one that matches the types.
        if let others = mooseOps[name] {
            for other in others {
                let (otherOpPos, otherArgs, _) = other
                if opPos == otherOpPos, args == otherArgs {
                    return true
                }
            }
        }

        if let enclosing = enclosing, includeEnclosing {
            return enclosing.hasOp(name: name, opPos: opPos, args: args, includeEnclosing: includeEnclosing)
        }

        return false
    }

    func getOpType(name: String, opPos: OpPos, args: [MooseType]) throws -> MooseType {
        guard mooseOps.keys.contains(name) else {
            throw ScopeError(message: "No operation `\(name)` exists.")
        }

        if let others = mooseOps[name] {
            for other in others {
                let (otherOpPos, otherArgs, otherRet) = other
                if opPos == otherOpPos, args == otherArgs {
                    return otherRet
                }
            }
        }

        guard enclosing != nil else {
            throw ScopeError(message: "No operation '\(name)' exists, that operates on \(args).")
        }

        return try enclosing!.getOpType(name: name, opPos: opPos, args: args)
    }

    func addOp(name: String, opPos: OpPos, args: [MooseType], returnType: MooseType) {
        if !mooseOps.keys.contains(name) {
            mooseOps.updateValue([], forKey: name)
        }

        mooseOps[name]!.append((opPos, args, returnType))
    }

    func removeVar(variable name: String) {
        mooseConsts.remove(name)
        mooseVars.removeValue(forKey: name)
    }
}
