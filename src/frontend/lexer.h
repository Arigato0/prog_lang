#pragma once

#include "ds/array.h"
#include <stdbool.h>

#define LEXER_MAX_INDENT_LEVEL 256

typedef enum
{
    TK_ERROR,
    TK_INDENT,
    // to indicate no error happened
    TK_NO_TOKEN,
    TK_PLUS, TK_MINUS, TK_STAR, TK_FORWARD_SLASH,
    TK_PLUS_EQUAL, TK_MINUS_EQUAL,
    TK_EQUAL, TK_EQUAL_EQUAL, TK_COLON, TK_COLON_EQUAL, TK_COLON_COLON, TK_DOT,
    TK_LESS, TK_GREATER, TK_LESS_EQUAL, TK_GREATER_EQUAL,
    TK_BANG, TK_BANG_EQUAL,
    TK_INT, TK_FLOAT, TK_STRING,
    TK_IDENTIFIER, TK_IF, TK_ELSE, TK_PROC, TK_FOR, TK_WHILE,
    TK_RETURN, TK_STRUCT, TK_TRUE, TK_FALSE, TK_NIL, TK_IN, TK_PASS,
    TK_LEFT_BRACKET, TK_RIGHT_BRACKET, TK_LEFT_SQUARE_BRACKET, TK_RIGHT_SQUARE_BRACKET,
    TK_COMMA,

    TK_EOF
} TOKEN_TYPE;

static const char *TK_STRING_TABLE[] =
{
    "Error",
    "Indent",
    "NoToken",
    "Plus", "Minus", "Star", "ForwardSlash",
    "PlusEqual", "MinusEqual",
    "Equal", "EqualEqual", "Colon", "ColonEqual", "ColonColon", "Dot",
    "Less", "Greater", "LessEqual", "GreaterEqual",
    "Bang", "BangEqual",
    "Int", "Float", "String",
    "Identifier", "If", "Else", "Proc", "For", "While",
    "Return", "Struct", "True", "False", "Nil", "In", "Pass",
    "LeftBracket", "RightBracket", "LeftSquareBracket", "RightSquareBracket",
    "Comma",
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
    // checks if its in a middle of two tokens for generating indent tokens.
    bool in_middle;
    void *keyword_tree;
    TOKEN_TYPE last_token;
} Lexer;

int token_get_string_size(Token *token);
// buffer needs to be length token_get_string_size + 10
// use token_fmt_str for easier use
void token_to_string(Token *token, char *buffer);

void token_fmt_str(Array *array, Token *token);

void lexer_new(Lexer *lexer);

Token lexer_advance_token(Lexer *lexer);
