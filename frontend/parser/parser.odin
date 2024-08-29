package parser

import "../lexer"

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
    root_expr: ^Expr,
    token_offset: int,
    tokens: []lexer.Token,
    // empty if nothing went wrong
    error_message: string
}

parse_tokens :: proc(tokens: []lexer.Token) -> ^Expr 
{
    parser := Parser{ tokens = tokens }

    parser.root_expr = expression(&parser)

    return parser.root_expr
}