package compiling

import "../../frontend/parsing"

OpCode :: enum u8
{
    Push,
    Pop,
    Add,
    Div,
    Mul,
    Sub,
}

Compiler :: struct 
{
    code: [dynamic]u8,
}

free_compiler :: proc(using compiler: ^Compiler)
{
    delete(code)
}

compile :: proc(using parser: ^parsing.Parser) -> (compiler: Compiler)
{
    for stmt in parser.statements
    {
        compile_stmt(&compiler, stmt)
    }

    return
}