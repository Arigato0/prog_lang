#include "ds/array.h"
#include "frontend/lexer.h"
#include "util/io.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

int main()
{
    Lexer lexer;

    new_lexer(&lexer);

    int src_len; 

    char *src = read_file("tokens.prog", &src_len);

    if (src == NULL)
    {
        fprintf(stderr, "could not read source file\n");
        return -1;
    }

    lexer.src = src;
    lexer.src_len = src_len;

    Token token;

    do 
    {
        token = advance_token(&lexer);

        Array token_str;

        array_new(&token_str, 1);

        token_fmt_str(&token_str, token);

        printf("%s\n", token_str.data);

        array_free(&token_str);

    } while (token.type != TK_EOF);

    free(src);
}

