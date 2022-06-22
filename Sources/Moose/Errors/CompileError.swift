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
        messages.map { message in
            message.localizedDescription
        }
        .joined()
    }

    public func getFullReport(sourcecode: String) -> String {
        var out = ""
        for msg in messages {
            // The header
            out += msg.getFullReport(sourcecode: sourcecode)
        }
        return out
    }
}
