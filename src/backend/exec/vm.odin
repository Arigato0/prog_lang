package exec

import "../compiling"
import "../native"
import "core:fmt"

VirtualMachine :: struct 
{
    code: compiling.ByteCode,
    reader: compiling.CodeReader,
    stack: [dynamic]native.Value
}

StatusCode :: enum 
{
    Ok,
    Failed,
}

push_stack :: proc(using vm: ^VirtualMachine, value: native.Value)
{
    append(&stack, value)
}

get_stack_top :: proc(using vm: ^VirtualMachine) -> native.Value 
{
    return pop(&stack)
}

run_code :: proc(compiler: ^compiling.Compiler) -> StatusCode
{
    vm := VirtualMachine { reader = compiling.CodeReader { compiler = compiler } }

    for !compiling.reader_at_end(&vm.reader)
    {
        op := compiling.read_op_code(&vm.reader)

        #partial switch op 
        {
            case .Push:
                value := compiling.read_value(&vm.reader)
                push_stack(&vm, value)
            case .Add:
                a := get_stack_top(&vm)
                b := get_stack_top(&vm)

                result := native.value_add(&a, &b)

                push_stack(&vm, result)

        }
    }

    fmt.println(get_stack_top(&vm))

    return .Ok
}