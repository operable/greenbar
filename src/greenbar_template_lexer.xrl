Definitions.

TEXT                    = [^~\n\r#]+
COMMENT                 = #(.+)(\n|\r\n)?
TAG                     = ~([^~])+~
TAG_END                 = ~end~
TAG_VAR                 = ~\$[a-zA-Z]+[a-zA-Z0-9_]*
ESCAPED                 = (\\~|\\#)
EOL                     = (\n|\r\n)+

Rules.

{TAG_END}               : {token, {tag_end, TokenLine, TokenChars}}.
{TAG_VAR}               : {token, {var, TokenLine, normalize_var(TokenChars)}}.
{TAG}                   : {token, {tag, TokenLine, TokenChars}}.
{COMMENT}               : skip_token.
{EOL}                   : {token, {text, TokenLine, TokenChars}}.
{ESCAPED}               : {token, {text, TokenLine, unescape(TokenChars)}}.
{TEXT}                  : {token, {text, TokenLine, TokenChars}}.

Erlang code.

-export[scan/1].

scan(Str) when is_binary(Str) ->
  case ?MODULE:string(erlang:binary_to_list(Str)) of
    {ok, Nodes, Lines} ->
      Nodes1 = [{bof, 1, "<bof>"}|Nodes] ++ [{eof, Lines, "<eof>"}],
      case post_process(Nodes1, []) of
        {ok, Nodes2} ->
          {ok, Nodes2, Lines};
        Error ->
          Error
      end;
    Error ->
      Error
  end.

normalize_var(Chars) ->
  re:replace(Chars, "~\$", "$", [{return, list}]).


unescape([$\\|Chars]) -> Chars.

post_process([], Accum) -> {ok, lists:reverse(Accum)};
post_process([{text, _, T2}|Rest], [{text, Line, T1}|Accum]) ->
  post_process(Rest, [{text, Line, T1 ++ T2}|Accum]);
post_process([{tag, Line, Text}|T], Accum) ->
  case greenbar_template_tag_lexer:string(Text) of
    {ok, Nodes, _} ->
      Nodes1 = [{Type, Line, Chars} || {Type, _, Chars} <- lists:reverse(Nodes)],
      post_process(T, Nodes1 ++ Accum);
    Error ->
      Error
  end;
post_process([H|T], Accum) -> post_process(T, [H|Accum]).
