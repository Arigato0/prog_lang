#include "ds/array.h"
#include "ds/trie.h"
#include "frontend/lexer.h"
#include "util/io.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

void print_tokens(Lexer *lexer)
{
    Token token;

    do 
    {
        token = lexer_advance_token(lexer);

        if (token.type == TK_ERROR)
        {
            fprintf(stderr, "Error while lexing (%d:%d): %s\n", 
            token.line, token.column, token.str_value);

            break;
        }

        Array token_str;

        array_new(&token_str, 1);

        token_fmt_str(&token_str, token);

        printf("%s\n", token_str.data);

        array_free(&token_str);

    } while (token.type != TK_EOF);
}

int main()
{
    Keyword keywords[] =
    {
        {"proc", TK_PROC},
        {"if", TK_IF},
        {"else", TK_ELSE},
        {"for", TK_FOR},
        {"while", TK_WHILE},
        {"return", TK_RETURN},
        {"class", TK_CLASS},
        {"true", TK_TRUE},
        {"false", TK_FALSE},
        {"nil", TK_NIL},
        {"in", TK_IN},
    };

    TrieNode *keyword_tree = trie_new_node();

    trie_set(keyword_tree, keywords, sizeof(keywords) / sizeof(Keyword));

    Lexer lexer;

    lexer_new(&lexer);
    
    Array src;

    array_new(&src, 1);

    read_file("tokens.prog", &src);

    if (src.len == 0)
    {
        fprintf(stderr, "could not read source file\n");
        return -1;
    }

    lexer.src = src.data;
    lexer.src_len = src.len;
    lexer.keyword_tree = keyword_tree;

    print_tokens(&lexer);

    array_free(&src);
    trie_free(keyword_tree);
}

