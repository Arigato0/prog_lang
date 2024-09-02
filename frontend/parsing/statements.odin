// +private package
package parsing 

import "core:fmt"

decleration :: proc(using parser: ^Parser) -> ^Stmt
{
    if match_token(parser, .Identifier)
    {
        identifier := previous_token(parser)

        if match_token(parser, .ColonEqual, .Equal)
        {
            var_decl := new(Stmt)

            type := previous_token(parser).type

            pair := VarPair {
                name = identifier,
                value = expression(parser)
            }
            
            if type == .ColonEqual 
            {
                var_decl^ = pair
            }
            else 
            {
                expr := new(Expr)
                expr^ = pair
                var_decl^ = ExpressionStmt { expr }
            }

            return var_decl
        }
    }
    return nil
}

statement :: proc(using parser: ^Parser) -> ^Stmt
{

    return nil
}