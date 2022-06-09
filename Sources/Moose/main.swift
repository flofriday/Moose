
let input = """
            mut albert = "//hello
            """
let l = Lexer(input: input)

var t = l.nextToken()
while t.type != .EOF {
    print(t)
    t = l.nextToken()
}
print(t)