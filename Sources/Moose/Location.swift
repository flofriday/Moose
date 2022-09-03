//
// Created by flofriday on 28.06.22.
//

import Foundation

struct Location {
    var col: Int
    var endCol: Int
    var line: Int
    var endLine: Int
}

func mergeLocations(_ a: Location, _ b: Location) -> Location {
    // Calculating the lines is straight forward
    let line = min(a.line, b.line)
    let endLine = max(a.line, b.line)

    // Lets assume a is the first one
    var col = a.col

    // Now check if we made a mistake and if so lets correct for it
    if b.line < a.line || (b.line == a.line && b.col < a.col) {
        col = b.col
    }

    // Lets assume b is the last one
    var endCol = b.endCol

    // Now check if we made another mistake
    if (a.line > b.line) || (a.line == b.line && a.endLine > b.endLine) {
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
        endCol: max(t.column, t.lexeme.lines.last?.count ?? t.column, t.column),
        line: t.line,
        endLine: max(t.line, t.line + t.lexeme.lines.count - 1)
    )
}
