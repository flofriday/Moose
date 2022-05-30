
let input = """
            mut albert = 2

            """
let l = Lexer(input: input)

var t = l.nextToken()
while t.type != .EOF {
    print(t)
    t = l.nextToken()
}
print(t)