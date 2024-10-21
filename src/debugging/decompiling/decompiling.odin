package decompiling 

import "../../backend/compiling"
import "core:fmt"
import "core:mem"
import "core:bytes"
import "../../backend/native"

@(private="package")
Decompiler :: struct 
{
    reader: compiling.CodeReader,
    compiler: ^compiling.Compiler,
}

print_decompiliation :: proc(using compiler: ^compiling.Compiler)
{
    fmt.println("======== CODE =======")

    reader := compiling.CodeReader { compiler = compiler }

    fmt.println()

    for !compiling.reader_at_end(&reader)
    {
        op := compiling.read_op_code(&reader)

        fmt.print(op, " ")

        #partial switch op 
        {
            case .Push: 
                n := compiling.read_value(&reader)
                fmt.printfln("{}", n.(int))
        }
    }

    fmt.println()
}