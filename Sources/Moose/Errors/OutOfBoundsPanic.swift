class OutOfBoundsPanic: Panic {
    var length: Int64
    var attemptedIndex: Int64

    init(length: Int64, attemptedIndex: Int64) {
        self.length = length
        self.attemptedIndex = attemptedIndex
        super.init(name: "Out of bounds panic", stacktrace: Stacktrace())
    }

    init(length: Int64, attemptedIndex: Int64, node: Expression) {
        self.length = length
        self.attemptedIndex = attemptedIndex
        super.init(name: "Out of bounds panic", stacktrace: Stacktrace())
        stacktrace.push(node: node)
    }

    override func getFullReport(sourcecode: String) -> String {
        var out = super.getFullReport(sourcecode: sourcecode)

        // Exact reason for this error
        out += "\(name)".red + ": you tried to access index \(attemptedIndex) on a collection that only holds \(length) items."
        return out
    }
}
