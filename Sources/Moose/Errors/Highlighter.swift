enum Highlighter {
    static func highlight(location: Location, sourcecode: String) -> String {
        let lines = sourcecode.lines
        guard location.line - 1 < lines.count else {
            return "<no highlight available>\n(Internal Error: the error is on line \(location.line) of a document that has only \(lines.count) lines.)\n"
        }

        // Single line highlights (the most common)
        if location.line == location.endLine {
            var out = "   |\n".blue
            out += String(format: "%3d| ".blue, location.line)
            out += "\(lines[location.line - 1])\n"
            out += "   | ".blue
            out += String(repeating: " ", count: location.col - 1)
            out += String(repeating: "^".red, count: location.endCol - (location.col - 1))
            out += "\n"
            return out
        }

        // Multiline highlights
        // TODO: at the moment they are inspired by elm error messages, which
        // on muliline errors only highlight the whole lines. However, we do
        // have more information and could highlight exactly where it starts and
        // and where it ends.
        var out = "   |\n".blue
        for l in location.line ... location.endLine {
            out += String(format: "%3d|".blue, l)
            out += ">".red
            out += "\(lines[l - 1])\n"
        }
        out += "   |\n".blue
        return out
    }
}
