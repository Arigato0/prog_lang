// +private package
package parser

import "../lexer"
import "core:fmt"

Rule :: proc(^Parser) -> ^Expr

binary_rule :: #force_inline proc(using parser: ^Parser, rule: Rule, types: ..lexer.TokenType) -> ^Expr
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

    defer if _, has_value := expr.(BinaryExpr); !has_value 
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
        previous := previous_token(parser)
        expr^ = IdentifierExpr{previous}
    }
    else if match_token(parser, .LeftParen)
    {
        inside := expression(parser)

        ok := expect_token(parser, .RightParen, "expected matching closing parenthesis")

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
        return nil
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

factor :: proc(using parser: ^Parser) -> ^Expr 
{
    return binary_rule(parser, unary, .Star, .ForwardSlash)
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

expression :: proc(using parser: ^Parser) -> ^Expr 
{
    return equality(parser)
}