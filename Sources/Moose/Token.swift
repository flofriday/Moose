// include all types
enum TokenType: String {

    case EOF = "EOF"
    case Illegal = "ILLEGAL"

    case Int = "INT"
    case Identifier = "IDENT"
    case Operator = "OPERATOR"
    case AssignOperator = "ASSIGN OPERATOR"

    case Assign = "="
    case ToType = ">"
    case InheritsFrom = "<"

    case Comma = ","
    case SemiColon = ";"
    case Colon = ":"

    case NLine = "NEW_LINE"
    case String = "STRING"

    case LParen = "("
    case RParen = ")"
    case LBrace = "{"
    case RBrace = "}"
    case LBracket = "["
    case RBracket = "]"

    // Keywords
    case Mut = "MUT"
    case Func = "FUNC"
    case True = "TRUE"
    case False = "FALSE"
    case If = "IF"
    case Else = "ELSE"
    case Ret = "RETURN"
    case For = "FOR"
    case In = "IN"
    case Class = "CLASS"
    case Extend = "EXTEND"
    case Infix = "INFIX"
    case Prefix = "PREFIX"
    case Postfix = "POSTFIX"
}

struct Token {
    var type: TokenType
    var lexeme: String
    var literal: Any?
    var line: Int
    var column: Int
}

internal func lookUpIdent(ident: String) -> TokenType {
    switch ident {
    case "mut": return .Mut
    case "func": return .Func
    case "true": return .True
    case "false": return .False
    case "return": return .Ret
    case "for": return .For
    case "in": return .In
    case "class": return .Class
    case "extend": return .Extend
    case "infix": return .Infix
    case "postfix": return .Postfix
    case "prefix": return .Prefix
    default: return .Identifier
    }
}

