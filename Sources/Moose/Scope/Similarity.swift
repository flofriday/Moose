/// This module finds similar objects in the current scope so that we can
/// suggest them to the user and help them find their error blazingly fast.
///
/// Variables
/// For variables the algorithm is quite easy, we search for similarly named
/// variables and suggest all that have a editing distance of 5 or < 33% which
/// ever is smaller. The result get sorted ascending by their Levenshtein
/// distance.
///
/// Functions
/// Functions are more complex because functions can be false if their name is
/// correct but their arguments are of the wrong type. Therefore we assign each
/// similar function a score by which we sort:
///     - Per wrong argument type: 0.25
///     - Per wrong argument number: 0.50
///     - Per levenshtein distance: -1

extension String {
    func chopPrefix(_ count: Int = 1) -> String {
        if count >= 0, count <= self.count {
            let indexStartOfText = index(startIndex, offsetBy: count)
            return String(self[indexStartOfText...])
        }
        return ""
    }
}

extension TypeScope {
    // NOTE: this function could be greatly improved if we use an upper bound.
    // For now it should be good enough and is not optimized at all.
    private func levenshtein(a: String, b: String) -> Int {
        if b == "" { return a.count }
        if a == "" { return b.count }

        if a.first == b.first {
            return levenshtein(a: a.chopPrefix(1), b: b.chopPrefix(1))
        }

        return 1 + min(
            levenshtein(a: a.chopPrefix(1), b: b),
            levenshtein(a: a, b: b.chopPrefix(1)),
            levenshtein(a: a.chopPrefix(1), b: b.chopPrefix(1))
        )
    }

    private func getSimilarHelper(variable: String) -> [(String, MooseType, Int)] {
        return variables.map { n, v in
            let (t, _) = v
            return (n, t, levenshtein(a: n, b: variable))
        }
        .filter { (_: String, _: MooseType, score) in
            score <= 5
        }
    }

    func getSimilar(variable: String) -> [(String, MooseType)] {
        // Find all variables in current scope
        var candidates = getSimilarHelper(variable: variable)

        // Add all from the outer scopes
        if let enclosing = enclosing {
            candidates += (enclosing.getSimilarHelper(variable: variable))
        }

        // Sort by relevance
        candidates = candidates.filter {
            // Reject all that would need more than 33% change
            Float($0.2) < Float(variable.count) * 0.33
        }
        .sorted {
            // The third element is the index and we want to sort on it.
            $0.2 < $1.2
        }

        // Format the result
        return candidates.map { (n: String, t: MooseType, _) in
            (n, t)
        }
    }

    func getSimilar(function: String, params: [MooseType]) -> [(String, FunctionType)] {
        var similars: [(String, FunctionType)] = []

        if let candidates = funcs[function] {
            similars += candidates.map { (function, $0) }
        }

        // TODO: add similar named functions

        if let enclosing = enclosing {
            similars += enclosing.getSimilar(function: function, params: params)
        }

        // Sort by arity
        similars.sort { a, b in
            abs(a.1.params.count - params.count) < abs(b.1.params.count - params.count)
        }

        return similars
    }
}
