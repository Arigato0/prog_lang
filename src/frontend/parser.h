#pragma once

#include "ds/array.h"
#include "frontend/lexer.h"

typedef struct Expr Expr;

// represents a single expression which is useful for things like grouping
typedef struct
{
    Expr *expr;
} SingleExpr;

// represents any binary expression
typedef struct
{
    Expr *left;
    Token *operator;
    Expr *right;
} BinaryExpr;

// represents unary expressions
typedef struct
{
    Token *operator;
    Expr *right;
} UnaryExpr;

// represents true, false, nil, "hello", 42
typedef struct
{
    // TODO: make value type
    Token *value;
} LiteralExpr;



// represents variables and function names
typedef struct
{
    Token *name;
} IdentifierExpr;

// represents parser expression errors
typedef struct
{
    Token token;
    char *message;
} ErrorExpr;

struct Expr
{
    enum
    {
        EXPR_ERROR,
        EXPR_BINARY,
        EXPR_LITERAL,
        EXPR_UNARY,
        EXPR_IDENTIFIER,
    } type;

    union
    {
        ErrorExpr error;
        BinaryExpr binary;
        UnaryExpr unary;
        LiteralExpr literal;
        IdentifierExpr identifier;
    } as;

};

static const Expr TRUE_LITERAL = { .as.literal.value = (void*)1, .type = EXPR_LITERAL };
static const Expr FALSE_LITERAL = { .as.literal.value = (void*)0, .type = EXPR_LITERAL };
static const Expr NIL_LITERAL = { .as.literal.value = (void*)0, .type = EXPR_LITERAL };

typedef struct
{
    union
    {
        Array block;
    } as;
} Stmt;

typedef enum
{
    // everything is ok!
    PARSE_OK,
    // an error was found during parsing
    PARSE_ERR,
    // a syntax error happened during lexing. error is inside current_token
    PARSE_LEX_ERR,
} PARSER_RESULT;

typedef struct
{
    Expr *root;
    Lexer *lexer;
    size_t token_offset;
    Array *tokens;
    PARSER_RESULT state;
    const char *error_message;
} Parser;

void parse(Parser *parser);
