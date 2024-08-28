package main

import "core:fmt"
import "core:os"
import "core:log"
import "frontend/lexer"

main :: proc() 
{
    contents, ok := os.read_entire_file("./tests/tokens.prog")

    if !ok do log.fatal("could not read source file")

    lex := lexer.create(cast(string)contents)

    token: lexer.Token 

    for true 
    {
        token = lexer.advance_token(&lex)

        if token.type == .Error {
            log.fatalf("error while lexing ({}:{}): {}", token.line, token.column, token.value)
        }

        fmt.println(token)

        if token.type == .Eof 
        {
            break
        }
    }
}
