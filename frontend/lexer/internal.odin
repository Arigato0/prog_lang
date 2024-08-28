// +private package
package lexer

import "core:strings"

make_error :: proc(using lexer: ^Lexer, message: string) -> Token 
{
    return Token{
        line = line,
        column = column,
        value = message,
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

    return source[offset + 1];
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
                column = 1;
                indent = 0;
                line += 1;
                in_middle = false;
            // TODO: add multile comments with ## to start and ## to end. EXAMPLE: ## this is a comment ##
            case '#':
                for !at_end(lexer) && peak_next(lexer) != '\n'
                {
                    offset += 1
                }

            case: break loop
        }

        advance_stream(lexer);
    }
}