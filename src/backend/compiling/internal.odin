// +private package
package compiling 

import "../../frontend/parsing"
import "../../frontend/lexing"
import "../native"

import "core:mem"
import "core:strconv"
import "base:intrinsics"
import "core:fmt"

emit_op :: proc(using compiler: ^Compiler, op: OpCode)
{
    append(&code, cast(u8)op) 
}

emit_integral :: proc(using compiler: ^Compiler, value: $T)
{
    value: native.Value = value
    bytes := mem.byte_slice(&value, size_of(value))

    for b in bytes 
    {
        append(&code, b)
    }
}

emit_literal :: proc(using compiler: ^Compiler, literal: parsing.Literal)
{
    switch v in literal
    {
        case bool:
            n := cast(int)v

            emit_integral(compiler, n)

        case ^lexing.Token:
            #partial switch v.type
            {
                case .Int:
                    n, _ := strconv.parse_int(transmute(string)v.value.([]byte))
                    emit_integral(compiler, n)
            }
    }
}

compile_expr :: proc(using compiler: ^Compiler, expr: ^parsing.Expr) 
{
    #partial switch v in expr 
    {
        case parsing.BinaryExpr:
            compile_expr(compiler, v.left)
            compile_expr(compiler, v.right)

            switch v.operator.value.([]byte)[0]
            {
                case '+': emit_op(compiler, .Add)
                case '-': emit_op(compiler, .Sub)
                case '*': emit_op(compiler, .Mul)
                case '/': emit_op(compiler, .Div)
            }
            
        case parsing.LiteralExpr:
            emit_op(compiler, .Push)
            emit_literal(compiler, v.value)
    }
}

compile_stmt :: proc(using compiler: ^Compiler, stmt: ^parsing.Stmt) 
{
    #partial switch v in stmt 
    {
        case ^parsing.Expr: compile_expr(compiler, v)
    }
}