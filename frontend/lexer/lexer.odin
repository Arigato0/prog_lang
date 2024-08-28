package lexer

import "core:fmt"

TokenType :: enum 
{
    Error,
    Indent,
	Plus,
	Minus,
	ForwardSlash,
	Star,
    Eof,
}

TokenValue :: union #no_nil {string, int}

Token :: struct 
{
	line:   int,
	column: int,
	value:  TokenValue,
	type:   TokenType,
}

Lexer :: struct 
{
    source:    string,
	current:   int,
	offset:    int,
    column:    int,
    line:      int,
    indent:    int,
    in_middle: bool
}

create :: proc(source: string) -> (out: Lexer )
{
    out.line = 1
    out.source = source

    return out
}

advance_token :: proc(lexer: ^Lexer) -> Token 
{
    if lexer == nil || lexer.source == "" {
        return make_error(lexer, "either lexer or source string is nil or empty")
    }

    handle_blank(lexer)

    if should_indent(lexer) do return build_token(lexer, .Indent)

    reset(lexer)

    c := advance_stream(lexer)

    switch c 
    {
        case '+': return build_token(lexer, .Plus)
        case '-': return build_token(lexer, .Minus)
        case '/': return build_token(lexer, .ForwardSlash)
        case '*': return build_token(lexer, .Star)
        case 0:   return build_token(lexer, .Eof)
    }

    return make_error(lexer, "unknown character found")
}

