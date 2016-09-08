Definitions.

EXPR_END                = end
INTEGER                 = [0-9]+
FLOAT                   = [0-9]+\.[0-9]+
STRING                  = "(\\\^.|\\.|[^"])*"
VAR                     = \$[a-zA-Z][a-zA-Z0-9_]*
EXPR_NAME               = [a-zA-Z][a-zA-Z0-9_]*
ASSIGN                  = \=
GREATER_THAN            = >
GREATER_THAN_EQ         = >\=
LESS_THAN               = <
LESS_THAN_EQ            = <\=
EQ                      = \=\=
NEQ                     = !\=
LENGTH                  = length
EMPTY                   = empty\?
NOT_EMPTY               = not_empty\?
BOUND                   = bound\?
NOT_BOUND               = not_bound\?
DOT                     = \.
BRACKET                 = \[|\]
PAREN                   = \(|\)
SKIPPED                 = \s

Rules.

{EXPR_END}              : {token, {expr_end, TokenLine, <<"end">>}}.
{EXPR_NAME}             : {token, {expr_name, TokenLine, ?_ES(TokenChars)}}.
{INTEGER}               : {token, {integer, TokenLine, ?_INT(TokenChars)}}.
{FLOAT}                 : {token, {float, TokenLine, ?_FLOAT(TokenChars)}}.
{STRING}                : {token, {string, TokenLine, ?_ES(TokenChars)}}.
{VAR}                   : [$$|VarName] = TokenChars, {token, {var, TokenLine, ?_ES(VarName)}}.
{EQ}                    : {token, {equal, TokenLine, <<"==">>}}.
{NEQ}                   : {token, {not_equal, TokenLine, <<"!=">>}}.
{GREATER_THAN_EQ}       : {token, {gte, TokenLine, <<">=">>}}.
{GREATER_THAN}          : {token, {gt, TokenLine, <<">">>}}.
{LESS_THAN_EQ}          : {token, {lte, TokenLine, <<"<=">>}}.
{LESS_THAN}             : {token, {lt, TokenLine, <<"<">>}}.
{EMPTY}                 : {token, {empty, TokenLine, <<"empty?">>}}.
{NOT_EMPTY}             : {token, {not_empty, TokenLine, <<"not_empty?">>}}.
{BOUND}                 : {token, {bound, TokenLine, <<"bound?">>}}.
{NOT_BOUND}             : {token, {not_bound, TokenLine, <<"not_bound?">>}}.
{ASSIGN}                : {token, {assign, TokenLine, <<"=">>}}.
{DOT}                   : {token, {dot, TokenLine, <<".">>}}.
{BRACKET}               : {token, which_bracket(TokenLine, TokenChars)}.
{PAREN}                 : {token, which_paren(TokenLine, TokenChars)}.
{SKIPPED}               : skip_token.

Erlang code.

-export[scan/1].

-define(_ES(Chars), erlang:list_to_binary(Chars)).
-define(_INT(Chars), erlang:list_to_integer(Chars)).
-define(_FLOAT(Chars), 'Elixir.String':to_float(erlang:list_to_binary(Chars))).

scan(Str) when is_binary(Str) -> scan(erlang:binary_to_list(Str));
scan(Str) ->
  case ?MODULE:string(Str) of
    {ok, Tokens, _} ->
      {ok, Tokens};
    Error ->
      Error
  end.

which_bracket(TokenLine, [$[]) ->
  {lbracket, TokenLine, <<"[">>};
which_bracket(TokenLine, [$]]) ->
  {rbracket, TokenLine, <<"]">>}.

which_paren(TokenLine, [$(]) ->
  {lparen, TokenLine, <<"(">>};
which_paren(TokenLine, [$)]) ->
  {rparen, TokenLine, <<")">>}.
