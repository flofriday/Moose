//
//  File.swift
//
//
//  Created by Johannes Zottele on 13.08.22.
//

import Foundation

extension Typechecker {
    func visit(_ node: List) throws {
        // if no expressions in list, type of list is Nil
        guard !node.expressions.isEmpty else {
            node.mooseType = NilType()
            return
        }

        let listType = try node.expressions.reduce(nil) { (acc: MooseType?, curr) in
            try curr.accept(self)
            guard let acc = acc else {
                return curr.mooseType
            }

            // if the current type is no subtype of the acc. type, check if it is a supertype of the acc type
            // if it is the super, set the type to the curr
            if TypeScope.rate(subtype: curr.mooseType!, ofSuper: acc, classExtends: scope.doesScopeExtend) == nil {
                guard TypeScope.rate(subtype: acc, ofSuper: curr.mooseType!, classExtends: scope.doesScopeExtend) != nil else {
                    throw error(message: "`\(curr.description)` is of type `\(curr.mooseType!.description)`, but previous list entry is of type `\(acc.description)`.\nTip: Lists have to be homogen.", node: node)
                }
                return curr.mooseType!
            }
            return acc
        }

        guard let listType = listType as? ParamType else {
            throw error(message: "Type of list `\(listType?.description ?? "list")` is not a valid type for Lists.", node: node)
        }

        node.mooseType = ListType(listType)
    }

    func visit(_ node: Dict) throws {
        guard !node.pairs.isEmpty else {
            node.mooseType = NilType()
            return
        }

        var keyType: ParamType?
        var valType: ParamType?
        try node.pairs.forEach { cur in

            try cur.key.accept(self)
            guard let curKey = cur.key.mooseType as? ParamType else {
                throw error(message: "Type \(cur.key.mooseType!) is not suitable as key of dict.", node: cur.key)
            }
            if let key = keyType {
                // if the current key is no subtype of the acc. key type, check if it is a supertype of the acc keytype
                // if it is the super, set the key type to the curKey
                if TypeScope.rate(subtype: curKey, ofSuper: key, classExtends: scope.doesScopeExtend) == nil {
                    guard TypeScope.rate(subtype: key, ofSuper: curKey, classExtends: scope.doesScopeExtend) != nil else {
                        throw error(message: "Key types \(curKey) and \(key) are not compatible as keys in same dict.", node: node)
                    }
                    keyType = curKey
                }
            } else {
                keyType = curKey
            }

            try cur.value.accept(self)
            guard let curVal = cur.value.mooseType as? ParamType else {
                throw error(message: "Type \(cur.key.mooseType!) is not suitable as value of dict.", node: cur.value)
            }
            if let val = valType {
                // if the current value is no subtype of the acc. value type, check if it is a supertype of the acc valuetype
                // if it is the super, set the value type to the curVal
                if TypeScope.rate(subtype: curVal, ofSuper: val, classExtends: scope.doesScopeExtend) == nil {
                    guard TypeScope.rate(subtype: val, ofSuper: curVal, classExtends: scope.doesScopeExtend) != nil else {
                        throw error(message: "Value types \(curVal) and \(val) are not compatible as values in same dict.", node: node)
                    }
                    valType = curVal
                }
            } else {
                valType = curVal
            }
        }

        node.mooseType = DictType(keyType!, valType!)
    }

    func visit(_ node: IndexExpression) throws {
        try node.indexable.accept(self)

        guard let listtype = (node.indexable.mooseType as? ListType)?.type else {
            throw error(message: "`\(node.indexable.description)` is of type `\(node.indexable.mooseType!)`, but index access requires a List.", node: node.indexable)
        }

        try node.index.accept(self)
        guard node.index.mooseType is IntType else {
            throw error(message: "Index expression `\(node.index.description)` must be an `Int` but is of type `\(node.index.mooseType!)`", node: node.index)
        }

        node.mooseType = listtype
    }
}
