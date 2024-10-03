package debugging

import "../frontend/parsing"
import "../frontend/lexing"

import "core:fmt"

print_literal :: proc(literal: parsing.Literal)
{
    #partial switch v in literal 
    {
    case ^lexing.Token:
        fmt.print(lexing.get_token_string(v))
    case:
        fmt.print(v)
    }
}

print_expr :: proc(root: ^parsing.Expr)
{
    if root == nil do return 
    
    #partial switch v in root 
    {
    case parsing.BinaryExpr:
        fmt.printf("({} ", lexing.get_token_string(v.operator))
        print_expr(v.left)
        print_expr(v.right)
        fmt.print(")")
    case parsing.UnaryExpr:
        fmt.printf("({} ", lexing.get_token_string(v.operator))
        print_expr(v.right)
        fmt.print(")")
    case parsing.LiteralExpr:
        print_literal(v.value)
    case parsing.GroupingExpr:
        print_expr(v.inside)
    case parsing.IdentifierExpr:
        fmt.print(lexing.get_token_string(v.name))
    case parsing.CallExpr:
        fmt.printf("(call {} (", lexing.get_token_string(v.name))
        for expr in v.arguments
        {
            print_expr(expr)
        }
        fmt.println("))")
    case parsing.SubScriptExpr:
        fmt.printf("(subscript {} [", lexing.get_token_string(v.identifier))
        print_expr(v.value)
        fmt.println("])")
    case parsing.PropertyAccessExpr:
        fmt.printf("{}.{}", lexing.get_token_string(v.object), lexing.get_token_string(v.property))
    case parsing.MatchExpr:
        fmt.println("(match ")
        print_expr(v.value)
        fmt.println()
        for stmt in v.cases.statments
        {
            print_stmt(stmt)
        }
    }

    fmt.print(" ")
}

print_stmt :: proc(stmt: ^parsing.Stmt)
{
    #partial switch v in stmt 
    {
    case parsing.VarDeclStmt:
        fmt.printf("({} := ", lexing.get_token_string(v.name))
        print_expr(v.init_value)
        fmt.println(")")
    case ^parsing.Expr:
        print_expr(v)
    case parsing.FnDecleration:
        fmt.printf("(fn {} (", lexing.get_token_string(v.name))
        for expr, i in v.args
        {
            print_expr(expr)

            if i < len(v.args)-1
            {
                fmt.print(", ")
            }
        }
        fmt.printf(") body =>\n")
        for stmt, i in v.body.statments
        {
            print_stmt(stmt)

            if i < len(v.args)-1
            {
                fmt.println()
            }
        }
        fmt.println(")")
    case parsing.StructDecleration:
        fmt.printfln("(struct {} ({}) =>", lexing.get_token_string(v.name), lexing.get_token_string(v.interface))
        for stmt, i in v.methods.statments
        {
            print_stmt(stmt)
        }
        fmt.println(")")
    case parsing.ReturnStmt:
        fmt.print("(return ")
        for expr in v.values
        {
            print_expr(expr)
        }
        fmt.println(")")
    case parsing.IfStmt:

        if v.is_elif 
        {
            fmt.print("(else if")
        }
        if v.condition != nil 
        {
            fmt.print("(if ")
            print_expr(v.condition)
            fmt.println()
        }
        else 
        {
            fmt.println("(else")
        }

        for stmt in v.branch.statments
        {
            print_stmt(stmt)
        }

        fmt.println(")")
    case parsing.ForInStmt:
        fmt.printf("(for {} {} in ", 
            lexing.get_token_string(v.element1), lexing.get_token_string(v.element2) if v.element2 != nil else "")

        print_expr(v.range)

        fmt.println()

        for stmt in v.body.statments
        {
            print_stmt(stmt)
        }

        fmt.println(")")
    case parsing.WhileStmt:
        fmt.print("(while ",)
        print_expr(v.condition)
        fmt.println()
        for stmt in v.body.statments
        {
            print_stmt(stmt)
        }
        fmt.println(")")
    case parsing.MatchCase:
        fmt.print("case ")
        print_expr(v.value)
        fmt.printf(" => ")
        for stmt in v.body.statments
        {
            print_stmt(stmt)
        }
        fmt.println()
    }
}

print_ast :: proc(using parser: ^parsing.Parser)
{
    for stmt in statements
    {
        print_stmt(stmt)
    }
}