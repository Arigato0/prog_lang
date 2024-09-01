package main

import "core:fmt"
import "core:os"
import "core:log"
import "frontend/lexing"
import "frontend/parsing"
import "base:intrinsics"
import "core:mem"
import "base:runtime"

PRINT_TOKENS :: #config(DEBUG_TOKENS, false)
PRINT_AST :: #config(DEBUG_AST, false)
TRACK_ALLOCS :: #config(DEBUG_MEMORY, false)

build_tokens :: proc(source: []byte) -> (out: [dynamic]lexing.Token)
{
    lexer := lexing.create(source)

    lexer.keywords = 
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

    defer delete(lexer.keywords)

    for true 
    {
        token := lexing.advance_token(&lexer)

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

print_tokens :: proc(tokens: [dynamic]lexing.Token)
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

print_literal :: proc(literal: parsing.Literal)
{
    #partial switch v in literal 
    {
    case ^lexing.Token:
        fmt.print(lexing.get_token_string(v))
    case:
        fmt.print(v)
    }
}

print_ast :: proc(root: ^parsing.Expr)
{
    if root == nil do return 
    
    #partial switch v in root 
    {
    case parsing.BinaryExpr:
        fmt.printf("({} ", lexing.get_token_string(v.operator))
        print_ast(v.left)
        print_ast(v.right)
        fmt.print(")")
    case parsing.UnaryExpr:
        fmt.printf("({} ", lexing.get_token_string(v.operator))
        print_ast(v.right)
        fmt.print(")")
    case parsing.LiteralExpr:
        print_literal(v.value)
    case parsing.GroupingExpr:
        print_ast(v.inside)
    case parsing.IdentifierExpr:
        fmt.print(lexing.get_token_string(v.name))
    }

    fmt.print(" ")
}

print_unfreed_memory :: proc(tracking_alloc: ^mem.Tracking_Allocator)
{
    alloc_size := len(tracking_alloc.allocation_map)

    if alloc_size > 0
    {
        unfreed_size := tracking_alloc.total_memory_allocated - tracking_alloc.total_memory_freed

        fmt.printfln("{} entries ({}B) unfreed:", alloc_size, unfreed_size)

        for _, entry in tracking_alloc.allocation_map
        {
            fmt.printfln("\t({}) {}", entry.size, entry.location)
        }
    }

    bad_free_size := len(tracking_alloc.bad_free_array)

    if bad_free_size > 0
    {
        fmt.printfln("{} bad frees:", bad_free_size)

        for entry in tracking_alloc.bad_free_array
        {
            fmt.printfln("\t({}) {}", entry.memory, entry.location)
        }
    }
}

main :: proc() 
{
    when TRACK_ALLOCS 
    {
        tracking_alloc: mem.Tracking_Allocator

        mem.tracking_allocator_init(&tracking_alloc, context.allocator)

        context.allocator = mem.tracking_allocator(&tracking_alloc)

        defer print_unfreed_memory(&tracking_alloc)
    }

    contents, ok := os.read_entire_file("./examples/parsing.prog")

    defer delete(contents)

    if !ok 
    {
        fmt.println("could not read source file")
        return
    }

    tokens := build_tokens(contents)

    defer delete(tokens)

    if tokens == nil do return
    
    when PRINT_TOKENS do print_tokens(tokens)

    parser := parsing.parse_tokens(tokens[:])

    defer parsing.free_expr(parser.root)

    if err, had_err := parser.error.?; had_err
    {
        fmt.printfln("error while parsing '{}' ({}:{}) {}", 
            lexing.get_token_string(err.token), err.token.line, err.token.column, err.message)
        return
    }

    when PRINT_AST 
    {
        print_ast(parser.root)
        fmt.println()
    }

}
