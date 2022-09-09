class Stacktrace {
    var locations = [Location]()

    func push(node: Expression) {
        locations.append(node.location)
    }
}
