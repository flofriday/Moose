protocol Panic: Error {
    var name: String { get }
    var stacktrace: Stacktrace { get }

    func getFullReport(sourcecode: String) -> String
}
