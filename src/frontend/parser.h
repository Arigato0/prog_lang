#pragma once

#include "ds/array.h"
#include "frontend/lexer.h"


typedef struct 
{
    void *parent;
    Array children;
    Token token;
} AstNode;

typedef enum 
{
    PARSE_ERR_OK,
    PARSE_ERR_SYNTAX,
    PARSE_ERR_INVALID_OPERANDS,
} PARSER_ERROR;

typedef struct 
{
    AstNode *root;
    Lexer *lexer;
    Token current_token;
    PARSER_ERROR state;
} Parser;

PARSER_ERROR parse(Parser *parser);