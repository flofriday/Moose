//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

class TypeScope: Scope {
    static var global = TypeScope()

    /// Since arguments are never checked withing a closed environment,  we don't want
    /// the scopes to check against closed scopes. More info in github issue #31.
    ///
    ///
    /// This is toggled by the argument checking.
    static var argumentCheck = false

    typealias rateType = (rate: Int, extendStep: Int)
    internal var variables: [String: (type: MooseType, mut: Bool)] = [:]
    internal var funcs: [String: [FunctionType]] = [:]
    private var ops: [String: [(FunctionType, OpPos)]] = [:]

    private var classes: [String: ClassTypeScope] = [:]

    let enclosing: TypeScope?
    var _closed: Bool = false
    var closed: Bool {
        get { _closed && !TypeScope.argumentCheck }
        set(value) { _closed = value }
    }

    init(enclosing: TypeScope? = nil) {
        self.enclosing = enclosing
    }

    init(copy: TypeScope) {
        self.funcs = copy.funcs
        self.variables = copy.variables
        self.ops = copy.ops
        self.classes = copy.classes
        self.enclosing = copy.enclosing
        self.closed = copy.closed
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
    private func currentContains(op: String, opPos: OpPos, params: [MooseType]) -> Bool {
        guard let hits = ops[op] else {
            return false
        }
        return hits.contains {
            guard opPos == $0.1 else { return false }
            guard let (rate, steps) = TypeScope.rate(storedFunction: $0.0, by: params, classExtends: self.doesScopeExtend) else { return false }
            return rate == 0 && steps == 0
        }
    }

    func typeOf(op: String, opPos: OpPos, params: [MooseType]) throws -> (MooseType, OpPos) {
        guard isGlobal() else { return try TypeScope.global.typeOf(op: op, opPos: opPos, params: params) }
        // Go through all operators with name op and then map the results to (type, rate) where
        // rate is the rating of the stored operator. If operator doesn't match in any way
        // return nil (sorted out). Last but not least sort the result by the rating (lower is better)
        let ratedOps = ops[op]?.compactMap { o -> (type: (MooseType, OpPos), rate: rateType)? in
            guard o.1 == opPos else { return nil }
            let rate = TypeScope.rate(storedFunction: o.0, by: params, classExtends: self.doesScopeExtend)
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
        guard isGlobal() else { return try TypeScope.global.returnType(op: op, opPos: opPos, params: params) }

        guard let retType = (try typeOf(op: op, opPos: opPos, params: params).0 as? FunctionType)?.returnType else {
            fatalError("INTERNAL ERROR: MooseType is not of type .Function")
        }
        return retType
    }

    func has(op: String, opPos: OpPos, params: [MooseType]) -> Bool {
        guard isGlobal() else { return TypeScope.global.has(op: op, opPos: opPos, params: params) }
        return currentContains(op: op, opPos: opPos, params: params)
    }

    func add(op: String, opPos: OpPos, params: [ParamType], returnType: MooseType) throws {
        guard isGlobal() else { return try TypeScope.global.add(op: op, opPos: opPos, params: params, returnType: returnType) }

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
            guard let (rate, steps) = TypeScope.rate(storedFunction: $0, by: params, classExtends: doesScopeExtend) else { return false }
            return rate == 0 && steps == 0
        }
    }

    private func getPossible(function: String, params: [MooseType]) -> [(type: MooseType, rate: TypeScope.rateType)]? {
        // Go through all functions with name function and then map the results to (type, rate) where
        // rate is the rating of the stored function. If function doesn't match in any way
        // return nil (sorted out). Last but not least sort the result by the rating (lower is better)
        return funcs[function]?.compactMap { storedFunc -> (type: MooseType, rate: rateType)? in
            let rate = TypeScope.rate(storedFunction: storedFunc, by: params, classExtends: TypeScope.global.doesScopeExtend)
            guard let rate = rate else { return nil }
            return (storedFunc, rate)
        }.sorted { $0.rate < $1.rate }
    }

    func callIsPossible(of function: String, with params: [MooseType]) -> Bool {
        guard
            let ratedFuncs = getPossible(function: function, params: params)
        else { return false }

        if ratedFuncs.count == 1 { return true }
        if ratedFuncs.count > 1, ratedFuncs[0].rate != ratedFuncs[1].rate { return true }
        return false
    }

    func typeOf(function: String, params: [MooseType]) throws -> MooseType {
        // Go through all functions with name function and then map the results to (type, rate) where
        // rate is the rating of the stored function. If function doesn't match in any way
        // return nil (sorted out). Last but not least sort the result by the rating (lower is better)
        let ratedFuncs = getPossible(function: function, params: params)
        if let types = ratedFuncs {
            if types.count == 1 {
                return types.first!.type
            }
            if types.count > 1 {
                guard types[0].rate != types[1].rate else {
                    throw ScopeError(message: "Multiple possible functions with signatures `\(function)(\(params.map { $0.description }.joined(separator: ",")))`. You have to give more context to the function call.")
                }
                return types[0].type
            }
        }
        guard let enclosing = enclosing, !closed else {
            throw ScopeError(message: "Function with signature `\(function)(\(params.map { $0.description }.joined(separator: ",")))` isn't defined.")
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

    func replace(function: String, with params: [ParamType], by newType: FunctionType) throws {
        let possibleFuncs = getPossible(function: function, params: params)
        guard let possibleFuncs = possibleFuncs, !possibleFuncs.isEmpty else {
            throw ScopeError(message: "No function \(function)(\(params.map { $0.description }.joined(separator: ", "))) could be found to replace.")
        }

        guard possibleFuncs.count == 1 || possibleFuncs[0].rate < possibleFuncs[1].rate else {
            throw ScopeError(message: "Multiple possible function to replace.")
        }

        let selectedRate = possibleFuncs[0].rate
        let selectedIndex = funcs[function]!.firstIndex {
            guard let currRate = TypeScope.rate(storedFunction: $0, by: params, classExtends: doesScopeExtend) else { return false }
            return currRate == selectedRate
        }

        funcs[function]![selectedIndex!] = newType
    }
}

extension TypeScope {
    func isGlobal() -> Bool {
        return enclosing == nil && !closed
    }

    func global() -> TypeScope {
        guard let enclosing = enclosing else {
            return self
        }
        return enclosing.global()
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
        guard isGlobal() else { return global().has(clas: clas) }
        return classes.contains(where: { $0.key == clas })
    }

    func getScope(clas: String) -> ClassTypeScope? {
        guard isGlobal() else { return TypeScope.global.getScope(clas: clas) }

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

    typealias SuperClass = String
    typealias SubClass = String
    typealias ExtendsFunction = (SubClass, SuperClass) -> (extends: Bool, steps: Int)
    static func rate(subtype: MooseType, ofSuper superType: MooseType, classExtends: ExtendsFunction) -> rateType? {
        if subtype == superType { return (0, 0) }
        if subtype is NilType || superType.superOf(type: subtype) { return (1, 0) }
        if
            let subtype = subtype as? ClassType,
            let supr = superType as? ClassType
        {
            let (extends, steps) = classExtends(subtype.name, supr.name)
            guard extends else { return nil }

            return (0, steps)
        }

        return nil
    }

    /// Caluclates the distance between two array of params
    ///
    /// Supers are the params of the function that should be callable with the params of subtypes.
    ///
    /// classExtends is the function that is used to determine if and in how many steps a subtype class type extends a super class type parameter
    ///  the first param is the subclass and the second the eventual superclass
    ///
    /// Returns for rate: `0` if params are exakt matches, `n` if "hamming distance" is `n` and `nil` if params are not compatibale
    /// Returns for extendSteps: `0` if all class types are exaclty matching the super param types, `n` if the sum of all inheritances of subtypes to the supers class types is `n`
    static func rate(storedFunction: FunctionType, by params: [MooseType], classExtends: ExtendsFunction) -> rateType? {
        let supers = storedFunction.params
        let subtypes = params
        guard subtypes.count == supers.count else { return nil }

        return zip(subtypes, supers)
            .reduce((0, 0)) { acc, zip -> rateType? in
                guard let (rate, extendStep) = acc else { return nil }
                let (subtype, supr) = zip

                guard let (curRate, curExtendStep) = TypeScope.rate(subtype: subtype, ofSuper: supr, classExtends: classExtends) else {
                    return nil
                }

                return (rate + curRate, extendStep + curExtendStep)
            }
    }

    static func rate(of storedFunction: FunctionType, equalTo params: [MooseType], classExtends: (String, String) -> (extends: Bool, steps: Int)) -> Bool {
        guard let (rate, steps) = rate(storedFunction: storedFunction, by: params, classExtends: classExtends) else { return false }
        return rate == 0 && steps == 0
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
        self.className = name
        self.classProperties = properties
        super.init(enclosing: enclosing)
    }

    init(copy: ClassTypeScope) {
        self.className = copy.className
        self.classProperties = copy.classProperties
        self.visited = copy.visited
        self.superClass = copy.superClass
        super.init(copy: copy)
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

    private func extendStep(clas: String, step: Int) -> (extends: Bool, steps: Int) {
        if className == clas { return (true, step) }
        if let superClass = superClass {
            return superClass.extendStep(clas: clas, step: step + 1)
        }
        return (false, step)
    }

    /// Returns if and in how many steps a class extends an other class
    func extends(clas: String) -> (extends: Bool, steps: Int) {
        return extendStep(clas: clas, step: 0)
    }

    var propertyCount: Int {
        return super.variableCount
    }
}

extension TypeScope {
    /// Returns if and in how many steps a class extends an other class
    func doesScopeExtend(clas: String, extend superclass: String) -> (extends: Bool, steps: Int) {
        guard isGlobal() else { return global().doesScopeExtend(clas: clas, extend: superclass) }
        guard let subClas = getScope(clas: clas) else { return (false, 0) }
        return subClas.extends(clas: superclass)
    }
}
