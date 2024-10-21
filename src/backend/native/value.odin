package native 

import "base:intrinsics"

NoValue :: distinct int

Value :: union 
{
    NoValue,
    int,
    f32,
    bool,
    string,
}

value_add :: proc(a: ^Value, b: ^Value) -> Value 
{
    #partial switch v in a 
    {
        case int: 
            if float, ok := b.(f32); ok 
            {
                return cast(f32)v + float
            }
            else if integer, ok := b.(int); ok 
            {
                return v + b.(int)
            }
            else if boolean, ok := b.(bool); ok
            {
                return v + 1
            }

    }

    return int(0)
}