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

    // The default constructor
    init(col: Int, endCol: Int, line: Int, endLine: Int) {
        self.col = col
        self.endCol = endCol
        self.line = line
        self.endLine = endLine
    }

    // TODO: There is still a bug here with multiline nodes.
    // https://github.com/flofriday/Moose/issues/36

    // The merging constructor
    init(_ a: Location, _ b: Location) {
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

        self.col = col
        self.endCol = endCol
        self.line = line
        self.endLine = endLine
    }
}
