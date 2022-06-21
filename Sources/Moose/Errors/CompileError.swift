//
// Created by flofriday on 01.06.22.
//

import Foundation
import Rainbow

class CompileError: Error {
    let messages: [CompileErrorMessage]

    init(messages: [CompileErrorMessage]) {
        self.messages = messages
    }
}

extension CompileError: LocalizedError {
    public var errorDescription: String? {
        messages.map { message in message.localizedDescription }.joined()
    }

    public func getFullReport(sourcecode: String) -> String {
        var out = ""
        let lines = sourcecode.lines

        for m in messages {
            // The header
            out += "\("-- CompileError ----------------------------------------------------------------\n\n".red)"

            var msg = m
            if lines.count <= msg.line {
                msg.line = lines.count - 1
            }
            // The source code line causing the error
            out += String(format: "%3d| ".blue, msg.line)
            out += "\(lines[msg.line - 1])\n"
            out += String(repeating: " ", count: 5 + msg.startCol)
            out += String(repeating: "^".red, count: msg.endCol - msg.startCol)
            out += "\n\n"

            // A detailed message explaining the error
            out += msg.message
            out += "\n"
        }
        return out
    }
}
