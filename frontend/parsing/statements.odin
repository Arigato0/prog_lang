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

    start_indent := current_token(parser).value.(int)

    for !at_end(parser)
    {
        if match_token(parser, .Indent) 
        {
            level := previous_token(parser).value.(int)

            if level != start_indent 
            {
                set_error(parser, "expected same indent level as start of function")
                return nil
            }
        }
        else 
        {
            break
        }
        
        stmt := decleration(parser)

        if stmt != nil 
        {
            append(&fn.body.statments, stmt)
        }
    }

    last_indent = start_indent

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
    else 
    {
        return expression_stmt(parser)
    }
}