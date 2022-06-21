import Darwin

if CommandLine.arguments.count == 1 {
    runRepl()
} else if CommandLine.arguments.count == 2 {
    runFile(CommandLine.arguments[1])
} else {
    fputs("Usage: \(CommandLine.arguments[0]) [script]\n", stderr)
    exit(1)
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
    } catch let error as CompileError {
        printCompileError(error: error, sourcecode: input)
        return
    } catch {
        print(error)
        exit(1)
    }

//    let checker = TypeChecker(statements: statements)
//    checker.check()

    let interpreter = Interpreter(program: program!)
    interpreter.run()
}

// TOOD: add colors AND move to CompileError itself
func printCompileError(error: CompileError, sourcecode: String) {
    var out = ""
    let lines = sourcecode.split(separator: "\n")

    for msg in error.messages {
        // The header
        out += "-- CompileError ----------------------------------------------------------------\n\n"

        // The source code line causing the error
        out += String(format: "%3d", msg.line)
        out += "| \(lines[msg.line - 1])\n"
        out += String(repeating: " ", count: 5 + msg.startCol)
        out += String(repeating: "^", count: msg.endCol - msg.startCol)
        out += "\n\n"

        // A detailed message explaining the error
        out += msg.message
        out += "\n\n"
    }
    print(out)
}

// let input = """
//             mut albert = 2

//             """
// let l = Lexer(input: input)

// var t = l.nextToken()
// while t.type != .EOF {
//     print(t)
//     t = l.nextToken()
// }
// print(t)
