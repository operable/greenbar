Terminals

text integer float string var

dot lbracket rbracket

expr_name expr_end eol

assign.

Nonterminals

template template_exprs tag_attrs tag_attr var_expr var_ops.

Rootsymbol template.

Expect 2.

template ->
  template_exprs : ensure_list('$1').

template_exprs ->
  text : {text, value_from('$1')}.
template_exprs ->
  expr_name : make_tag(value_from('$1')).
template_exprs ->
  expr_name tag_attrs : make_tag(value_from('$1'), '$2').
template_exprs ->
  expr_name tag_attrs template_exprs expr_end : make_tag(value_from('$1'), '$2', '$3').
template_exprs ->
  var_expr : '$1'.
template_exprs ->
  eol : eol.
template_exprs ->
  text template_exprs : combine({text, value_from('$1')}, '$2').
template_exprs ->
  expr_name template_exprs : combine(make_tag(value_from('$1')), '$2').
template_exprs ->
  expr_name tag_attrs template_exprs : combine(make_tag(value_from('$1'), '$2'), '$3').
template_exprs ->
  expr_name tag_attrs template_exprs expr_end template_exprs : combine(make_tag(value_from('$1'), '$2', '$3'), drop_leading_eol('$5')).
template_exprs ->
  var_expr template_exprs : combine('$1', '$2').
template_exprs ->
  eol template_exprs : combine(eol, '$2').

tag_attrs ->
  tag_attr : '$1'.
tag_attrs ->
  tag_attr tag_attrs : combine('$1', '$2').

tag_attr ->
  expr_name assign integer : {assign_tag_attr, value_from('$1'), '$3'}.
tag_attr ->
  expr_name assign float : {assign_tag_attr, value_from('$1'), '$3'}.
tag_attr ->
  expr_name assign string : {assign_tag_attr, value_from('$1'), '$3'}.
tag_attr ->
  expr_name assign expr_name : {assign_tag_attr, value_from('$1'), name_to_string('$3')}.
tag_attr ->
  expr_name assign var_expr : {assign_tag_attr, value_from('$1'), '$3'}.

var_expr ->
  var : make_var(value_from('$1')).
var_expr ->
  var var_ops : make_var(value_from('$1'), '$2').

var_ops ->
  dot expr_name : [{key, value_from('$2')}].
var_ops ->
  lbracket integer rbracket : [{index, value_from('$2')}].
var_ops ->
  dot expr_name var_ops : [{key, value_from('$2')}] ++ '$3'.
var_ops ->
  lbracket integer rbracket var_ops : [{index, value_from('$2')}] ++ '$4'.

Erlang code.

-export([scan_and_parse/1]).

-define(MISSING_TILDE_REGEX, "^~([^~])+$").

scan_and_parse(Text) when is_binary(Text) ->
  case gb_lexer:scan(Text) of
    {ok, Nodes, _} ->
      case ?MODULE:parse(Nodes) of
        {error, Error} ->
          pp_error(Error);
        Parsed ->
          Parsed
      end;
    {error, Error} ->
      pp_error(Error);
    {error, Error, _} ->
      pp_error(Error)
  end.

combine(A, B) when is_list(A),
                   is_list(B) ->
  [A] ++ B;
combine(A, B) when is_list(A) -> A ++ [B];
combine(A, B) when is_list(B) -> [A|B];
combine(A, B) -> [A, B].

value_from({_, _, Text}) -> Text.

make_tag(Name) -> {tag, Name, nil, nil}.
make_tag(Name, Attrs) -> {tag, Name, ensure_list(Attrs), nil}.
make_tag(Name, Attrs, Body) ->
  Body1 = drop_leading_eol(Body),
  {tag, Name, ensure_list(Attrs), ensure_list(Body1)}.

make_var(Name) -> {var, Name, nil}.
make_var(Name, Ops) -> {var, Name, Ops}.

ensure_list(Value) when is_list(Value) -> Value;
ensure_list(Value) -> [Value].

drop_leading_eol({text, <<"\n">>}) -> [];
drop_leading_eol([{text, <<"\n">>}|T]) -> T;
drop_leading_eol([{text, <<$\n, Text/binary>>}|T]) ->
  [{text, <<$\n, Text/binary>>}|T];
drop_leading_eol(V) ->
  V.

name_to_string({expr_name, Pos, Value}) -> {string, Pos, Value, nil}.

pp_error({_, gb_lexer, {illegal, Chars}}) ->
  Chars1 = string:strip(Chars, right, $\n),
  %% Try to classify error
  case re:run(Chars1, ?MISSING_TILDE_REGEX) of
    {match, _} ->
      {error, iolist_to_binary(["Missing terminating tilde from tag expression: \"", Chars1, "\""])};
    nomatch ->
      {error, iolist_to_binary(gb_expr_lexer:format_error({illegal, Chars1}))}
  end;
pp_error({_, gb_parser, ["syntax error before: ", [[60, 60, "\"end\"", 62, 62]]]}) ->
  {error, <<"Syntax error: Dangling ~end~">>};
pp_error({_, gb_parser, ["syntax error before: ", [[60, 60, Chars, 62, 62]]]}) ->
  Chars1 = case Chars of
             "\"\\n\"" ->
               "<EOL>";
             _ ->
              Chars
           end,
  {error, iolist_to_binary(["Syntax error before ", Chars1])};
pp_error({_, Module, Error}) ->
  io:format("~p ~p~n", [Module, Error]),
  {error, iolist_to_binary(Module:format_error(Error))}.