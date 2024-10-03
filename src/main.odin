package main

import "frontend/lexing"
import "frontend/parsing"
import "backend/compiling"
import "debugging"

import "core:fmt"
import "core:os"
import "core:log"
import "base:intrinsics"
import "core:mem"
import "base:runtime"

PRINT_TOKENS :: #config(DEBUG_TOKENS, false)
PRINT_AST :: #config(DEBUG_AST, false)
TRACK_ALLOCS :: #config(DEBUG_MEMORY, false)

main :: proc() 
{
    when TRACK_ALLOCS 
    {
        tracking_alloc: mem.Tracking_Allocator

        mem.tracking_allocator_init(&tracking_alloc, context.allocator)

        context.allocator = mem.tracking_allocator(&tracking_alloc)

        defer debugging.print_unfreed_memory(&tracking_alloc)
    }

    // TODO: take the source filepath from system args
    contents, ok := os.read_entire_file("./examples/parsing.prog")

    defer delete(contents)

    if !ok 
    {
        fmt.println("could not read source file")
        return
    }

    tokens := lexing.build_tokens(contents)

    defer delete(tokens)

    if tokens == nil do return
    
    when PRINT_TOKENS do debugging.print_tokens(tokens)

    parser := parsing.parse_tokens(tokens[:])

    defer parsing.free_parser(&parser)

    if err, had_err := parser.error.?; had_err
    {
        fmt.printfln("error while parsing '{}' ({}:{}) {}", 
            lexing.get_token_string(err.token), err.token.line, err.token.column, err.message)
        return
    }

    when PRINT_AST 
    {
        debugging.print_ast(&parser)
    }

    compiler := compiling.compile(&parser)
}
