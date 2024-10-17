package decompiling 

import "../../backend/compiling"
import "core:fmt"
import "core:mem"
import "core:bytes"
import "../../backend/native"

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

read_value :: proc(using decompiler: ^Decompiler) -> (value: native.Value) 
{
    mem.copy(&value, bytes.ptr_from_bytes(compiler.code[cursor:]), size_of(native.Value))

    cursor += size_of(native.Value)

    return
}

print_decompiliation :: proc(using compiler: ^compiling.Compiler)
{
    fmt.println("======== CODE =======")

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
                n := read_value(&decompiler)
                fmt.printfln("{}", n.(int))
        }
    }

    fmt.println()
}