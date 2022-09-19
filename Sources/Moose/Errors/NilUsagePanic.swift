class NilUsagePanic: Panic {
    init() {
        super.init(name: "Nil usage panic", stacktrace: Stacktrace())
    }

    init(node: Expression) {
        super.init(name: "Nil usage panic", stacktrace: Stacktrace())
        stacktrace.push(node: node)
    }

    override func getFullReport(sourcecode: String) -> String {
        var out = super.getFullReport(sourcecode: sourcecode)

        // Exact reason for this error
        out += "\(name)".red + ": You tried to dereference something that is nil."
        return out
    }

    override func equals(other: Panic) -> Bool {
        return super.equals(other: other) && other is NilUsagePanic
    }
}
