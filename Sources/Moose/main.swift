import Darwin

class Cli {
    let typechecker = Typechecker()
    let interpreter = Interpreter()

    func run() {
        if CommandLine.arguments.count == 1 {
            runRepl()
        } else if CommandLine.arguments.count == 2 {
            runFile(CommandLine.arguments[1])
        } else {
            fputs("Usage: \(CommandLine.arguments[0]) [script]\n", stderr)
            exit(1)
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

    func runFile(_ file: String) {
        fputs("Error: Reading from files is not yet supported\n", stderr)
        exit(1)
    }

    func run(_ input: String) {
        var program: Program?

        do {
            let scanner = Lexer(input: input)
            let tokens = try scanner.scan()

            let parser = Parser(tokens: tokens)
            program = try parser.parse()


            try typechecker.check(program: program!)

            try interpreter.run(program: program!)

        } catch let error as CompileError {
//        printCompileError(error: error, sourcecode: input)
            print(error.getFullReport(sourcecode: input))
            return
        } catch let error as RuntimeError {
            //print(error.getFullReport(sourcecode: input))
            exit(1)
        } catch {
            print(error)
            exit(1)
        }
    }
}

Cli().run()
