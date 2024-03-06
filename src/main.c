#include "ds/array.h"
#include "ds/trie.h"
#include "frontend/lexer.h"
#include "util/io.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

int main()
{
    Keyword keywords[] =
    {
        {"func", TK_FUNC},
        {"if", TK_IF},
    };

    TrieNode *root = trie_new_node();

    trie_set(root, keywords, sizeof(keywords) / sizeof(Keyword));

    TOKEN_TYPE tk_type = trie_match(root, "if");

    if (tk_type == 0)
    {
        printf("could not match\n");
        return -1;
    }

    printf("%s\n", TK_STRING_TABLE[tk_type]);

    trie_free(root);

    // Lexer lexer;

    // lexer_new(&lexer);

    // Array src;

    // array_new(&src, 1);

    // read_file("tokens.prog", &src);

    // if (src.len == 0)
    // {
    //     fprintf(stderr, "could not read source file\n");
    //     return -1;
    // }

    // lexer.src = src.data;
    // lexer.src_len = src.len;

    // Token token;

    // do 
    // {
    //     token = advance_token(&lexer);

    //     Array token_str;

    //     array_new(&token_str, 1);

    //     token_fmt_str(&token_str, token);

    //     printf("%s\n", token_str.data);

    //     array_free(&token_str);

    // } while (token.type != TK_EOF);

    // array_free(&src);
}

