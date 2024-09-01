package parsing

import "../lexing"
import "core:fmt"


Error :: struct 
{
    message: string,
    token: ^lexing.Token
}

BinaryExpr :: struct
{
    left: ^Expr,
    operator: ^lexing.Token,
    right: ^Expr,
}

UnaryExpr :: struct
{
    operator: ^lexing.Token,
    right: ^Expr,
}

GroupingExpr :: struct 
{
    inside: ^Expr
}

Literal :: union {^lexing.Token, bool}

LiteralExpr :: struct 
{
    value: Literal
}

IdentifierExpr :: struct 
{
    name: ^lexing.Token
}

VarPair :: struct 
{
    name: ^lexing.Token,
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

Stmt :: union 
{

}

Parser :: struct 
{
    token_offset: int,
    root: ^Expr,
    tokens: []lexing.Token,
    statements: [dynamic]Stmt,
    error: Maybe(Error)
}

free_expr :: proc(root: ^Expr)
{
    #partial switch v in root 
    {
    case BinaryExpr:
        free_expr(v.left)
        free_expr(v.right)
    case UnaryExpr:
        free(v.right)
    case GroupingExpr:
        free_expr(v.inside)
    case VarPair:
        free_expr(v.value)
    }

    free(root)
}

parse_tokens :: proc(tokens: []lexing.Token) -> Parser 
{
    parser := Parser { tokens = tokens }

    parser.root = expression(&parser)

    return parser
}