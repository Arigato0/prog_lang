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
        fprintf(stderr, "Could not read source file\n");
        return -1;
    }

    lexer.src = src;
    lexer.src_len = src_len;

    Token token;

    do 
    {
        token = advance_token(&lexer);

        int tk_len = token_get_string_size(token);

        // extra len for the format characters to create a string such as TokenName(value: token_string, line:column)
        tk_len += 10;

        char *token_string_buff = malloc(tk_len+1);

        token_to_string(token, token_string_buff);

        printf("%s\n", token_string_buff);

        free(token_string_buff);

    } while (token.type != TK_EOF);

    free(src);
}

