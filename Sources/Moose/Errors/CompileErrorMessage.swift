//
// Created by flofriday on 01.06.22.
//

import Foundation

// Note: this doesn't inherit from Error as it never needs to be thrown but will be returned.
// The reason for this is that we wan't to continue after an error to find all errors at once, throwing an Error
// prevents this because execution stops after an error.
struct CompileErrorMessage: Error {
    var location: Location
    var header: String
    var message: String
}

extension CompileErrorMessage: LocalizedError {
    public var errorDescription: String? {
        var out = "-- \(header) ---\n"
        out += "Line: \(location.line)\nStart: \(location.col)\nEnd: \(location.endCol)\n"
        out += "Message: \(message)\n\n"
        return out
    }
}

// TODO: adapt for multiline errors
extension CompileErrorMessage {
    public func getFullReport(sourcecode: String) -> String {
        // The read header
        var out = "-- \(header) ".red
        out += String(repeating: "-", count: 80 - 4 - header.count).red
        out += "\n\n"

        // Print the bad code part
        out += Highlighter.highlight(location: location, sourcecode: sourcecode)
        out += "\n"

        // A detailed message explaining the error
        out += message
        out += "\n\n"
        return out
    }
}
