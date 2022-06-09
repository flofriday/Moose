//
// Created by flofriday on 01.06.22.
//

import Foundation

// Note: this doesn't inherit from Error as it never needs to be thrown but will be returned.
// The reason for this is that we wan't to continue after an error to find all errors at once, throwing an Error
// prevents this because execution stopps after an error.
struct CompileErrorMessage {
    var line: Int
    var startCol: Int
    var endCol: Int
    var message: String


}
