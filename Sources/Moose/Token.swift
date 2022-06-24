
enum OpPos: Equatable, Hashable, CustomStringConvertible {
    case Prefix
    case Infix
    case Postfix

    var description: String {
        switch self {
        case .Prefix:
            return "prefix"
        case .Infix:
            return "infix"
        case .Postfix:
            return "postfix"
        }
    }

    var numArgs: Int {
        switch self {
        case .Prefix, .Postfix:
            return 1
        case .Infix:
            return 2
        }
    }

    static func from(token: TokenType) -> OpPos? {
        switch token {
        case .Prefix:
            return .Prefix
        case .Infix:
            return .Infix
        case .Postfix:
            return .Postfix
        default:
            return nil
        }
    }
}

// include all types
enum TokenType: Equatable, Hashable {
    case EOF

    case Int
    case Identifier
    case Operator(pos: OpPos, assign: Bool)

    case Assign

    case Comma
    case SemiColon
    case Colon

    case NLine
    case String

    case LParen
    case RParen
    case LBrace
    case RBrace
    case LBracket
    case RBracket

    // Keywords
    case Mut
    case Func
    case Boolean(Bool)
    case If
    case Else
    case Ret
    case For
    case In
    case Class
    case Extend
    case Infix
    case Prefix
    case Postfix
    case Void
    case Nil
}

extension TokenType {
    var isAssign: Bool {
        switch self {
        case .Assign, .Operator(pos: .Infix, assign: true):
            return true
        default:
            return false
        }
    }
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
    case "true": return .Boolean(true)
    case "false": return .Boolean(false)
    case "return": return .Ret
    case "for": return .For
    case "in": return .In
    case "class": return .Class
    case "extend": return .Extend
    case "infix": return .Infix
    case "postfix": return .Postfix
    case "prefix": return .Prefix
    case "Void": return .Void
    case "nil": return .Nil
    case "if": return .If
    case "else": return .Else
    default: return .Identifier
    }
}
