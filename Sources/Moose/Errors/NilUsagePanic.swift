class NilUsagePanic: Panic {
    var name = "Nil usage panic"
    var stacktrace = Stacktrace()

    init() {}

    init(node: Expression) {
        stacktrace.push(node: node)
    }
}

extension NilUsagePanic {
    func getFullReport(sourcecode: String) -> String {
        var out = "-- \(name) \(String(repeating: "-", count: 80 - 4 - name.count))\n".red

        // Stacktrace:
        out += "Stacktrace (most recent call last):\n\n".blue
        for location in stacktrace.locations.reversed() {
            // The source code line causing the error
            out += String(format: "%3d| ".blue, location.line)
            out += "\(sourcecode.lines[location.line - 1])\n"
            out += String(repeating: " ", count: 5 + (location.col - 1))
            out += String(repeating: "^".red, count: location.endCol - (location.col - 1))
            out += "\n\n"
        }

        // Exact reason for this error
        out += "\(name)".red + ": You tried to dereference something that is nil."
        return out
    }
}
