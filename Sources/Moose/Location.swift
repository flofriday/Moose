//
// Created by flofriday on 28.06.22.
//

import Foundation

/// The common datastructure to determine where something
/// (a token or a AST node) is.
/// A document starts on line 1 with column 1.
struct Location {
    var col: Int
    var endCol: Int
    var line: Int
    var endLine: Int

    func mergeLocations(_ other: Location) -> Location {
        return Moose.mergeLocations(self, other)
    }
}

extension Token {
    func mergeLocations(_ other: Location) -> Location {
        return locationFromToken(self).mergeLocations(other)
    }

    func mergeLocations(_ other: Token) -> Location {
        return Moose.mergeLocations(self, other)
    }
}

func mergeLocations(_ a: Location, _ b: Location) -> Location {
    // Calculating the lines is straight forward
    let line = min(a.line, b.line)
    let endLine = max(a.line, b.line)

    // rewrite logic
    // Lets assume a is the first one
    var col = a.col

    // Now check if we made a mistake and if so lets correct for it
    if (b.line, b.col) < (a.line, a.col) {
        col = b.col
    }

    // Lets assume b is the last one
    var endCol = b.endCol

    // Now check if we made another mistake
    if (b.endLine, b.endCol) < (a.endLine, a.endCol) {
        endCol = a.endCol
    }

    return Location(
        col: col,
        endCol: endCol,
        line: line,
        endLine: endLine
    )
}

func mergeLocations(_ a: Token, _ b: Token) -> Location {
    return mergeLocations(locationFromToken(a), locationFromToken(b))
}

func locationFromToken(_ t: Token) -> Location {
    return Location(
        col: t.column,
        endCol: max(t.column, t.column + (t.lexeme.lines.last?.count ?? t.column) - 1),
        line: t.line,
        endLine: max(t.line, t.line + t.lexeme.lines.count - 1)
    )
}
