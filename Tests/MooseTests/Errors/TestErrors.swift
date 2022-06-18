//
// Created by Johannes Zottele on 18.06.22.
//

import Foundation

enum TestErrors: Error {
    case parseError(String)
    case testError(String)
}