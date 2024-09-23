package parsing

import "../lexing"
import "core:fmt"

Error :: struct 
{
    message: string,
    token: ^lexing.Token
}

SubScriptExpr :: struct 
{
    identifier: ^lexing.Token,
    value: ^Expr,
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

CallExpr :: struct 
{
    name: ^lexing.Token,
    arguments: [dynamic]^Expr,
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

PropertyAccessExpr :: struct 
{
    object: ^lexing.Token,
    property: ^lexing.Token,
}

Expr :: union 
{
    BinaryExpr,
    UnaryExpr,
    GroupingExpr,
    LiteralExpr,
    IdentifierExpr,
    CallExpr,
    SubScriptExpr,
    PropertyAccessExpr,
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

// is used for if, else if, and else. it will be else, if condition is nil
IfStmt :: struct 
{
    is_elif: bool,
    condition: ^Expr,
    branch: BlockStmt
}

FnDecleration :: struct 
{
    name: ^lexing.Token,
    args: [dynamic]^Expr,
    body: BlockStmt,
}

StructDecleration :: struct 
{
    name: ^lexing.Token,
    interface: ^lexing.Token,
    ctor: ^Stmt,
    dtor: ^Stmt,
    methods: BlockStmt,
}

ReturnStmt :: struct 
{
    values: [dynamic]^Expr
}

ForInStmt :: struct 
{
    element1: ^lexing.Token,
    element2: ^lexing.Token,
    range: ^Expr,
    body: BlockStmt,
}

ForStmt :: struct 
{
    initializer: ^Expr,
    condition: ^Expr,
    update: ^Expr,
    body: BlockStmt,
}

WhileStmt :: struct 
{
    condition: ^Expr,
    body: BlockStmt,
}

VarDeclStmt :: struct 
{
    name: ^lexing.Token,
    init_value: ^Expr,
}

Stmt :: union 
{
    VarDeclStmt,
    IfStmt,
    BlockStmt,
    ExpressionStmt,
    FnDecleration,
    ReturnStmt,
    ForStmt,
    ForInStmt,
    WhileStmt,
    StructDecleration,
}

Parser :: struct 
{
    token_offset: int,
    tokens: []lexing.Token,
    last_indent: int,
    decl_table: map[string]lexing.TokenType,
    statements: [dynamic]^Stmt,
    error: Maybe(Error)
}

free_expr :: proc(root: ^Expr)
{
    switch v in root 
    {
    case BinaryExpr:
        free_expr(v.left)
        free_expr(v.right)
    case UnaryExpr:
        free(v.right)
    case GroupingExpr:
        free_expr(v.inside)
    case LiteralExpr:
    case IdentifierExpr:
    case PropertyAccessExpr:
    case CallExpr:
        free_all_expr(v.arguments)
    case SubScriptExpr:
        free_expr(v.value)
    }

    free(root)
}

free_all_expr :: proc(exprs: [dynamic]^Expr)
{
    for expr in exprs 
    {
        free_expr(expr)
    }

    delete(exprs)
}

free_a_stmt :: proc(root: ^Stmt)
{
    switch v in root 
    {
    case VarDeclStmt:
        free_expr(v.init_value)
    case IfStmt:
        free_expr(v.condition)
        free_block(v.branch)
    case ExpressionStmt:
        free_expr(v.expr)
    case FnDecleration:
        free_all_expr(v.args)
        free_block(v.body)
    case ReturnStmt:
        free_all_expr(v.values)
    case ForStmt:
        free_expr(v.condition)
        free_expr(v.initializer)
        free_expr(v.update)
        free_block(v.body)
    case ForInStmt:
        free_expr(v.range)
        free_block(v.body)
    case WhileStmt:
        free_expr(v.condition)
    case StructDecleration:
        free_block(v.methods)
    case BlockStmt:
    }

    free(root)
}

free_block :: proc(block: BlockStmt)
{
    free_all_stmt(block.statments[:])
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

free_parser :: proc(using parser: ^Parser)
{
    free_all_stmt(statements[:])
    delete(decl_table)
}

parse_tokens :: proc(tokens: []lexing.Token) -> Parser 
{
    parser := Parser { tokens = tokens }

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