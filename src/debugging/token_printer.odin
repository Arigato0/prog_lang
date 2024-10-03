package debugging

import "../frontend/lexing"

import "core:fmt"

print_tokens :: proc(tokens: [dynamic]lexing.Token)
{
    for &token in tokens 
    {
        value: any = token.value

        #partial switch _ in token.value 
        {
            case []byte: value = transmute(string) token.value.([]byte)
        }

        fmt.printfln("{}({}, {}:{})", 
        token.type, value, token.line, token.column)
    }
}