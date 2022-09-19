#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

class Cli {
    let typechecker: Typechecker
    let interpreter = Interpreter.shared

    init() throws {
        typechecker = try Typechecker()
    }

    func run() {
        if CommandLine.arguments.count == 1 {
            runRepl()
        } else {
            runFile(path: CommandLine.arguments[1])
        }
    }

    func runRepl() {
        print("Moose Interpreter (https://github.com/flofriday/Moose)")
        print("Written with <3 by Jozott00 and flofriday.")
        while true {
            print("> ", terminator: "")
            guard let line = readLine() else {
                return
            }
            run(line)
        }
    }

    func runFile(path: String) {
        do {
            let code = try String(contentsOfFile: path)
            run(code)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    func run(_ input: String) {
        var program: Program?

        do {
            let scanner = Lexer(input: input)
            let tokens = try scanner.scan()

            let parser = Parser(tokens: tokens)
            program = try parser.parse()

            try typechecker.check(program: program!)

            var args: [String] = []
            if CommandLine.argc > 2 {
                args = Array(CommandLine.arguments[2...])
            }
            try interpreter.run(program: program!, arguments: args)

        } catch let error as CompileError {
            print(error.getFullReport(sourcecode: input))
            return
        } catch let error as CompileErrorMessage {
            print(error.getFullReport(sourcecode: input))
            return
        } catch let error as RuntimeError {
            // print(error.getFullReport(sourcecode: input))
            print(error)
            print(error.message)
            exit(1)
        } catch let panic as Panic {
            print(panic.getFullReport(sourcecode: input))
            exit(1)
        } catch {
            print(error)
            exit(1)
        }
    }
}

try Cli().run()
