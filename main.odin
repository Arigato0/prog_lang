package main

import "core:fmt"
import "core:os"
import "core:log"
import "frontend/lexer"
import "frontend/parser"

build_tokens :: proc(source: []byte) -> (out: [dynamic]lexer.Token)
{
    lex := lexer.create(source)

    lex.keywords = 
    { 
        "struct" = .Struct,
        "fn" = .Fn,
        "for" = .For,
        "while" = .While,
        "if" = .If,
        "else" = .Else,
        "nil" = .Nil,
        "true" = .True,
        "false" = .False,
        "return" = .Return,
        "pass" = .Pass
    }

    for true 
    {
        token := lexer.advance_token(&lex)

        if token.type == .Error {
            fmt.printfln("error while lexing ({}:{}): {}", token.line, token.column, token.value)
            return nil
        }

        append(&out, token)

        if token.type == .Eof 
        {
            break
        }
    }

    return out
}

print_tokens :: proc(tokens: [dynamic]lexer.Token)
{
    for &token in tokens 
    {
        value: any = token.value

        #partial switch _ in token.value 
        {
            case []byte: value = transmute(string) token.value.([]byte)
        }

        fmt.printfln("{}({}, {}:{})", 
        token.type, value, token.line, token.column)
    }
}

main :: proc() 
{
    contents, ok := os.read_entire_file("./tests/tokens.prog")

    if !ok 
    {
        fmt.println("could not read source file")
        return
    }

    tokens := build_tokens(contents)

    defer delete(tokens)

    if tokens == nil do return 

    print_tokens(tokens)

    expr := parser.Expr{}
    expr = parser.BinaryExpr {
        left = new(parser.Expr), 
        operator = &tokens[0], 
        right = new(parser.Expr)
    }

    fmt.println(expr)
}
