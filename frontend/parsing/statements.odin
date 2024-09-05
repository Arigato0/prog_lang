// +private package
package parsing 

import "core:fmt"
import "../lexing"

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

    if !match_token(parser, .ColonEqual, .Equal)
    {
        rollback(parser)
        return expression_stmt(parser)
    }

    var_decl := new(Stmt)

    type := previous_token(parser).type

    pair := VarPair {
        name = identifier,
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

block_stmt :: proc(using parser: ^Parser) -> BlockStmt 
{
    block := BlockStmt {}

    current := current_token(parser) 

    if current.type != .Indent
    {
        set_error(parser, "expected an indentation at the begining of a block")
        block.statments = nil 
        return block
    }

    start_indent := current.value.(int)

    for !at_end(parser) && current_token(parser).type == .Indent
    {
        stmt := decleration(parser, start_indent)

        if stmt == nil 
        {
            return BlockStmt {statments = nil}
        }

        append(&block.statments, stmt)
    }

    last_indent = start_indent

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

    ok = expect_token(parser, "expected an identifier and a left parenthesis and a colon", .RightParen, .Colon)

    if !ok do return nil

    fn.body = block_stmt(parser) 

    if fn.body.statments == nil do return nil

    stmt := new(Stmt)

    stmt^ = fn

    return stmt
}

decleration :: proc(using parser: ^Parser, start_indent := 0) -> ^Stmt
{
    if match_token(parser, .Indent) 
    {
        level := previous_token(parser).value.(int)

        if level < start_indent 
        {
            return decleration(parser, start_indent)
        }
        if level > start_indent 
        {
            set_error(parser, "expected same indent level as start of function")
            return nil
        }

        return decleration(parser, start_indent)
    }
    else if match_token(parser, .Identifier)
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

    ok := expect_token(parser, "expected a colon after if statement condition", .Colon)

    if !ok do return nil 

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
    ok := expect_token(parser, "expected a colon after else statement condition", .Colon)

    if !ok do return nil 

    block := block_stmt(parser) 

    if block.statments == nil do return nil 

    stmt := new(Stmt)

    stmt^ = IfStmt {
        condition = nil,
        branch = block
    }

    return stmt
}

statement :: proc(using parser: ^Parser) -> ^Stmt
{
    if match_token(parser, .Indent)
    {
        last_indent = previous_token(parser).value.(int)
        return nil
    }
    else if match_token(parser, .Return)
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
    else 
    {
        return expression_stmt(parser)
    }
}