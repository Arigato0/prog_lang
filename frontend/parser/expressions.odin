// +private package
package parser

import "../lexer"


binary_rule :: #force_inline proc(using parser: ^Parser, rule: proc(^Parser) -> ^Expr, types: ..lexer.TokenType) -> ^Expr
{
    expr := rule(parser)

    for match_token(parser, ..types) 
    {
        operator := previous_token(parser)
        left := expr
        right := rule(parser)

        binary := &expr.(BinaryExpr) 

        binary.left = left
        binary.operator = operator
        binary.right = right
    }

    return expr
}

primary :: proc(using parser: ^Parser) -> ^Expr 
{
    expr := new(Expr)

    #partial switch tokens[token_offset].type
    {
    case .True: 
        expr^ = LiteralExpr{true}
    case .False:
        expr^ = LiteralExpr{false}
    case .Nil:
        expr^ = LiteralExpr{nil}
    case .Int, .Float, .String:
        expr^ = LiteralExpr{previous_token(parser)}
    }

    return expr
}

unary :: proc(using parser: ^Parser) -> ^Expr 
{
    if match_token(parser, .Bang, .Minus) 
    {
        operator := previous_token(parser)
        expr := unary(parser)

        unary := &expr.(UnaryExpr) 

        unary.right = expr
        unary.operator = operator
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