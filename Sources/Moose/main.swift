
let input = """
            12 + (3 * 10)
            a = 2
            mut b = 12
            """
let l = Lexer(input: input)
let p = Parser(l)

let prog = p.parseProgram()
print("Errors: \(p.errors)")
print("Program:")
print(prog)