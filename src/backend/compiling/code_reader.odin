package compiling 

import "../native"
import "core:mem"
import "core:bytes"

CodeReader :: struct 
{
    using compiler: ^Compiler,
    offset: int,
}

read_op_code :: proc(using reader: ^CodeReader) -> OpCode 
{
    op := cast(OpCode)code[offset]

    offset += 1

    return op
}

read_value :: proc(using reader: ^CodeReader) -> (value: native.Value) 
{
    mem.copy(&value, bytes.ptr_from_bytes(compiler.code[offset:]), size_of(native.Value))

    offset += size_of(native.Value)

    return
}

reader_at_end :: proc(using reader: ^CodeReader) -> bool 
{
    return offset >= len(code)
}