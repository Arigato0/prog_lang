// +private package
package compiling 

import "../../frontend/parsing"

emit_op :: proc(using compiler: ^Compiler, op: OpCode)
{
    append(&code, cast(u8)op) 
}

emit_literal :: proc(using compiler: ^Compiler, literal: parsing.Literal)
{

}

compile_expr :: proc(using compiler: ^Compiler, expr: ^parsing.Expr) 
{
    #partial switch v in expr 
    {
        case parsing.BinaryExpr:
            compile_expr(compiler, v.left)
            compile_expr(compiler, v.left)

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