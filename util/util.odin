package util 

is_type :: proc(value: $U, $T: typeid) -> bool
{
    _, ok := value.(T) 
    return ok
}