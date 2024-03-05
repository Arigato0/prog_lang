#pragma once

#include "ds/array.h"

typedef enum 
{
    TK_ERROR,
    TK_PLUS, TK_MINUS, TK_STAR, TK_FORWARD_SLASH,
    TK_EQUAL, TK_COLON, TK_COLON_EQUAL, 
    TK_INT, TK_FLOAT, TK_STRING,
    TK_IDENTIFIER, TK_IF, TK_FUNC, 
    TK_LEFT_BRACKET, TK_RIGHT_BRACKET,

    TK_SCOPE_START, TK_SCOPE_END, 

    TK_EOF
} TOKEN_TYPE;

static const char *TK_STRING_TABLE[] =
{
    "Error",
    "Plus", "Minus", "Star", "ForwardSlash",
    "Equal", "Colon", "ColonEqual",
    "Int", "Float", "String",
    "Identifier", "If", "Func",
    "LeftBracket", "RightBracket",
    "ScopeStart", "ScopeEnd",
    "EOF"
};

typedef struct 
{
    TOKEN_TYPE type;
    const char *str_value;
    int line;
    int column;
} Token;

typedef struct 
{
    const char *src;
    int src_len;
    int off;
    int start;
    int current_line;
    int current_column;
    int indent_level;
    TOKEN_TYPE last_token;
} Lexer;

int token_get_string_size(Token token);
// buffer needs to be length token_get_string_size + 10
// use token_fmt_str for easier use
void token_to_string(Token token, char *buffer);

void token_fmt_str(Array *array, Token token);

void new_lexer(Lexer *lexer);

Token advance_token(Lexer *lexer);
