//
//  File.swift
//
//
//  Created by Johannes Zottele on 23.06.22.
//

import Foundation

protocol AstDebug {
    typealias Line = Int
    typealias Column = Int

    func getSourceRange() -> ((Line, Column), (Line, Column))
}
