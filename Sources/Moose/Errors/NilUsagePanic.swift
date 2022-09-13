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
            out += Highlighter.highlight(location: location, sourcecode: sourcecode)
            out += "\n"
        }

        // Exact reason for this error
        out += "\(name)".red + ": You tried to dereference something that is nil."
        return out
    }
}
