extension Interpreter {
    func visit(_ node: ForEachStatement) throws -> MooseObject {
        let indexable = try node.list.accept(self) as! IndexableObject

        pushEnvironment()
        defer { popEnvironment() }

        for i in 0 ... indexable.length() - 1 {
            do {
                _ = environment.update(variable: node.variable.value, value: indexable.getAt(index: i), allowDefine: true)
                _ = try node.body.accept(self)
            } catch is BreakSignal {
                break
            } catch is ContinueSignal {
                continue
            }
        }

        return VoidObj()
    }

    func visit(_ node: ForCStyleStatement) throws -> MooseObject {
        // First push a new Environment since the variable definitions only
        // apply here
        pushEnvironment()
        defer { popEnvironment() }

        if let preStmt = node.preStmt {
            _ = try preStmt.accept(self)
        }

        while true {
            // Check condition
            let condition: Bool? = (try node.condition.accept(self) as! BoolObj).value
            guard condition != nil else {
                throw NilUsagePanic(node: node.condition)
            }
            if condition == false {
                break
            }

            // Execute body
            do {
                _ = try node.body.accept(self)
            } catch is BreakSignal {
                break
            } catch is ContinueSignal {
                // Do nothing, this is just used to jump form the body to this
                // exact point.
            }

            // Post statement
            if let postEachStmt = node.postEachStmt {
                _ = try postEachStmt.accept(self)
            }
        }

        // Pop the loop environment
        return VoidObj()
    }

    func visit(_: Break) throws -> MooseObject {
        throw BreakSignal()
    }

    func visit(_: Continue) throws -> MooseObject {
        throw ContinueSignal()
    }
}
