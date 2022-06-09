//
// Created by flofriday on 01.06.22.
//

import Foundation

class CompileError: Error {
    let messages: [CompileErrorMessage]

    init(messages: [CompileErrorMessage]) {
        self.messages = messages
    }
}
