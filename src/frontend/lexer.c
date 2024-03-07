#include "lexer.h"
#include "ds/array.h"
#include "ds/trie.h"

#include <ctype.h>
#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void lexer_new(Lexer *lexer)
{
    memset(lexer, 0, sizeof(Lexer));

    lexer->current_line = 1;
}

Token lexer_new_error(Lexer *lexer, const char *error)
{
    Token out = 
    {
        .type = TK_ERROR,
        .str_value = error,
        .line = lexer->current_line,
        .column = lexer->current_column,
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

bool is_blank(char c)
{
    return 
       c == ' ' 
    || c == '\t' 
    || c == '\r' 
    || c == '\n'
    || c == '\0';
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

int lexer_get_indent_level(Lexer *lexer)
{
    if (lexer->indent_level >= LEXER_MAX_INDENT_LEVEL)
    {
        return -1;
    }

    return lexer->indent_table[lexer->indent_level];
}

Token lexer_handle_blank(Lexer *lexer)
{
    if (lexer->indent_level != 0 && lexer_get_indent_level(lexer) == lexer->indent_table[lexer->indent_level-1])
    {
        lexer->indent_level--;
        return lexer_build_token(lexer, TK_SCOPE_END);
    }

    char c;

    while ( (c = lexer_peak(lexer) ))
    {
        switch (c)
        {
            case ' ': 
            {
                lexer->indent_table[lexer->indent_level]++; 
                break;
            }
            case '\t': 
            {
                lexer->indent_table[lexer->indent_level] += 4; 
                break;
            }
            case '\r':
            case '\n': 
            {
                lexer->current_column = 1;
                lexer->indent_table[lexer->indent_level] = 0;
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

    if (lexer->last_token == TK_SCOPE_START)
    {
        if (lexer_get_indent_level(lexer) <= lexer->indent_table[lexer->indent_level-1])
        {
            return lexer_new_error(lexer, "indent level is less than previous scope");
        }
    }

    lexer->start = lexer->off;

    return lexer_build_token(lexer, TK_NO_TOKEN);
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

    c = lexer_peak(lexer);

    if (lexer_peak(lexer) == '.')
    {
        is_float = true;
        lexer_advance(lexer);
        goto scan_digits;
    }
    // TODO: handle integral suffixes here IE: 5f should become a float
    else if (!is_blank(c))
    {
        return lexer_new_error(lexer, "Unexpected character found while lexing digit");
    }

    return lexer_build_token(lexer, is_float ? TK_FLOAT : TK_INT);
}

bool lexer_is_id(char c)
{
    return isalnum(c) || c == '_';
}

Token lexer_build_id(Lexer *lexer)
{
    while (lexer_is_id(lexer_peak(lexer)))
    {
        lexer_advance(lexer);
    }

    Token token = lexer_build_token(lexer, TK_IDENTIFIER);

    TOKEN_TYPE tk_type = trie_match(lexer->keyword_tree, token.str_value);

    if (tk_type != 0)
    {
        token.type = tk_type;
    }

    return token;
}

Token advance_token(Lexer *lexer)
{
    if (lexer == NULL || lexer->src == NULL)
    {
        return lexer_new_error(lexer, "Lexer or lexer source is null");
    }

    Token blank_tk = lexer_handle_blank(lexer);

    if (blank_tk.type != TK_NO_TOKEN)
    {
        return blank_tk;
    }

    char c = lexer_advance(lexer);

    switch (c)
    {
        case '+': return lexer_build_token(lexer, TK_PLUS);
        case '-': return lexer_build_token(lexer, TK_MINUS);
        case '*': return lexer_build_token(lexer, TK_STAR);
        case '/': return lexer_build_token(lexer, TK_FORWARD_SLASH);
        case ':':
        {
            if (lexer_match_next(lexer, '='))
            {
                return lexer_build_token(lexer, TK_COLON_EQUAL);
            }

            lexer->indent_level++;
            return lexer_build_token(lexer, TK_SCOPE_START);
        } 
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
            else if (lexer_is_id(c))
            {
                return lexer_build_id(lexer);
            }
        }
    }

    return lexer_new_error(lexer, "Unknown token found");
}