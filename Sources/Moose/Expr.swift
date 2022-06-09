//
// Created by flofriday on 01.06.22.
//

import Foundation

indirect enum Expr {
    case value(Int)
    case addition(Expr, Expr)
}
