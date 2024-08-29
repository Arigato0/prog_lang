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

print_literal :: proc(literal: parser.Literal)
{
    #partial switch v in literal 
    {
    case ^lexer.Token:
        fmt.print(lexer.get_token_string(v))
    case:
        fmt.print(v)
    }
}

print_ast :: proc(root: ^parser.Expr)
{
    fmt.print(" ")

    #partial switch v in root 
    {
    case parser.BinaryExpr:
        fmt.printf("({} ", lexer.get_token_string(v.operator))
        print_ast(v.left)
        print_ast(v.right)
        fmt.print(")")
    case parser.UnaryExpr:
        fmt.printf("({} ", lexer.get_token_string(v.operator))
        print_ast(v.right)
        fmt.print(")")
    case parser.LiteralExpr:
        print_literal(v.value)
    case parser.GroupingExpr:
        print_ast(v.inside)
    case parser.IdentifierExpr:
        fmt.print(lexer.get_token_string(v.name))
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

    root := parser.parse_tokens(tokens[:])

    if root == nil
    {
        fmt.println("root node was nil")
        return
    }

    print_ast(root)

    fmt.println()
}
