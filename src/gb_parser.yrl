Terminals

text integer float boolean string var

dot lbracket rbracket lparen rparen

expr_name expr_end tag body_tag eol

assign empty not_empty gt gte lt lte equal not_equal bound not_bound

newline end_of_collapsible_body_tag.

Nonterminals

template template_exprs template_expr tag_attrs tag_attr attr_name var_value var_expr var_ops var_op.

Rootsymbol template.

Nonassoc 100 expr_name.
Nonassoc 200 tag.
Nonassoc 300 body_tag.

template ->
  template_exprs : ensure_list('$1').

template_exprs ->
  template_expr template_exprs : combine('$1', '$2').
template_exprs ->
  '$empty' : nil.

template_expr ->
  text : {text, value_from('$1')}.
template_expr ->
  newline : make_newline('$1').
template_expr ->
  end_of_collapsible_body_tag : nil.
template_expr ->
  expr_name tag_attrs : unknown_tag('$1').
template_expr ->
  expr_name tag_attrs template_exprs expr_end : unknown_tag('$1').
template_expr ->
  tag tag_attrs : make_tag('$1', '$2').
template_expr ->
  body_tag tag_attrs template_exprs expr_end : make_tag('$1', '$2', '$3').
template_expr ->
  newline body_tag tag_attrs template_exprs expr_end newline :
    combine(make_newline('$1'), make_tag('$2', '$3', maybe_combine_newline('$2', strip_newlines('$4'), make_newline('$6')))).
template_expr ->
  end_of_collapsible_body_tag body_tag tag_attrs template_exprs expr_end newline :
    make_tag('$2', '$3', maybe_combine_newline('$2', strip_newlines('$4'), make_newline('$6'))).
template_expr ->
  var_value : '$1'.
template_expr ->
  eol : eol.

tag_attrs ->
  tag_attr tag_attrs : combine('$1', '$2').
tag_attrs ->
  '$empty' : nil.

tag_attr ->
  attr_name assign integer : {assign_tag_attr, '$1', '$3'}.
tag_attr ->
  attr_name assign float : {assign_tag_attr, '$1', '$3'}.
tag_attr ->
  attr_name assign boolean : {assign_tag_attr, '$1', '$3'}.
tag_attr ->
  attr_name assign string : {assign_tag_attr, '$1', '$3'}.
tag_attr ->
  attr_name assign expr_name : {assign_tag_attr, '$1', name_to_string('$3')}.
tag_attr ->
  attr_name assign var_value : {assign_tag_attr, '$1', '$3'}.
tag_attr ->
  attr_name assign var_expr : {assign_tag_attr, '$1', '$3'}.

attr_name ->
  expr_name : value_from('$1').
attr_name ->
  string : value_from('$1').

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
  var_value equal boolean : {equal, '$1', '$3'}.
var_expr ->
  var_value not_equal boolean : {not_equal, '$1', '$3'}.
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
  var_value not_equal string : {not_equal, '$1', '$3'}.
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
var_expr ->
  var_value not_bound : {not_bound, '$1'}.

var_value ->
  var var_ops : make_var(value_from('$1'), '$2').
var_value ->
  expr_name lparen var var_ops rparen : make_var(value_from('$3'), combine('$4', make_funcall('$1'))).

var_ops ->
  var_op var_ops : combine('$1', '$2').
var_ops ->
  '$empty': nil.

var_op ->
  dot expr_name : {key, value_from('$2')}.
var_op ->
  lbracket integer rbracket : {index, value_from('$2')}.

Erlang code.

-export([scan_and_parse/2]).

-define(MISSING_TILDE_REGEX, "^~([^~])+$").

scan_and_parse(Text, Engine) when is_binary(Text) ->
  erlang:put(greenbar_engine, Engine),
  try
    case gb_lexer:scan(Text) of
      {ok, Nodes, _} ->
        Nodes2 = [{newline, -1, <<"\n">>}] ++ Nodes ++ [{newline, -1, <<"\n">>}],
        case ?MODULE:parse(Nodes2) of
          {error, Error} ->
            pp_error(Error);
          Parsed ->
            Parsed
        end;
      {error, Error} ->
        pp_error(Error);
      {error, Error, _} ->
        pp_error(Error)
    end
  of
    Result ->
      Result
  after
    erlang:erase(greenbar_engine)
  end.

combine(nil, B) -> combine([], B);
combine(A, nil) -> combine(A, []);
combine(A, B) when is_list(A), is_list(B) -> A ++ B;
combine(A, B) when is_list(A) -> A ++ [B];
combine(A, B) when is_list(B) -> [A|B];
combine(A, B) -> [A, B].

value_from({_, _, Text}) -> Text.

make_newline({newline, -1, _Text}) -> nil;
make_newline({newline, _, Text}) -> {newline, Text}.

make_tag(Name, nil) -> {tag, value_from(Name), nil, nil};
make_tag(Name, Attrs) -> {tag, value_from(Name), ensure_list(Attrs), nil}.

make_tag(Name, nil, Body) -> make_tag(Name, [], Body);
make_tag(Name, Attrs, nil) -> make_tag(Name, Attrs, []);
make_tag(Name, Attrs, Body) ->
  {tag, value_from(Name), ensure_list(Attrs), ensure_list(Body)}.

make_var(Name, Ops) -> {var, Name, Ops}.

make_funcall({_, _, Name}) ->
  {funcall, Name}.

maybe_combine_newline({body_tag, _, <<"join">>}, Body, _Newline) ->
  Body;
maybe_combine_newline({body_tag, _, _}, nil, Newline) ->
  [Newline];
% If we've already injected a newline in an existing tag body, skip it this time.
maybe_combine_newline({body_tag, _, _}, Body, Newline) ->
  case lists:reverse(Body) of
    [{tag, _, _, nil}|_] ->
      combine(Body, Newline);
    [{tag, _, _, TagBody}|_] ->
      case lists:reverse(TagBody) of
        [{newline, _}|_] ->
          Body;
        _ ->
          combine(Body, Newline)
      end;
    _ ->
      combine(Body, Newline)
  end.

strip_newlines(nil) -> nil;
strip_newlines([{newline, _}|R]) ->
  strip_newlines_reverse(lists:reverse(R));
strip_newlines(L) ->
  strip_newlines_reverse(lists:reverse(L)).

strip_newlines_reverse([{newline, _}|R]) ->
  lists:reverse(R);
strip_newlines_reverse(L) ->
  lists:reverse(L).

ensure_list(Value) when is_list(Value) -> Value;
ensure_list(Value) -> [Value].

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
  {error, iolist_to_binary(Module:format_error(Error))}.

name_to_string({expr_name, Pos, Value}) -> {string, Pos, Value}.

unknown_tag({_, TokenLine, TokenChars}) ->
  return_error(TokenLine, ["Unknown tag '", binary_to_list(TokenChars), "'"]).
