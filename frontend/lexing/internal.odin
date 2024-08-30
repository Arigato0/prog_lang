// +private package
package lexing

import "core:strings"
import "core:unicode"

make_error :: proc(using lexer: ^Lexer, message: string) -> Token 
{
    return Token{
        line = line,
        column = column,
        value = transmute([]byte)message,
        type = .Error
    }
}

at_end :: proc(using lexer: ^Lexer) -> bool 
{
    return offset >= len(source)
}

advance_stream :: proc (using lexer: ^Lexer) -> (out: u8) 
{
    if at_end(lexer) do return 0
    
    out = source[offset]
    
    column += 1
    offset += 1

    return out
}

reset :: proc(using lexer: ^Lexer)
{
    current = offset
    indent = 0
    in_middle = true
}

build_token :: proc(using lexer: ^Lexer, type: TokenType) -> Token
{
    value: TokenValue = source[current : offset] if type != .Indent else indent

    out := Token{
        type = type,
        line = line,
        column = column,
        value = value
    }

    reset(lexer)

    return out
}

peak :: proc(using lexer: ^Lexer) -> u8 
{
    return source[offset] if !at_end(lexer) else 0
}

peak_next :: proc(using lexer: ^Lexer) ->u8 
{
    if (at_end(lexer) || offset+1 >= len(source))
    {
        return 0;
    }

    return source[offset + 1]
}

peak_last :: proc(using lexer: ^Lexer) ->u8 
{
    if (offset-1 <= 0)
    {
        return 0;
    }

    return source[offset - 1];
}

should_indent :: proc(using lexer: ^Lexer) -> bool 
{
    return indent > 0 && !in_middle
}

handle_blank :: proc(using lexer: ^Lexer)  
{
    loop: for !at_end(lexer)
    {
        switch peak(lexer)
        {
            case ' ': indent += 1
            case '\t': indent += 4
            case '\r': fallthrough
            case '\n':
                column = 1
                indent = 0
                line += 1
                in_middle = false
            // TODO: add multile comments with ## to start and ## to end. EXAMPLE: ## this is a comment ##
            case '#':
                for !at_end(lexer) && peak_next(lexer) != '\n'
                {
                    offset += 1
                }

            case: break loop
        }

        advance_stream(lexer)
    }
}

scan_digits :: proc(using lexer: ^Lexer) 
{
    for !at_end(lexer) && unicode.is_digit(cast(rune)peak(lexer))
    {
        advance_stream(lexer)
    }
}

build_digit :: proc(using lexer: ^Lexer) -> Token 
{
    scan_digits(lexer)
    
    is_float := false

    if (peak(lexer) == '.')
    {
        is_float = true
        advance_stream(lexer)
        scan_digits(lexer)
    }

    return build_token(lexer, .Float if is_float else .Int)
}

is_identifier :: proc(c: u8) -> bool 
{
    c := cast(rune)c
    return unicode.is_alpha(c) || unicode.is_digit(c) || c == '_'
}

build_identifier :: proc(using lexer: ^Lexer) -> Token 
{
    for is_identifier(peak(lexer))
    {
        advance_stream(lexer)
    }

    out := build_token(lexer, .Identifier)

    type := keywords[transmute(string)out.value.([]byte)] or_else out.type
    
    out.type = type

    return out;
}

build_string :: proc(using lexer: ^Lexer) -> Token
{
    start_char := peak_last(lexer)

    for !at_end(lexer) && peak(lexer) != start_char
    {
        advance_stream(lexer)
    }

    if peak(lexer) != start_char
    {
        return make_error(lexer, "unclosed string found")
    }

    current += 1

    out := build_token(lexer, .String)

    advance_stream(lexer)

    return out;
}

match_next :: proc(using lexer: ^Lexer, c: u8) -> bool 
{
    if peak_next(lexer) == c 
    {
        advance_stream(lexer)
        return true
    }

    return false
}

match :: proc(using lexer: ^Lexer, c: u8) -> bool 
{
    if peak(lexer) == c 
    {
        advance_stream(lexer)
        return true
    }

    return false
}

build_or_else :: proc(using lexer: ^Lexer, next: u8, if_type, else_type: TokenType) -> Token 
{
    if match(lexer, next) 
    {
        return build_token(lexer, if_type)
    }

    return build_token(lexer, else_type)
}