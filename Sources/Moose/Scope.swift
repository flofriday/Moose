//
// Created by flofriday on 21.06.22.
//

import Foundation

class Scope {
    var mooseVars: [String: MooseType] = [:]
    var mooseConsts: Set<String> = []
    var mooseFuncs: [String: ([MooseType], MooseType)] = [:]
    var mooseClasses: Set<String> = []
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

    func getFuncType(name: String) throws -> MooseType? {
        guard let f = mooseFuncs[name] else {
            if let enclosing = enclosing {
                return try enclosing.getFuncType(name: name)
            }

            // TODO: format this error correctly
            throw ScopeError(message: "There is no function with the name '\(name)'")
        }

        throw ScopeError(message: "NOT IMPLEMENTED")
    }

    func addFunc(name: String, args: [MooseType], returnType: MooseType?) throws {
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
}
