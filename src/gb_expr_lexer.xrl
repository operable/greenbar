Definitions.

EXPR_END                = end
INTEGER                 = [0-9]+
FLOAT                   = [0-9]+\.[0-9]+
STRING                  = "(\\\^.|\\.|[^"])"
VAR                     = \$[a-zA-Z][a-zA-Z0-9_]*
EXPR_NAME               = [a-zA-Z][a-zA-Z0-9_]*
ASSIGN                  = \=
DOT                     = \.
BRACKET                 = \[|\]
SKIPPED                 = \s

Rules.

{EXPR_END}              : {token, {expr_end, TokenLine, <<"end">>}}.
{EXPR_NAME}             : {token, {expr_name, TokenLine, ?_ES(TokenChars)}}.
{INTEGER}               : {token, {integer, TokenLine, ?_INT(TokenChars)}}.
{FLOAT}                 : {token, {float, TokenLine, ?_FLOAT(TokenChars)}}.
{STRING}                : {token, {string, TokenLine, ?_ES(TokenChars)}}.
{VAR}                   : [$$|VarName] = TokenChars, {token, {var, TokenLine, ?_ES(VarName)}}.
{ASSIGN}                : {token, {assign, TokenLine, <<"=">>}}.
{DOT}                   : {token, {dot, TokenLine, <<".">>}}.
{BRACKET}               : {token, which_bracket(TokenLine, TokenChars)}.
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