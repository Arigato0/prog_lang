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

Value :: union 
{
    int,
    f32,
    string
}

Compiler :: struct 
{
    code: [dynamic]u8,
}

compile :: proc(using parser: ^parsing.Parser) -> (compiler: Compiler)
{
    for stmt in parser.statements
    {
        compile_stmt(&compiler, stmt)
    }

    return
}