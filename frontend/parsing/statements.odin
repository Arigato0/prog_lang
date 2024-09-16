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

block_stmt :: proc(using parser: ^Parser, allowed_types: ..lexing.TokenType) -> BlockStmt 
{
    if !check_token(parser, .Indent)
    {
        set_error(parser, "expected an indentation at the begining of a block")
        return BlockStmt { statments = nil }
    }

    block := BlockStmt {}

    start_indent := current_token(parser).value.(int)
    last_indent = start_indent
    
    for !at_end(parser) && last_indent == start_indent
    {
        if match_token(parser, .Indent)
        {
            last_indent = previous_token(parser).value.(int)
        }
        else 
        {
            break
        }

        fmt.println(last_indent, start_indent)

        if last_indent > start_indent
        {
            set_error(parser, "indent level is greater than scope start indent")
            break
        }

        stmt := decleration(parser)

        if stmt == nil 
        {
            return BlockStmt {statments = nil}
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

    stmt := new(Stmt)

    defer if stmt == nil 
    {
        free(stmt)
    }
    
    if match_token(parser, .Arrow)
    {
        expr := expression_stmt(parser)

        append(&fn.body.statments, expr)
    }
    else if match_token(parser, .Colon)
    {
        fn.body = block_stmt(parser) 
    
        if fn.body.statments == nil do return nil
    }
    else 
    {
        set_error(parser, "expected a colon or arrow statement")
        return nil
    }

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

for_range_stmt :: proc(using parser: ^Parser, element1, element2: ^lexing.Token) -> ^Stmt
{
    for_range := ForInStmt {
        element1 = element1,
        element2 = element2,
    }

    for_range.range = expression(parser)

    ok := expect_token(parser, "expected a colon after for statement head", .Colon)

    if !ok do return nil 

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

    ok := expect_token(parser, "expected colon after while loop expression", .Colon)

    if !ok do return nil 

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

    ok = expect_sequence(parser, "expected a colon after struct signature", .Colon, .Indent) 

    if !ok do return nil

    start_indent := previous_token(parser).value.(int)
    last_indent = start_indent

    for !at_end(parser) && last_indent == start_indent
    {
        if match_token(parser, .Indent)
        {
            last_indent = previous_token(parser).value.(int)
        }
        
        ok = expect_sequence(parser, "exepcted either a function", .Fn)
        
        if !ok
        {
            return nil
        }
        
        fn := fn_decleration(parser)

        if fn == nil 
        {
            return nil
        }

        append(&decl.methods, fn)

        last_indent = start_indent
    }

    last_indent = start_indent

    stmt := new(Stmt)

    stmt^ = decl

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