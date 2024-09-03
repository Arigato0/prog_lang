// +private package
package parsing 

import "../lexing"

at_end :: proc(using parser: ^Parser) -> bool
{
    return token_offset >= len(tokens)
}

check_token :: proc(using parser: ^Parser, type: lexing.TokenType) -> bool
{
   if at_end(parser) do return false 

   return tokens[token_offset].type == type
}

previous_token :: proc(using parser: ^Parser) -> ^lexing.Token
{
    if token_offset - 1 < 0 do return &tokens[0]

    return &tokens[token_offset-1]
}

current_token :: proc(using parser: ^Parser) -> ^lexing.Token
{
    if at_end(parser) do return nil

    return &tokens[token_offset]
}


advance :: proc(using parser: ^Parser) 
{
    if token_offset >= len(tokens) do return

    token_offset += 1
}

match_token :: proc(using parser: ^Parser, types: ..lexing.TokenType) -> bool
{
    for type in types 
    {
        if check_token(parser, type)
        {
            advance(parser)
            return true
        }
    }

    return false
}

set_error :: proc(using parser: ^Parser, message: string)
{
    error = Error {
        message,
        previous_token(parser)
    }
}

expect_token :: proc(using parser: ^Parser, message: string, types: ..lexing.TokenType) -> bool
{
    for type in types 
    {
        if (!match_token(parser, type)) 
        {
            set_error(parser, message)
            return false
        }
    }
    
    return true
}

rollback :: proc(using parser: ^Parser)
{
    token_offset -= 1
}