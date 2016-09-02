Terminals

text integer float string var

dot lbracket rbracket

expr_name expr_end eol

assign empty not_empty gt gte lt lte equal not_equal bound.

Nonterminals

template template_exprs tag_attrs tag_attr var_value var_expr var_ops.

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
  var_value : '$1'.
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
  var_value template_exprs : combine('$1', '$2').
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
  expr_name assign var_value : {assign_tag_attr, value_from('$1'), '$3'}.
tag_attr ->
  expr_name assign var_expr : {assign_tag_attr, value_from('$1'), '$3'}.

var_expr ->
  var_value gt integer : {gt, '$1', '$3'}.
var_expr ->
  var_value gte integer : {gte, '$1', '$3'}.
var_expr ->
  var_value lt integer : {lt, '$1', '$3'}.
var_expr ->
  var_value lte integer : {lte, '$1', '$3'}.
var_expr ->
  var_value equal integer : {equal, '$1', '$3'}.
var_expr ->
  var_value not_equal integer : {not_equal, '$1', '$3'}.
var_expr ->
  var_value gt float : {gt, '$1', '$3'}.
var_expr ->
  var_value gte float : {gte, '$1', '$3'}.
var_expr ->
  var_value lt float : {lt, '$1', '$3'}.
var_expr ->
  var_value lte float : {lte, '$1', '$3'}.
var_expr ->
  var_value equal float : {equal, '$1', '$3'}.
var_expr ->
  var_value not_equal float : {not_equal, '$1', '$3'}.
var_expr ->
  var_value gt var_value : {gt, '$1', '$3'}.
var_expr ->
  var_value gte var_value : {gte, '$1', '$3'}.
var_expr ->
  var_value lt var_value : {lt, '$1', '$3'}.
var_expr ->
  var_value lte var_value : {lte, '$1', '$3'}.
var_expr ->
  var_value equal var_value : {equal, '$1', '$3'}.
var_expr ->
  var_value not_equal var_value : {not_equal, '$1', '$3'}.
var_expr ->
  var_value equal string : {equal, '$1', '$3'}.
var_expr ->
  var_value not_equal string : {equal, '$1', '$3'}.
var_expr ->
  var_value equal expr_name : {equal, '$1', name_to_string('$3')}.
var_expr ->
  var_value not_equal expr_name : {not_equal, '$1', name_to_string('$3')}.
var_expr ->
  var_value empty : {empty, '$1'}.
var_expr ->
  var_value not_empty : {not_empty, '$1'}.
var_expr ->
  var_value bound : {bound, '$1'}.

var_value ->
  var : make_var(value_from('$1')).
var_value ->
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

name_to_string({expr_name, Pos, Value}) -> {string, Pos, Value}.

