package parser

import "../lexer"
import "core:fmt"


Error :: struct 
{
    message: string,
    token: ^lexer.Token
}

BinaryExpr :: struct
{
    left: ^Expr,
    operator: ^lexer.Token,
    right: ^Expr,
}

UnaryExpr :: struct
{
    operator: ^lexer.Token,
    right: ^Expr,
}

GroupingExpr :: struct 
{
    inside: ^Expr
}

Literal :: union {^lexer.Token, bool}

LiteralExpr :: struct 
{
    value: Literal
}

IdentifierExpr :: struct 
{
    name: ^lexer.Token
}

VarPair :: struct 
{
    name: ^lexer.Token,
    value: ^Expr
}

Expr :: union 
{
    BinaryExpr,
    UnaryExpr,
    GroupingExpr,
    LiteralExpr,
    IdentifierExpr,
    VarPair,
}

Parser :: struct 
{
    token_offset: int,
    root: ^Expr,
    tokens: []lexer.Token,
    error: Maybe(Error)
}

parse_tokens :: proc(tokens: []lexer.Token) -> Parser 
{
    parser := Parser { tokens = tokens }

    parser.root = expression(&parser)

    return parser
}