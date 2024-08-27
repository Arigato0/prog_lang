#include "ds/array.h"
#include "ds/trie.h"
#include "frontend/lexer.h"
#include "frontend/parser.h"
#include "util/io.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

void make_tokens(Lexer *lexer, Array *out_tokens)
{
    Token token;

    do
    {
        token = lexer_advance_token(lexer);

        if (token.type == TK_ERROR)
        {
            fprintf(stderr, "Error while lexing (%d:%d): %s\n",
            token.line, token.column, token.str_value);

            exit(-1);
        }

        array_append(out_tokens, &token);

    } while (token.type != TK_EOF);
}

void print_tokens(Array *tokens)
{
    for (int i = 0; i < tokens->len; i++)
    {
        Array token_str;

        array_new(&token_str, 1);

        Token *token = array_get(tokens, i);

        token_fmt_str(&token_str, token);

        printf("%s\n", token_str.data);

        array_free(&token_str);
    }
}

void parse_tokens(Parser *parser, Array *tokens)
{
    parse(parser);
}

void print_ast(Expr *root, int depth)
{
    if (root == NULL)
    {
        return;
    }

    for (int i = 0; i < depth; i++)
    {
        printf(" ");
    }

    depth++;
    
    switch (root->type)
    {
    case EXPR_ERROR:
        printf("ran into an error\n");
        break;
    case EXPR_BINARY:  
    {
        printf("%s:\n", root->as.binary.operator->str_value);
        print_ast(root->as.binary.left, depth);
        print_ast(root->as.binary.right, depth);
        break;
    }
    case EXPR_LITERAL:
        printf("%s:\n", root->as.literal.value->str_value);
        break;
    case EXPR_UNARY:
        printf("%s:\n", root->as.unary.operator->str_value);
        print_ast(root->as.unary.right, depth);
        break;
    case EXPR_IDENTIFIER:
      break;
    }
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
        {"struct", TK_STRUCT},
        {"true", TK_TRUE},
        {"false", TK_FALSE},
        {"nil", TK_NIL},
        {"in", TK_IN},
        {"pass", TK_PASS}
    };

    TrieNode *keyword_tree = trie_new_node();

    trie_set(keyword_tree, keywords, sizeof(keywords) / sizeof(Keyword));

    Lexer lexer;

    lexer_new(&lexer);

    Array src;

    array_new(&src, 1);

    read_file("parsing.prog", &src);

    if (src.len == 0)
    {
        fprintf(stderr, "could not read source file\n");
        return -1;
    }

    lexer.src = src.data;
    lexer.src_len = src.len;
    lexer.keyword_tree = keyword_tree;

    Array tokens;

    array_new(&tokens, sizeof(Token));

    make_tokens(&lexer, &tokens);

    print_tokens(&tokens);

    Parser parser;

    parser.tokens = &tokens;
    parser.lexer = &lexer;

    parse_tokens(&parser, &tokens);

    // printf("%s\n", parser.root->as.binary.left->as.literal.value->str_value);
    print_ast(parser.root, 0);

    array_free(&src);
    trie_free(keyword_tree);
}
