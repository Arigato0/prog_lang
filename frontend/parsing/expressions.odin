// +private package
package parsing

import "../lexing"
import "../../util"
import "core:fmt"

Rule :: proc(^Parser) -> ^Expr

binary_rule :: #force_inline proc(using parser: ^Parser, rule: Rule, types: ..lexing.TokenType) -> ^Expr
{
    expr := rule(parser)

    for match_token(parser, ..types) 
    {
        operator := previous_token(parser)
        right := rule(parser)

        new_expr := new(Expr)

        new_expr^ = BinaryExpr {
            left = expr,
            operator = operator,
            right = right,
        }

        expr = new_expr
    }

    return expr
}

match_expr :: proc(using parser: ^Parser) -> ^Expr 
{
    expr := MatchExpr {}

    expr.value = expression(parser)

    if expr.value == nil do return nil

    expr.cases = block_stmt(parser, proc(using parser: ^Parser) -> ^Stmt
    {
        match_case := MatchCase {}

        match_case.value = expression(parser)

        if match_case.value == nil do return nil 

        if check_next_token(parser, .Indent)
        {
            match_case.body = block_stmt(parser)

            if match_case.body.statments == nil do return nil
        }
        else 
        {
            ok := expect_token(parser, "expected a colon after match case value", .Colon)
            
            if !ok do return nil 

            append(&match_case.body.statments, make_stmt(expression(parser)))
        }

        return make_stmt(match_case)
    })

    if expr.cases.statments == nil do return nil

    return make_expr(expr)
}

identifier_expr :: proc(using parser: ^Parser) -> ^Expr 
{
    identifier := previous_token(parser)

    if match_token(parser, .LeftParen)
    {
        call_expr := CallExpr { name = identifier }

        for !check_token(parser, .RightParen) && !at_end(parser)
        {
            // TODO: add support for var pairs so named arguments can work here
            append(&call_expr.arguments, expression(parser))

            if !match_token(parser, .Comma)
            {
                break
            }
        }

        ok := expect_token(parser, "expected a right parenthesis to match left one", .RightParen)

        if !ok do return nil

        return make_expr(call_expr)
    }
    else if match_token(parser, .LeftBrack)
    {
        value := expression(parser) 

        // TODO: implement parsing slicing
        if value == nil do return nil

        ok := expect_token(parser, "exepcted matching bracket to close off subscript operation", .RightBrack)

        if !ok do return nil

        return make_expr(SubScriptExpr {
            identifier = identifier,
            value = value
        })
    }
    else if match_token(parser, .Dot)
    {
        ok := expect_token(parser, "exepcted identifier to access a property of an object", .Identifier)

        if !ok do return nil   

        return make_expr(PropertyAccessExpr {
            object = identifier,
            property = previous_token(parser)
        })
    }
    else 
    {
        return make_expr(IdentifierExpr{identifier})
    }
}

primary :: proc(using parser: ^Parser) -> ^Expr 
{

    if match_token(parser, .True)
    {
        return make_expr(LiteralExpr{true})
    }
    else if match_token(parser, .False)
    {
        return make_expr(LiteralExpr{false})
    }
    else if match_token(parser, .Int, .Float, .String)
    {
        previous := previous_token(parser)
        return make_expr(LiteralExpr{previous})
    }
    else if match_token(parser, .Identifier)
    {
        return identifier_expr(parser)
    }
    else if match_token(parser, .LeftParen)
    {
        inside := expression(parser)

        ok := expect_token(parser, "expected matching closing parenthesis", .RightParen)

        if !ok
        {
            return nil
        }

        return make_expr(GroupingExpr {
            inside = inside
        })
    }
    else 
    {
        set_error(parser, "expected value")
        return nil
    }
}

unary :: proc(using parser: ^Parser) -> ^Expr 
{
    if match_token(parser, .Bang, .Minus) 
    {
        operator := previous_token(parser)
        expr := unary(parser) 

        unary := new(Expr) 
        unary^ = UnaryExpr {
            operator = operator,
            right = expr
        }

        return unary
    }

    return primary(parser)
}

power :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, unary, .Caret)
}

factor :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, power, .Star, .ForwardSlash)
}

term :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, factor, .Plus, .Minus)
}

comparison :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, term, .Less, .LessEqual, .Greater, .GreaterEqual)
}

equality :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, comparison, .EqualEqual, .BangEqual)
}

numeric_range :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, equality, .DotDot, .DotEqual)
}

assignment_expr :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, numeric_range, .Equal, .PlusEqual, .MinusEqual, .ForwardSlashEqual, .MinusEqual)
}

expression :: proc(using parser: ^Parser) -> ^Expr 
{
    return assignment_expr(parser)
}