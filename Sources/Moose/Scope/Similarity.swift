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
///     - Per levenshtein distance: 1

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

    private func getSimilarHelper(variable: String) -> [(String, MooseType, Float)] {
        var candidates = variables.map { n, v in
            let (t, _) = v
            return (n, t, Float(levenshtein(a: n, b: variable)))
        }
        .filter { (_: String, _: MooseType, score) in
            score <= 5 && score < Float(variable.count) * 0.33
        }

        // Add all from the outer scopes
        if let enclosing = enclosing {
            candidates += (enclosing.getSimilarHelper(variable: variable))
        }

        return candidates
    }

    func getSimilar(variable: String) -> [(String, MooseType)] {
        // Find all variables in current scope
        var candidates = getSimilarHelper(variable: variable)

        // Sort by relevance
        candidates.sort {
            // The third element is the index and we want to sort on it.
            $0.2 < $1.2
        }

        // Format the result
        return candidates.map { (n: String, t: MooseType, _) in
            (n, t)
        }
    }

    // TODO: we could do better here, since we shouldn't compare types but
    // look at the types that can match. For example a NilType is allowed for
    // a function that expects IntType.
    private func parmamsScore(a: [MooseType], b: [MooseType]) -> Float {
        if a.count == 0 {
            return Float(b.count) * 0.5
        }
        if b.count == 0 {
            return Float(a.count) * 0.5
        }

        // TODO: The creation of new arrays here is not the most sufficient
        // solution.
        if a[0] == b[0] {
            return parmamsScore(a: Array(a[1...]), b: Array(b[1...]))
        } else {
            return 0.25 + parmamsScore(a: Array(a[1...]), b: Array(b[1...]))
        }
    }

    func getSimilarHelper(function: String, params: [MooseType]) -> [(String, FunctionType, Float)] {
        var candidates: [(String, FunctionType, Float)] = []

        // Add functions with same name but different arguments
        /* if let funcs = funcs[function] {
             candidates += funcs.map { (function, $0, parmamsScore(a: params, b: $0.params)) }
         } */

        // Add functions with different name
        for (otherName, otherFuncs) in funcs {
            for otherFunc in otherFuncs {
                let levScore = Float(levenshtein(a: function, b: otherName))
                guard levScore <= 5 else {
                    continue
                }

                candidates.append((otherName, otherFunc, levScore + parmamsScore(a: params, b: otherFunc.params)))
            }
        }

        // Remove to bad candidates
        candidates = candidates.filter { (_: String, _: MooseType, score) in
            score <= 5 && score < Float(function.count) * 0.3
        }

        // Add functions from enclosing scopes
        if let enclosing = enclosing {
            candidates += enclosing.getSimilarHelper(function: function, params: params)
        }

        return candidates
    }

    func getSimilar(function: String, params: [MooseType]) -> [(String, FunctionType)] {
        var candidates = getSimilarHelper(function: function, params: params)

        // Sort by score
        candidates.sort { a, b in
            a.2 < b.2
        }

        // Format the result
        return candidates.map { c in
            (c.0, c.1)
        }
    }
}
