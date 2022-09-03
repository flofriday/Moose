//
// Created by flofriday on 01.06.22.
//

import Foundation

// Note: this doesn't inherit from Error as it never needs to be thrown but will be returned.
// The reason for this is that we wan't to continue after an error to find all errors at once, throwing an Error
// prevents this because execution stopps after an error.
struct CompileErrorMessage: Error {
    var location: Location
    var message: String
}

extension CompileErrorMessage: LocalizedError {
    public var errorDescription: String? {
        var out = "-- CompileError ---\n"
        out += "Line: \(location.line)\nStart: \(location.col)\nEnd: \(location.endCol)\n"
        out += "Message: \(message)\n\n"
        return out
    }
}

// TODO: adapt for multiline errors
extension CompileErrorMessage {
    public func getFullReport(sourcecode: String) -> String {
        var out = "\("-- CompileError ----------------------------------------------------------------\n\n".red)"

        let lines = sourcecode.lines
        var l = location.line
        if !(l - 1 < lines.count) {
            l = lines.count
        }
        // The source code line causing the error
        out += String(format: "%3d| ".blue, location.line)
        out += "\(lines[l - 1])\n"
        out += String(repeating: " ", count: 5 + location.col)
        out += String(repeating: "^".red, count: location.endCol - location.col)
        out += "\n\n"

        // A detailed message explaining the error
        out += message
        out += "\n"
        return out
    }
}
