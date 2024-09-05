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

// as a statement its a variable decleration but as an expression it is assignment
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

// for when expected a statement but an expression was also acceptable
ExpressionStmt :: struct 
{
    expr: ^Expr
}

BlockStmt :: struct 
{
    statments: [dynamic]^Stmt
}

IfStmt :: struct 
{
    condition: ^Expr,
    branch: BlockStmt
}

FnDecleration :: struct 
{
    name: ^lexing.Token,
    args: [dynamic]^Expr,
    body: BlockStmt,
}

ReturnStmt :: struct 
{
    values: [dynamic]^Expr
}

Stmt :: union 
{
    VarPair,
    IfStmt,
    BlockStmt,
    ExpressionStmt,
    FnDecleration,
    ReturnStmt,
}

Parser :: struct 
{
    token_offset: int,
    tokens: []lexing.Token,
    last_indent: int,
    statements: [dynamic]^Stmt,
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

free_a_stmt :: proc(root: ^Stmt)
{
    #partial switch v in root 
    {
    case VarPair:
        free_expr(v.value)
        free(root)
    }
}

free_all_stmt :: proc(stmts: []^Stmt)
{
    for stmt in stmts
    {
        free_a_stmt(stmt)
    }

    delete(stmts)
}

free_stmt :: proc{free_a_stmt, free_all_stmt}

parse_tokens :: proc(tokens: []lexing.Token) -> Parser 
{
    parser := Parser { tokens = tokens }

    // parser.root = expression(&parser)

    for _, had_err := parser.error.?; !had_err && !match_token(&parser, .Eof);
    {
        stmt := decleration(&parser)
        if stmt == nil 
        {
            break
        }
        append(&parser.statements, stmt)
    }

    return parser
}