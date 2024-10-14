package decompiling 

import "../../backend/compiling"
import "core:fmt"
import "core:mem"
import "core:bytes"

@(private="package")
Decompiler :: struct 
{
    cursor: int,
    compiler: ^compiling.Compiler,
}

read_op_code :: proc(using decompiler: ^Decompiler) -> compiling.OpCode 
{
    op := cast(compiling.OpCode)compiler.code[cursor]

    cursor += 1

    return op
}

read_constant :: proc(using decompiler: ^Decompiler) -> int 
{
    n := 0 

    mem.copy(&n, bytes.ptr_from_bytes(compiler.code[cursor:]), size_of(int))

    cursor += size_of(int)

    return n
}

print_decompiliation :: proc(using compiler: ^compiling.Compiler)
{
    decompiler := Decompiler {
        compiler = compiler
    }

    fmt.println()

    for decompiler.cursor < len(code)
    {
        op := read_op_code(&decompiler)

        fmt.print(op, " ")

        #partial switch op 
        {
            case .Push: 
                n := read_constant(&decompiler)
                fmt.println(n)
        }
    }
}