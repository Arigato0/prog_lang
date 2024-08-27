#include "parser.h"
#include "ds/array.h"
#include "stdlib.h"
#include "frontend/lexer.h"
#include <stdarg.h>
#include <stdio.h>

void parser_set_error(Parser *parser, char *message, PARSER_RESULT code)
{
    parser->error_message = message;
    parser->state = code;
}

Token* parser_current(Parser *parser)
{
    return (Token*)array_get(parser->tokens, parser->token_offset);
}

Token* parser_previous(Parser *parser)
{
    return (Token*)array_get(parser->tokens, parser->token_offset - 1);
}

void parser_advance(Parser *parser)
{
    if (parser->token_offset >= parser->tokens->len)
    {
        return;
    }

    parser->token_offset++;
}

Expr *parser_expr(Parser *parser);

// bool parser_match(Parser *parser, TOKEN_TYPE type)
// {
//     if (parser->current_token.type == type)
//     {
//         parser_advance(parser);
//         return true;
//     }

//     return false;
// }
//

bool parser_equals(Parser *parser, TOKEN_TYPE type)
{
    Token *current = parser_current(parser);

    if (current->type == TK_EOF)
    {
        return false;
    }

    return current->type == type;
}

bool parser_expect(Parser *parser, TOKEN_TYPE type, char *message)
{
    if (!parser_equals(parser, type))
    {
        // TODO: make this error message actually useful
        parser_set_error(parser, message, PARSE_ERR);
        return false;
    }

    parser_advance(parser);

    return true;
}

void parser_identifier(Parser *parser)
{
    // if (parser_match(parser, TK_LEFT_BRACKET))
    // {
    //     parser_function(parser);
    // }
    // else if (parser_match(parser, TK_DOT))
    // {
    //     parser_identifier(parser);
    // }
    // else
    // {
    //     parser_expr(parser);
    // }
}

bool _parser_match(Parser *parser, int count, ...)
{
    va_list args;

    va_start(args, count);

    bool matched = false;

    Token *current = parser_current(parser);

    for (int i = 0; i < count; i++)
    {
        int type = va_arg(args, int);

        if (current->type == type && parser->token_offset < parser->tokens->len)
        {
            parser_advance(parser);
            matched = true;
            break;
        }
    }

    va_end(args);

    return matched;
}

#define NUMARGS(...)  (sizeof((int[]){__VA_ARGS__})/sizeof(int))
#define PARSER_MATCH(parser, ...) _parser_match(parser, NUMARGS(__VA_ARGS__), __VA_ARGS__)

#define GENERATE_BINARY_EXPR_PROC(rule, ...)    \
Expr *expr = rule(parser);                      \
while (PARSER_MATCH(parser, __VA_ARGS__))       \
{                                               \
    Token *operator = parser_previous(parser);  \
                                                \
    Expr *right = rule(parser);                 \
                                                \
    Expr *new_expr = malloc(sizeof(Expr));      \
    new_expr->type = EXPR_BINARY;               \
    new_expr->as.binary.left = expr;            \
    new_expr->as.binary.operator = operator;    \
    new_expr->as.binary.right = right;          \
    expr = new_expr;                            \
}                                               \
                                                \
return expr;                                    \


Expr* parser_primary(Parser *parser)
{
    if (PARSER_MATCH(parser, TK_TRUE))
    {
        return &TRUE_LITERAL;
    }
    else if (PARSER_MATCH(parser, TK_FALSE))
    {
        return &FALSE_LITERAL;
    }
    else if (PARSER_MATCH(parser, TK_NIL))
    {
        return &NIL_LITERAL;
    }
    else if (PARSER_MATCH(parser, TK_STRING, TK_INT, TK_FLOAT))
    {
        Expr *expr = malloc(sizeof(Expr));
        expr->as.literal.value = parser_previous(parser);
        expr->type = EXPR_LITERAL;
        return expr;
    }
    else if (PARSER_MATCH(parser, TK_LEFT_BRACKET))
    {
        Expr *inside_expr = parser_expr(parser);

        bool ok = parser_expect(parser, TK_RIGHT_BRACKET, "expected a right bracket to match the left one");

        Expr *expr = malloc(sizeof(Expr));

        expr->as.single.expr = inside_expr;
        expr->type = EXPR_SINGLE;

        return inside_expr;
    }
    else if (PARSER_MATCH(parser, TK_IDENTIFIER))
    {
        Token *identifier = parser_previous(parser);
        Expr *expr = malloc(sizeof(Expr));

        if (PARSER_MATCH(parser, TK_LEFT_BRACKET))
        {
            expr->as.call.name = identifier;
            expr->type = EXPR_CALL;

            array_new(&expr->as.call.args, sizeof(Expr));

            do 
            {
                Expr *arg = parser_expr(parser);
                array_append(&expr->as.call.args, arg);
            } while (PARSER_MATCH(parser, TK_COMMA));

            parser_expect(parser, TK_RIGHT_BRACKET, "expected a ) to close off function call");
        }
        else  
        {
            expr->as.identifier.name = identifier;
            expr->type = EXPR_IDENTIFIER;
        }

        return expr;
    }
    else
    {
        return NULL;
    }
}

Expr* parser_unary(Parser *parser)
{
    if (PARSER_MATCH(parser, TK_BANG, TK_MINUS))
    {
        Token *operator = parser_previous(parser);

        Expr *right = parser_unary(parser);

        Expr *expr = malloc(sizeof(Expr));

        expr->type = EXPR_UNARY;
        expr->as.unary.operator = operator;
        expr->as.unary.right = right;

        return expr;
    }

    return parser_primary(parser);
}

Expr* parser_factor(Parser *parser)
{
    GENERATE_BINARY_EXPR_PROC(parser_unary, TK_STAR, TK_FORWARD_SLASH);
}

Expr* parser_term(Parser *parser)
{
    GENERATE_BINARY_EXPR_PROC(parser_factor, TK_MINUS, TK_PLUS);
}

Expr* parser_comparison(Parser *parser)
{
    GENERATE_BINARY_EXPR_PROC(parser_term, TK_GREATER, TK_LESS, TK_GREATER_EQUAL, TK_LESS_EQUAL);
}

Expr* parser_equality(Parser *parser)
{
    GENERATE_BINARY_EXPR_PROC(parser_comparison, TK_EQUAL_EQUAL, TK_BANG_EQUAL);
    // Expr *expr = parser_comparison(parser);

    // while (PARSER_MATCH(parser, TK_EQUAL_EQUAL, TK_BANG_EQUAL))
    // {
    //     Token operator = parser->previous_token;

    //     Expr *right = parser_comparison(parser);

    //     BinaryExpr binary =
    //     {
    //         .left = expr,
    //         .operator = operator,
    //         .right = right
    //     };

    //     expr->as.binary = binary;
    // }

    // return expr;
}

Expr* parser_function(Parser *parser)
{
    return parser_equality(parser);
}

Expr *parser_expr(Parser *parser)
{
    return parser_equality(parser);
}

Expr* parser_stmt(Parser *parser)
{
    if (PARSER_MATCH(parser, TK_IDENTIFIER))
    {

    }
}

void parse(Parser *parser)
{
    parser->state = PARSE_OK;
    parser->error_message = NULL;
    parser->token_offset = 0;


    parser->root = parser_expr(parser);


    // while (parser->token_offset < parser->tokens->len)
    // {
    //     parser_expr(parser);
    //     // parser_stmt(parser);
    // }
}
