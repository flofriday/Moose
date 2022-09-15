class Panic: Error {
    var name: String
    var stacktrace: Stacktrace

    init(name: String, stacktrace: Stacktrace) {
        self.name = name
        self.stacktrace = stacktrace
    }

    func getFullReport(sourcecode: String) -> String {
        var out = "-- \(name) \(String(repeating: "-", count: 80 - 4 - name.count))\n".red

        // Stacktrace:
        out += "Stacktrace (most recent call last):\n\n".blue
        for location in stacktrace.locations.reversed() {
            // The source code line causing the error
            out += Highlighter.highlight(location: location, sourcecode: sourcecode)
            out += "\n"
        }

        return out
    }

    func equals(other: Panic) -> Bool {
        return name == other.name
    }
}
