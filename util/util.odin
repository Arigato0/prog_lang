package util

construct :: #force_inline proc($T: typeid, value: $V) -> ^T
{
    ptr := new(T)
    
    ptr^ = value

    return ptr
}
