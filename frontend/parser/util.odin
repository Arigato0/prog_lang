// +private package
package parser 

import "../lexer"

at_end :: proc(using parser: ^Parser) -> bool
{
    return token_offset >= len(tokens)
}

check_token :: proc(using parser: ^Parser, type: lexer.TokenType) -> bool
{
   if at_end(parser) do return false 

   return tokens[token_offset].type == type
}

previous_token :: proc(using parser: ^Parser) -> ^lexer.Token
{
    if token_offset - 1 < 0 do return &tokens[0]

    return &tokens[token_offset-1]
}

current_token :: proc(using parser: ^Parser) -> ^lexer.Token
{
    if at_end(parser) do return nil

    return &tokens[token_offset]
}


advance :: proc(using parser: ^Parser) 
{
    if token_offset >= len(tokens) do return

    token_offset += 1
}

match_token :: proc(using parser: ^Parser, types: ..lexer.TokenType) -> bool
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

expect_token :: proc(using parser: ^Parser, type: lexer.TokenType, message: string) -> bool
{
    if (match_token(parser, type)) do return true
    
    error_message = message

    return false
}