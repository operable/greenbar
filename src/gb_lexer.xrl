Definitions.

TEMPLATE_EXPR           = ~(\\\^.|\\.|[^~])+~
COMMENT                 = #(.)*(\n|\r\n)
TEXT                    = (\\#|\\~|[^#~\r\n])+
EOL                     = (\n|\r\n)

Rules.

{COMMENT}               : skip_token.
{TEMPLATE_EXPR}         : {token, {tag_expr, TokenLine, unwrap_expr(TokenChars)}}.
{TEXT}                  : {token, {text, TokenLine, ?_ES(TokenChars)}}.
{EOL}                   : {token, {eol, TokenLine, <<"\n">>}}.

Erlang code.

-export[scan/1].

-define(_ES(Chars), erlang:list_to_binary(Chars)).

scan(Str) when is_binary(Str) ->
  case ?MODULE:string(erlang:binary_to_list(Str)) of
    {ok, Tokens, _} ->
      parse_tags(Tokens, []);
    Error ->
      Error
  end.

unwrap_expr(Text) ->
  re:replace(Text, "(^~|~$)", "", [global, {return, list}]).

parse_tags([], Accum) -> {ok, lists:reverse(Accum), 1};
parse_tags([{tag_expr, _, TokenChars}|T], Accum) ->
  case gb_expr_lexer:scan(TokenChars) of
    {ok, Tokens} ->
      parse_tags(T, lists:reverse(Tokens) ++ Accum);
    Error ->
      Error
  end;
parse_tags([H|T], Accum) -> parse_tags(T, [H|Accum]).