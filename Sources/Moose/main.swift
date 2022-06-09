import Darwin

if (CommandLine.arguments.count == 1) {
    runRepl()
} else if (CommandLine.arguments.count == 2) {
    runFile(CommandLine.arguments[1])
} else {
    fputs("Usage: \(CommandLine.arguments[0]) [script]\n", stderr)
    exit(1)
}

func runRepl() {
    print("Moose Interpreter (https://github.com/flofriday/Moose)")
    print("Written with <3 by Jozott00 and flofriday.")
    while (true) {
        print("> ", terminator: "")
        guard let line = readLine() else {
            return
        }
        run(line)
    }
}

func runFile(_ file: String) {
    fputs("Error: Reading from files is not yet supported\n", stderr);
    exit(1)
}

func run(_ input: String) {
    let scanner = Lexer(input: input)
    let tokens = scanner.scan()

    let parser = Parser(tokens: tokens)
    let statements = parser.parse()
    for statement in statements {
        //statement.print()
    }

//    let checker = TypeChecker(statements: statements)
//    checker.check()

    let interpreter = Interpreter(statements: statements)
    interpreter.run();
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