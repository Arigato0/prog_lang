#include "lexer.h"
#include "ds/array.h"

#include <ctype.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void new_lexer(Lexer *lexer)
{
    memset(lexer, 0, sizeof(Lexer));

    lexer->current_line = 1;
}

Token make_error_token(const char *error)
{
    Token out = 
    {
        .type = TK_ERROR,
        .str_value = error,
        .line = 0,
        .column = 0,
    };

    return out;
}

Token lexer_build_token(Lexer *lexer, TOKEN_TYPE type)
{
    int token_len = lexer->off - lexer->start;

    char *substr = malloc(token_len+1);

    strncpy(substr, lexer->src + lexer->start, token_len);

    substr[token_len] = '\0';

    Token out = 
    {
        .type = type,
        .str_value = substr,
        .line = lexer->current_line,
        .column = lexer->current_column
    };

    lexer->start = lexer->off;
    lexer->last_token = type;

    return out;
}

int token_get_string_size(Token token)
{
    return 
    strlen(TK_STRING_TABLE[token.type]) 
    + strlen(token.str_value) 
    + sizeof(token.line) 
    + sizeof(token.column);
}

void token_to_string(Token token, char *buffer)
{
    if (buffer == NULL)
    {
        return;
    }

    sprintf(buffer, "%s(value: %s, %d:%d)", 
    TK_STRING_TABLE[token.type], token.str_value, token.line, token.column);
}

void token_fmt_str(Array *array, Token token)
{
    int tk_len = token_get_string_size(token);

    // extra len for the format characters to create a string such as TokenName(value: token_string, line:column)
    tk_len += 10;

    if (array->len < tk_len)
    {
        array_resize(array, tk_len);
    }

    token_to_string(token, array->data);
}

bool lexer_at_end(Lexer *lexer)
{
    return lexer->off >= lexer->src_len;
}

char lexer_peak(Lexer *lexer)
{
    if (lexer_at_end(lexer))
    {
        return '\0';
    }

    return lexer->src[lexer->off];
}

char lexer_peak_next(Lexer *lexer)
{
    if (lexer_at_end(lexer) || lexer->off+1 >= lexer->src_len)
    {
        return '\0';
    }

    return lexer->src[lexer->off + 1];
}

char lexer_advance(Lexer *lexer)
{
    if (lexer_at_end(lexer))
    {
        return '\0';
    }

    lexer->current_column++;

    return lexer->src[lexer->off++];
}

bool lexer_is_blank(Lexer *lexer, char c)
{
    return 
       c == ' ' 
    || c == 't' 
    || c == '\r' 
    || c == '\n';
}

bool lexer_match_next(Lexer *lexer, char c)
{
    if (lexer_peak(lexer) == c)
    {
        lexer_advance(lexer);
        return true;
    }

    return false;
}

void lexer_handle_blank(Lexer *lexer)
{
    char c;

    while ( (c = lexer_peak(lexer) ))
    {
        switch (c)
        {
            case ' ': 
            {
                lexer->indent_level++; 
                break;
            }
            case '\t': 
            {
                lexer->indent_level += 2; 
                break;
            }
            case '\n': 
            {
                lexer->current_column = 1;
                lexer->indent_level = 0;
                lexer->current_line++;

                break;
            }
            case '#':
            {
                while (!lexer_at_end(lexer) && lexer_peak_next(lexer) != '\n')
                {
                    lexer->off++;
                }

                break;
            }
            default: goto while_end;
        }

        c = lexer_advance(lexer);    
    }

while_end:
    lexer->start = lexer->off;
}

Token lexer_build_if_match(Lexer *lexer, char c, TOKEN_TYPE if_match, TOKEN_TYPE default_token)
{
    if (lexer_match_next(lexer, c))
    {
        return lexer_build_token(lexer, if_match);
    }
    return lexer_build_token(lexer, default_token);
}

Token lexer_build_digit(Lexer *lexer)
{
    char c = lexer_peak(lexer);
    bool is_float = false;

scan_digits:

    while (!lexer_at_end(lexer) && isdigit(lexer_peak(lexer)))
    {
        c = lexer_advance(lexer);
    }

    if (lexer_peak(lexer) == '.')
    {
        is_float = true;
        lexer_advance(lexer);
        goto scan_digits;
    }

    return lexer_build_token(lexer, is_float ? TK_FLOAT : TK_INT);
}

Token advance_token(Lexer *lexer)
{
    if (lexer == NULL || lexer->src == NULL)
    {
        return make_error_token("Lexer or lexer source is null");
    }

    lexer_handle_blank(lexer);

    char c = lexer_advance(lexer);

    switch (c)
    {
        case '+': return lexer_build_token(lexer, TK_PLUS);
        case '-': return lexer_build_token(lexer, TK_MINUS);
        case '*': return lexer_build_token(lexer, TK_STAR);
        case '/': return lexer_build_token(lexer, TK_FORWARD_SLASH);
        case ':': return lexer_build_if_match(lexer, '=', TK_COLON_EQUAL, TK_COLON);
        case '=': return lexer_build_token(lexer, TK_EQUAL);
        case '(': return lexer_build_token(lexer, TK_LEFT_BRACKET);
        case ')': return lexer_build_token(lexer, TK_RIGHT_BRACKET);
        case '\0':
        {
            Token eof =
            {
                .type = TK_EOF,
                .str_value = "EOF",
                .line = lexer->current_line,
                .column = lexer->current_column
            };

            return eof;
        }
        default:
        {
            if (isdigit(c))
            {
                return lexer_build_digit(lexer);
            }
        }
    }

    return make_error_token("Unknown token found");
}
