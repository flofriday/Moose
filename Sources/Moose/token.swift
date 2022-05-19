// TODO: This is just a reference implementation, and needs to be updated to 
// include all types
enum TokenType {
    case Identifier
    case Return
}

struct Token {
    var type: TokenType
    var lexeme: String
    var literal: Any
    var line: Int
    var column: Int
}