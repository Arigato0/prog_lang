// +private package
package parsing

import "../lexing"
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

primary :: proc(using parser: ^Parser) -> ^Expr 
{
    expr := new(Expr)

    defer if _, had_err := error.?; had_err
    {
        free(expr)
    }

    if match_token(parser, .True)
    {
        expr^ = LiteralExpr{true}
    }
    else if match_token(parser, .False)
    {
        expr^ = LiteralExpr{false}
    }
    else if match_token(parser, .Int, .Float, .String)
    {
        previous := previous_token(parser)
        expr^ = LiteralExpr{previous}
    }
    else if match_token(parser, .Identifier)
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

            expr^ = call_expr
        }
        else if match_token(parser, .LeftBrack)
        {
            value := expression(parser) 

            // TODO: implement parsing slicing
            if value == nil do return nil

            ok := expect_token(parser, "exepcted matching bracket to close off subscript operation", .RightBrack)

            if !ok do return nil

            expr^ = SubScriptExpr {
                identifier = identifier,
                value = value
            }
        }
        else 
        {
            expr^ = IdentifierExpr{identifier}
        }
    }
    else if match_token(parser, .LeftParen)
    {
        inside := expression(parser)

        ok := expect_token(parser, "expected matching closing parenthesis", .RightParen)

        if !ok
        {
            return nil
        }

        expr^ = GroupingExpr {
            inside = inside
        }

    }
    else 
    {
        set_error(parser, "expected value")
        expr = nil
    }

    return expr
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

expression :: proc(using parser: ^Parser) -> ^Expr 
{
    return numeric_range(parser)
}