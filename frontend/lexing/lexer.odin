package lexing

import "core:unicode"

TokenType :: enum 
{
    Error,
    Indent, Terminate,
	Plus, Minus, ForwardSlash, Star, Caret,
    PlusEqual, MinusEqual, ForwardSlashEqual, StarEqual,
    Float, Int, Identifier, String,
    Equal, EqualEqual, Less, Greater, 
    LessEqual, GreaterEqual, BangEqual,
    LeftParen, RightParen, LeftBrace, RightBrace, LeftBrack, RightBrack,
    Dot, DotDot, DotEqual, Comma, Arrow, Bang, ColonEqual, Colon, ColonColon,
    True, False, Nil, Return, Pass,
    Struct, Implements, Interface, Fn, For, While, If, Else, In,
    Eof,
}

TokenValue :: union #no_nil {[]byte, int}

Token :: struct 
{
	line:   int,
	column: int,
	value:  TokenValue,
	type:   TokenType,
}

Lexer :: struct 
{
    source:    []byte,
	current:   int,
	offset:    int,
    column:    int,
    line:      int,
    indent:    int,
    in_middle: bool,
    last_type: TokenType,
    keywords:  map[string]TokenType,
}

create :: proc(source: []byte) -> (out: Lexer )
{
    out.line = 1
    out.source = source

    return out
}

get_token_string :: #force_inline proc(using token: ^Token) -> string 
{
    #partial switch v in value 
    {
    case []byte:
        return transmute(string)v
    case:
        return ""
    }
}

advance_token :: proc(lexer: ^Lexer) -> Token 
{
    if lexer == nil || lexer.source == nil {
        return make_error(lexer, "either lexer or source string is nil or empty")
    }

    should_terminate := handle_blank(lexer)

    if should_terminate do return build_token(lexer, .Terminate)

    if should_indent(lexer) do return build_token(lexer, .Indent)

    reset(lexer)

    c := advance_stream(lexer)

    switch c 
    {
        case '(': return build_token(lexer, .LeftParen)
        case ')': return build_token(lexer, .RightParen)
        case '[': return build_token(lexer, .LeftBrack)
        case ']': return build_token(lexer, .RightBrack)
        case ',': return build_token(lexer, .Comma)
        case '^': return build_token(lexer, .Caret)
        case '+': return build_or_else(lexer, '=', .PlusEqual, .Plus)
        case '-': return build_or_else(lexer, '=', .MinusEqual, .Minus)
        case '/': return build_or_else(lexer, '=', .ForwardSlashEqual, .ForwardSlash)
        case '*': return build_or_else(lexer, '=', .StarEqual, .Star)
        case '.': 
            if match(lexer, '.')
            {
                return build_or_else(lexer, '=', .DotEqual, .DotDot)
            }
            else 
            {
                return build_token(lexer, .Dot)
            }
        case '=': 
            if match(lexer, '=')
            {
                return build_token(lexer, .EqualEqual)
            }
            else if match(lexer, '>')
            {
                return build_token(lexer, .Arrow)
            }
            else 
            {
                return build_token(lexer, .Equal)
            }
        case '<': return build_or_else(lexer, '=', .LessEqual, .Less)
        case '>': return build_or_else(lexer, '=', .GreaterEqual, .Greater)
        case '!': return build_or_else(lexer, '=', .BangEqual, .Bang)
        case '\'': fallthrough
        case '"': return build_string(lexer)
        case ':':
            if match(lexer, '=') do return build_token(lexer, .ColonEqual)

            else if match(lexer, ':') do return build_token(lexer, .ColonColon)

            else do return build_token(lexer, .Colon)
        case 0:   return build_token(lexer, .Eof)
        case:
            if unicode.is_digit(cast(rune)c) do return build_digit(lexer)
            else if is_identifier(c) do return build_identifier(lexer)
    }

    return make_error(lexer, "unknown character found")
}

