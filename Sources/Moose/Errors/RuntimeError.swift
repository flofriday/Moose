//
// Created by flofriday on 22.06.22.
//

import Foundation

class RuntimeError: Error {
    var message: String

    init(message: String) {
        self.message = message
    }
}
