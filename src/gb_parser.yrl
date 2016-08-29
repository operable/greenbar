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
  expr_name tag_attrs template_exprs expr_end : make_tag(value_from('$1'), '$2', drop_leading_eol('$4')).
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
  expr_name tag_attrs template_exprs expr_end template_exprs : combine(make_tag(value_from('$1'), '$2', drop_leading_eol('$3')), drop_leading_eol('$5')).
template_exprs ->
  var_expr template_exprs : combine('$1', '$2').
template_exprs ->
  eol template_exprs : combine(eol, '$2').

tag_attrs ->
  tag_attr : ensure_list('$1').
tag_attrs ->
  tag_attr tag_attrs : combine('$1', '$2').

tag_attr ->
  expr_name assign integer : {assign_tag_attr, value_from('$1'), '$3'}.
tag_attr ->
  expr_name assign float : {assign_tag_attr, value_from('$1'), '$3'}.
tag_attr ->
  expr_name assign string : {assign_tag_attr, value_from('$1'), '$3'}.
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

scan_and_parse(Text) when is_binary(Text) ->
  case gb_lexer:scan(Text) of
    {ok, Nodes, _} ->
      ?MODULE:parse(Nodes);
    {error, {_, Module, Error}} ->
      Module:format_error(Error);
    {error, {_, Module, Error}, _} ->
      Module:format_error(Error)
  end.

combine(A, B) when is_list(A),
                   is_list(B) ->
  [A] ++ B;
combine(A, B) when is_list(A) -> A ++ [B];
combine(A, B) when is_list(B) -> [A|B];
combine(A, B) -> [A, B].

value_from({_, _, Text}) -> Text.

make_tag(Name) -> {tag, Name, nil, nil}.
make_tag(Name, Attrs) -> {tag, Name, Attrs, nil}.
make_tag(Name, Attrs, Body) -> {tag, Name, Attrs, Body}.

make_var(Name) -> {var, Name, nil}.
make_var(Name, Ops) -> {var, Name, Ops}.

ensure_list(Value) when is_list(Value) -> Value;
ensure_list(Value) -> [Value].

drop_leading_eol([eol|T]) -> T;
drop_leading_eol(V) -> V.