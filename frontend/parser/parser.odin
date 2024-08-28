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

LiteralExpr :: struct 
{
    value: ^lexer.Token
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
}

parse_tokens :: proc(tokens: []lexer.Token) -> ^Expr 
{
    parser := Parser{ tokens = tokens }

    parser.root_expr = expression(&parser)

    return parser.root_expr
}