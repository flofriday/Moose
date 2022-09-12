class OutOfBoundsPanic: Panic {
    var name = "Out of bounds panic"
    var stacktrace = Stacktrace()
    var length: Int64
    var attemptedIndex: Int64

    init(length: Int64, attemptedIndex: Int64) {
        self.length = length
        self.attemptedIndex = attemptedIndex
    }

    init(length: Int64, attemptedIndex: Int64, node: Expression) {
        self.length = length
        self.attemptedIndex = attemptedIndex
        stacktrace.push(node: node)
    }
}

extension OutOfBoundsPanic {
    public func getFullReport(sourcecode: String) -> String {
        var out = "-- \(name) \(String(repeating: "-", count: 80 - 4 - name.count))\n".red

        // Stacktrace:
        out += "Stacktrace (most recent call last):\n\n".blue
        for location in stacktrace.locations.reversed() {
            // The source code line causing the error
            out += Highlighter.highlight(location: location, sourcecode: sourcecode)
            out += "\n"
        }

        // Exact reason for this error
        out += "\(name)".red + ": you tried to access index \(attemptedIndex) on a collection that only holds \(length) items."
        return out
    }
}
