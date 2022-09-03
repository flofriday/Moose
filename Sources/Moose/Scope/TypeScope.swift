//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

class TypeScope: Scope {
    internal var variables: [String: (type: MooseType, mut: Bool)] = [:]
    internal var funcs: [String: [MooseType]] = [:]
    private var ops: [String: [(MooseType, OpPos)]] = [:]

    private var classes: [String: ClassTypeScope] = [:]

    let enclosing: TypeScope?
    var closed: Bool = false

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
        guard let enclosing = enclosing, !closed else {
            // TODO: We could find similarly named variables here and suggest
            // them
            throw ScopeError(message: "Couldn't find variable '\(variable)' in the current scope.")
        }
        return try enclosing.typeOf(variable: variable)
    }

    func has(variable: String, includeEnclosing: Bool = true) -> Bool {
        if variables.keys.contains(variable) {
            return true
        }
        guard includeEnclosing, let enclosing = enclosing, !closed else {
            return false
        }
        return enclosing.has(variable: variable, includeEnclosing: includeEnclosing)
    }

    func isMut(variable: String) throws -> Bool {
        if let type = variables[variable] {
            return type.1
        }
        guard let enclosing = enclosing, !closed else {
            // TODO: We could find similarly named variables here and suggest
            // them
            throw ScopeError(message: "Couldn't find variable '\(variable)' in the current scope.")
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
    /// Rates other operation from 0 to n.
    /// If a rating is lower, it means that the parameter are fitting better than if it would be higher
    ///
    /// nil means it does not match
    /// 0 is exact match, 1 is away by 1, 2 ..,
    private func rate(storedOp: (MooseType, OpPos), by pos: OpPos, and params: [MooseType]) -> Int? {
        let storedParams = (storedOp.0 as? FunctionType)?.params
        guard let storedParams = storedParams else { return nil }
        guard pos == storedOp.1 else { return nil }
        return TypeScope.distanceSuperToSub(supers: storedParams, subtypes: params)
    }

    private func currentContains(op: String, opPos: OpPos, params: [MooseType]) -> Bool {
        guard let hits = ops[op] else {
            return false
        }
        return hits.contains {
            rate(storedOp: $0, by: opPos, and: params) == 0
        }
    }

    func typeOf(op: String, opPos: OpPos, params: [MooseType]) throws -> (MooseType, OpPos) {
        // Go through all operators with name op and then map the results to (type, rate) where
        // rate is the rating of the stored operator. If operator doesn't match in any way
        // return nil (sorted out). Last but not least sort the result by the rating (lower is better)
        let ratedOps = ops[op]?.compactMap { o -> (type: (MooseType, OpPos), rate: Int)? in
            let rate = rate(storedOp: o, by: opPos, and: params)
            guard let rate = rate else { return nil }
            return (o, rate)
        }.sorted(by: { $0.rate < $1.rate })

        if let types = ratedOps {
            // if only one operator was found, take it
            if types.count == 1 {
                return types.first!.type
            }

            if types.count > 1 {
                // if the first 2 have the same rating, we cannot choose which one is taken as operator
                guard types[0].rate != types[1].rate else {
                    throw ScopeError(message: "Multiple possible operators of `\(op)` with operands (\(params.map { $0.description }.joined(separator: ","))). You have to give more context to the operation call.")
                }
                return types[0].type
            }
        }

        guard let enclosing = enclosing, !closed else {
            throw ScopeError(message: "Operator '\(op)' with params (\(params.map { $0.description }.joined(separator: ","))) isn't defined.")
        }
        return try enclosing.typeOf(op: op, opPos: opPos, params: params)
    }

    func returnType(op: String, opPos: OpPos, params: [MooseType]) throws -> MooseType {
        guard let retType = (try typeOf(op: op, opPos: opPos, params: params).0 as? FunctionType)?.returnType else {
            fatalError("INTERNAL ERROR: MooseType is not of type .Function")
        }
        return retType
    }

    func has(op: String, opPos: OpPos, params: [MooseType], includeEnclosing: Bool = true) -> Bool {
        if currentContains(op: op, opPos: opPos, params: params) {
            return true
        }
        guard includeEnclosing, let enclosing = enclosing, !closed else {
            return false
        }
        return enclosing.has(op: op, opPos: opPos, params: params, includeEnclosing: includeEnclosing)
    }

    func add(op: String, opPos: OpPos, params: [ParamType], returnType: MooseType) throws {
        let inCurrent = currentContains(op: op, opPos: opPos, params: params)
        guard !inCurrent else {
            throw ScopeError(message: "Operator '\(op)' with params (\(params.map { $0.description }.joined(separator: ","))) is alraedy defined.")
        }

        var list = (ops[op] ?? [])
        list.append((FunctionType(params: params, returnType: returnType), opPos))
        ops.updateValue(list, forKey: op)
    }
}

extension TypeScope {
    private func currentContains(function: String, params: [MooseType]) -> Bool {
        guard let hits = funcs[function] else {
            return false
        }
        return hits.contains {
            TypeScope.rate(storedFunction: $0, by: params) == 0
        }
    }

    func typeOf(function: String, params: [MooseType]) throws -> MooseType {
        // Go through all functions with name function and then map the results to (type, rate) where
        // rate is the rating of the stored function. If function doesn't match in any way
        // return nil (sorted out). Last but not least sort the result by the rating (lower is better)
        let ratedFuncs = funcs[function]?.compactMap { storedFunc -> (type: MooseType, rate: Int)? in
            let rate = TypeScope.rate(storedFunction: storedFunc, by: params)
            guard let rate = rate else { return nil }
            return (storedFunc, rate)
        }.sorted { $0.rate < $1.rate }

        if let types = ratedFuncs {
            if types.count == 1 {
                return types.first!.type
            }
            if types.count > 1 {
                guard types[0].rate != types[1].rate else {
                    throw ScopeError(message: "Multiple possible functions of `\(function)` with params (\(params.map { $0.description }.joined(separator: ","))). You have to give more context to the function call.")
                }
                return types[0].type
            }
        }
        guard let enclosing = enclosing, !closed else {
            throw ScopeError(message: "Function '\(function)' with params (\(params.map { $0.description }.joined(separator: ","))) isn't defined.")
        }
        return try enclosing.typeOf(function: function, params: params)
    }

    func returnType(function: String, params: [MooseType]) throws -> MooseType {
        guard let retType = (try typeOf(function: function, params: params) as? FunctionType)?.returnType else {
            fatalError("INTERNAL ERROR: MooseType is not of type .Function")
        }
        return retType
    }

    func has(function: String, params: [MooseType], includeEnclosing: Bool = true) -> Bool {
        if currentContains(function: function, params: params) {
            return true
        }
        guard includeEnclosing, let enclosing = enclosing, !closed else {
            return false
        }
        return enclosing.has(function: function, params: params, includeEnclosing: includeEnclosing)
    }

    func add(function: String, params: [ParamType], returnType: MooseType) throws {
        let inCurrent = currentContains(function: function, params: params)
        guard !inCurrent else {
            throw ScopeError(message: "Function '\(function)' with params (\(params.map { $0.description }.joined(separator: ","))) is already defined.")
        }
        var list = (funcs[function] ?? [])
        list.append(FunctionType(params: params, returnType: returnType))
        funcs.updateValue(list, forKey: function)
    }
}

extension TypeScope {
    func isGlobal() -> Bool {
        return enclosing == nil && !closed
    }
}

extension TypeScope {
    func add(clas: String, scope: ClassTypeScope) throws {
        guard !has(clas: clas) else {
            throw ScopeError(message: "Class with name '\(clas)' does already exist. Class names must be unique.")
        }

        classes[clas] = scope
    }

    func has(clas: String) -> Bool {
        return classes.contains(where: { $0.key == clas })
    }

    func getScope(clas: String) -> ClassTypeScope? {
        if let clasScope = classes[clas] {
            return clasScope
        }

        return closed ? nil : enclosing?.getScope(clas: clas)
    }

    /// returns next enclosing class type scope and nil if there is no class type scope
    func nearestClassScope() -> ClassTypeScope? {
        guard let scope = self as? ClassTypeScope else {
            return closed ? nil : enclosing?.nearestClassScope()
        }
        return scope
    }

    var variableCount: Int {
        return variables.count
    }

    /// Caluclates the distance between two array of params
    ///
    /// Returns `0` if params are exakt matches, `n` if "hamming distance" is `n` and `nil` if params are not compatibale
    static func distanceSuperToSub(supers: [MooseType], subtypes: [MooseType]) -> Int? {
        guard subtypes.count == supers.count else { return nil }

        return zip(subtypes, supers)
            .reduce(0) { acc, zip in
                guard let acc = acc else { return nil }

                let (subtype, supr) = zip
                if subtype == supr { return acc }
                if subtype is NilType || supr.superOf(type: subtype) { return acc + 1 }
                return nil
            }
    }

    /// Rates storedFunction  from 0 to n.
    /// If a rating is lower, it means that the parameters are fitting better than if it would be higher
    ///
    /// nil means it does not match
    /// 0 is exact match, 1 is away by 1, 2 ..,
    static func rate(storedFunction: MooseType, by params: [MooseType]) -> Int? {
        let storedParams = (storedFunction as? FunctionType)?.params
        guard let storedParams = storedParams else { return nil }
        return TypeScope.distanceSuperToSub(supers: storedParams, subtypes: params)
    }
}

/// Class Scope specific methods
/// Also holds the corresponding ast class node
class ClassTypeScope: TypeScope {
    typealias propType = (name: String, type: MooseType, mutable: Bool)

    let className: String
    var classProperties: [propType]
    var superClass: ClassTypeScope?
    var visited = false

    init(enclosing: TypeScope? = nil, name: String, properties: [propType]) {
        className = name
        classProperties = properties
        super.init(enclosing: enclosing)
    }

    private var alreadyFlat = false
    /// Here we are flatting the class, so we are creating one class that is build-up from all
    /// respecting all inherited properties
    ///
    /// This function is called by the typechecker, so after all classes are checked, they all have nil as superclass and all have their respective functions and variables
    func flat() throws {
        guard !alreadyFlat else { return }
        alreadyFlat = true

        guard let superClass = superClass else { return }
        try superClass.flat()

        // Check if class holds property that is also defined in super class
        try classProperties.forEach { name, _, _ in
            guard !superClass.classProperties.contains(where: { name == $0.name }) else {
                throw ScopeError(message: "Property `\(name)` cannot be overwritten by `\(className)`.")
            }
        }
        classProperties += superClass.classProperties
        var vars = superClass.variables
        variables.forEach { vars[$0.key] = $0.value }
        variables = vars

        // Run through all funcs of superclass
        for (superName, sFns) in superClass.funcs {
            for sFn in sFns {
                if let sFn = sFn as? FunctionType {
                    // if this class overrides a function from superclass, check if return types match each other
                    // else (if superclass function was not overridden) add superclass function to functions of this class
                    if has(function: superName, params: sFn.params, includeEnclosing: false) {
                        let thisReturnType = try returnType(function: superName, params: sFn.params)
                        guard sFn.returnType == thisReturnType else {
                            throw ScopeError(message: "Function `\(superName)(\(sFn.params.map { $0.description }.joined(separator: ","))) > \(thisReturnType)` of class \(className) does not match return type \(sFn.returnType) of superclass.")
                        }
                    } else {
                        try add(function: superName, params: sFn.params, returnType: sFn.returnType)
                    }
                }
            }
        }
    }

    func extends(clas: String) -> Bool {
        if className == clas { return true }
        if let superClass = superClass {
            return superClass.extends(clas: clas)
        }
        return false
    }

    var propertyCount: Int {
        return super.variableCount
    }
}
