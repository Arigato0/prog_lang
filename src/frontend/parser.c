#include "parser.h"
#include "frontend/lexer.h"

void parser_advance(Parser *parser)
{
    Token token = lexer_advance_token(parser->lexer);

    if (token.type == TK_ERROR)
    {
        parser->state = PARSE_ERR_SYNTAX;
    }

    parser->current_token = token;
}

void parser_expr(Parser *parser)
{

}

bool parser_match(Parser *parser, TOKEN_TYPE type)
{
    if (parser->current_token.type == type)
    {
        parser_advance(parser);
        return true;
    }

    return false;
}

void parser_expect(Parser *parser, TOKEN_TYPE type)
{
    if (parser->current_token.type == type)
    {
        parser->state = PARSE_ERR_SYNTAX;
    }
}

void parser_stmt(Parser *parser)
{
    if (parser_match(parser, TK_IDENTIFIER))
    {

    }
}

PARSER_ERROR parse(Parser *parser)
{
    parser_advance(parser);

    if (parser->state != PARSE_ERR_OK)
    {
        return parser->state;
    }

    while (parser->current_token.type != TK_ERROR)
    {

    }

    return PARSE_ERR_OK;
}
