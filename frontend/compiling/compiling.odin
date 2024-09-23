package compiling

import "../parsing"

OpCode :: enum
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

}

compile :: proc(using parser: ^parsing.Parser) -> Compiler
{

}