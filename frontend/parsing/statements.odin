// +private package
package parsing 

import "core:fmt"
import "../lexing"

EMPTY_BLOCK :: BlockStmt { statments = nil }

expression_stmt :: proc(using parser: ^Parser) -> ^Stmt 
{
    stmt := new(Stmt)
    stmt^ = ExpressionStmt {
        expr = expression(parser)
    }
    return stmt
}

var_pair :: proc(using parser: ^Parser) -> ^Stmt 
{
    identifier := previous_token(parser)

    if !match_token(parser, .ColonEqual, .Equal, .PlusEqual, .MinusEqual, .ForwardSlashEqual, .MinusEqual)
    {
        rollback(parser)
        return expression_stmt(parser)
    }

    var_decl := new(Stmt)

    type := previous_token(parser).type

    pair := VarPair {
        name = identifier,
        operator = previous_token(parser),
        value = expression(parser)
    }
    
    if type == .ColonEqual 
    {
        var_decl^ = pair
    }
    else 
    {
        expr := new(Expr)
        expr^ = pair
        var_decl^ = ExpressionStmt { expr }
    }

    return var_decl
}

block_stmt :: proc(using parser: ^Parser, allowed_types: ..lexing.TokenType) -> (BlockStmt) 
{
    ok := expect_token(parser, "expected a colon at to begin block", .Colon)

    if !ok do return EMPTY_BLOCK

    if !check_token(parser, .Indent)
    {
        set_error(parser, "expected an indentation at the begining of a block")
        return EMPTY_BLOCK
    }
    
    block := BlockStmt {}

    defer if _, had_err := error.?; had_err 
    {
        free_all_stmt(block.statments[:])
    }

    start_indent := current_token(parser).value.(int)
    last_indent = start_indent
    
    for !at_end(parser) && last_indent == start_indent
    {
        if match_token(parser, .Indent)
        {
            last_indent = previous_token(parser).value.(int)
        }
        else 
        { // scope ended so break
            break
        }

        if !check_token(parser, ..allowed_types)
        {
            set_error(parser, "unexpected token type found")
            return EMPTY_BLOCK
        }
        else if last_indent > start_indent
        {
            set_error(parser, "indent level is greater than scope start indent")
            return EMPTY_BLOCK
        }

        stmt := decleration(parser)

        if stmt == nil 
        {
            return EMPTY_BLOCK
        }

        append(&block.statments, stmt)
    }

    return block
}

fn_decleration :: proc(using parser: ^Parser) -> ^Stmt
{
    ok := expect_token(parser, "expected an identifier", .Identifier)

    if !ok do return nil
   
    identifier := previous_token(parser)

    ok = expect_token(parser, "expected a '('", .LeftParen)

    if !ok do return nil

    fn := FnDecleration { name = identifier}

    for !check_token(parser, .RightParen) && !at_end(parser)
    {
        append(&fn.args, expression(parser))

        if !match_token(parser, .Comma)
        {
            break
        }
    }

    ok = expect_token(parser, "expected an identifier and a right parenthesis", .RightParen)
    
    if !ok do return nil

    if match_token(parser, .Arrow)
    {
        expr := expression_stmt(parser)

        append(&fn.body.statments, expr)
    }
    else if check_token(parser, .Colon)
    {
        fn.body = block_stmt(parser) 
    
        if fn.body.statments == nil do return nil
    }
    else 
    {
        set_error(parser, "expected a colon or arrow statement")
        return nil
    }

    stmt := new(Stmt)

    stmt^ = fn

    return stmt
}

decleration :: proc(using parser: ^Parser) -> ^Stmt
{
    if match_token(parser, .Identifier)
    {
        return var_pair(parser)
    }
    else if match_token(parser, .Fn)
    {
        return fn_decleration(parser)
    }
    else 
    {
        return statement(parser)
    }
}

return_stmt :: proc(using parser: ^Parser) -> ^Stmt 
{
    stmt := new(Stmt)

    return_stmt := ReturnStmt {}

    if !match_token(parser, .Terminate)
    {
        for 
        {
            append(&return_stmt.values, expression(parser))

            if !match_token(parser, .Comma)
            {
                break
            }
        } 
    }

    stmt^ = return_stmt

    return stmt
}

if_stmt :: proc(using parser: ^Parser) -> ^Stmt 
{
    is_elif := previous_token(parser).type == .Else 

    condition := expression(parser)

    block := block_stmt(parser) 

    if block.statments == nil do return nil 

    stmt := new(Stmt)

    stmt^ = IfStmt {
        is_elif = is_elif,
        condition = condition,
        branch = block
    }

    return stmt
}

else_stmt :: proc(using parser: ^Parser) -> ^Stmt 
{
    block := block_stmt(parser) 

    if block.statments == nil do return nil 

    stmt := new(Stmt)

    stmt^ = IfStmt {
        condition = nil,
        branch = block
    }

    return stmt
}

for_range_stmt :: proc(using parser: ^Parser, element1, element2: ^lexing.Token) -> ^Stmt
{
    for_range := ForInStmt {
        element1 = element1,
        element2 = element2,
    }

    for_range.range = expression(parser)

    block := block_stmt(parser) 

    if block.statments == nil do return nil 

    for_range.body = block

    stmt := new(Stmt)

    stmt^ = for_range

    return stmt
}

for_stmt :: proc(using parser: ^Parser) -> ^Stmt 
{
    if match_token(parser, .Identifier)
    {
        identifier := previous_token(parser)
        element2: ^lexing.Token
        
        if match_token(parser, .Comma)
        {
            ok := expect_token(parser, "expected a second identifier after comma", .Identifier)
            
            if !ok do return nil 
            
            element2 = previous_token(parser)
        }
        
        if match_token(parser, .In)
        {
            return for_range_stmt(parser, identifier, element2)
        }
    }

    // TODO: implement clasic for loops

    return nil
}

while_stmt :: proc(using parser: ^Parser) -> ^Stmt 
{
    expr := expression(parser)

    if expr == nil 
    {
        set_error(parser, "expected an expression")
        return nil
    }

    wstmt := WhileStmt { condition = expr }

    block := block_stmt(parser) 

    if block.statments == nil do return nil 

    wstmt.body = block

    stmt := new(Stmt)

    stmt^ = wstmt

    return stmt
}

struct_decl :: proc(using parser: ^Parser) -> ^Stmt 
{
    decl := StructDecleration {}

    ok := expect_token(parser, "expected identifier for struct", .Identifier)

    if !ok do return nil

    decl.name = previous_token(parser)

    if match_token(parser, .Implements)
    {
        ok := expect_token(parser, "expected identifier for struct", .Identifier)

        if !ok do return nil

        decl.interface = previous_token(parser)
    }

    decl.methods = block_stmt(parser, .Fn)

    if decl.methods.statments == nil do return nil

    stmt := new(Stmt)

    stmt^ = decl

    return stmt
}

statement :: proc(using parser: ^Parser) -> ^Stmt
{
    if match_token(parser, .Return)
    {
        return return_stmt(parser)
    }
    else if match_token(parser, .If)
    {
        return if_stmt(parser)
    }
    else if match_token(parser, .Else)
    {
        if match_token(parser, .If)
        {
            return if_stmt(parser)
        }
        return else_stmt(parser)
    }
    else if match_token(parser, .For)
    {
        return for_stmt(parser)
    }
    else if match_token(parser, .While)
    {
        return while_stmt(parser)
    }
    else if match_token(parser, .Struct)
    {
        return struct_decl(parser)
    }
    else 
    {
        return expression_stmt(parser)
    }
}