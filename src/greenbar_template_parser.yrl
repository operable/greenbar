Terminals

bof eof tag tag_end tag_field var text assign
lbracket rbracket dot integer float comma tilde.

Nonterminals

template template_body template_statements tag_instance tag_fields tag_field_values
var_expr var_ops number.

Rootsymbol template.

Expect 1.

template ->
  template_body : ?AST(template):new('$1').

template_body ->
  bof eof : [].
template_body ->
  bof template_statements eof : ensure_list('$2').

template_statements ->
  tag_instance : '$1'.
template_statements ->
  tag_instance template_statements tag_end : ?AST(tag):body('$1', ?AST(tag_body):new(ensure_list('$2'))).
template_statements ->
  text : ?AST(text):new(?_ES(extract_value('$1'))).
template_statements ->
  tilde var_expr tilde : '$2'.
template_statements ->
  tag_instance template_statements : combine('$1', '$2').
template_statements ->
  tag_instance template_statements tag_end template_statements : combine(?AST(tag):body('$1', ?AST(tag_body):new(ensure_list('$2'))), '$4').

template_statements ->
  text template_statements : combine(?AST(text):new(?_ES(extract_value('$1'))), '$2').
template_statements ->
  tilde var_expr tilde template_statements : combine('$2', '$4').

tag_instance  ->
  tag tilde : ?AST(tag):new(?_ES(tag_name('$1'))).
tag_instance ->
  tag tag_fields tilde : ?AST(tag):new(?_ES(tag_name('$1')), ensure_list('$2')).

tag_fields ->
  tag_field : {?_ES(extract_value('$1')), undefined}.
tag_fields ->
  tag_field assign tag_field_values : {?_ES(extract_value('$1')), '$3'}.
tag_fields ->
  tag_field assign tag_field_values tag_fields : combine({?_ES(extract_value('$1')), '$3'}, '$4').

tag_field_values ->
  var_expr : '$1'.
tag_field_values ->
  number : '$1'.
tag_field_values ->
  text : ?AST(text):new(?_ES(extract_value('$1'))).
tag_field_values ->
  tag_field : ?AST(text):new(?_ES(extract_value('$1'))).
tag_field_values ->
  var_expr comma tag_field_values : combine('$1', '$3').
tag_field_values ->
  number comma tag_field_values : combine('$1', '$3').
tag_field_values ->
  text comma tag_field_values : combine(?AST(text):new(?_ES(extract_value('$1'))), '$3').

var_expr ->
  var : ?AST(variable):new(?_ES(extract_value('$1'))).
var_expr ->
  var var_ops : ?AST(variable):new(?_ES(extract_value('$1')), ensure_list('$2')).

var_ops ->
  lbracket integer rbracket : {index, extract_value('$2')}.
var_ops ->
  dot tag_field : {key, ?_ES(extract_value('$2'))}.
var_ops ->
  lbracket integer rbracket var_ops : combine({index, extract_value('$2')}, '$4').
var_ops ->
  dot tag_field var_ops : combine({key, ?_ES(extract_value('$2'))}, '$3').

number ->
  integer : ?AST(integer):new('$1').
number ->
  float : ?AST(float):new('$1').

Erlang code.

-export([scan_and_parse/1]).

-define(AST(Name), (ast(Name))).

%% Convert Erlang -> Elixir strings
-define(_ES(Str), convert_string(Str)).

scan_and_parse(Text) when is_binary(Text) ->
  case greenbar_template_lexer:scan(Text) of
    {ok, Tokens, _} ->
      case parse(Tokens) of
        {ok, Ast} ->
          {ok, Ast};
        {error, {_, Mod, Err}} ->
          {error, prettify_error(sane_error(Mod, Err))};
        {error, {_, Mod, Err}, _} ->
          {error, prettify_error(sane_error(Mod, Err))}
      end;
    {error, {_, Mod, Error}} ->
      {error, prettify_error(sane_error(Mod, Error))};
    {error, {_, Mod, Error}, _} ->
      {error, prettify_error(sane_error(Mod, Error))}
  end.

tag_name({tag, _, Name}) -> Name.

%% tag_field_name({tag_field, _, Name}) -> Name.

extract_value({var, _, [$$|Name]}) -> Name;
extract_value({_, _, Text}) -> Text.

%% AST helper functions
ast(template) ->
  'Elixir.Greenbar.Ast.Template';
ast(text) ->
  'Elixir.Piper.Common.Ast.String';
ast(tag) ->
  'Elixir.Greenbar.Ast.Tag';
ast(tag_body) ->
  'Elixir.Greenbar.Ast.TagBody';
ast(variable) ->
  'Elixir.Piper.Common.Ast.Variable';
ast(integer) ->
  'Elixir.Piper.Common.Ast.Integer';
ast(float) ->
  'Elixir.Piper.Common.Ast.Float'.

convert_string(Str) when is_list(Str) -> list_to_binary(Str);
convert_string(Str) when is_binary(Str) -> Str.

combine(A, B) when is_list(A),
                   is_list(B) ->
  [A] ++ B;
combine(A, B) when is_list(A) -> A ++ [B];
combine(A, B) when is_list(B) -> [A|B];
combine(A, B) -> [A, B].

ensure_list(L) when is_list(L) -> L;
ensure_list(L) -> [L].


%% Pretty up error messages
prettify_error(Err) when is_binary(Err) ->
  Changes = [{"\"<eof>\"", "<eof>"}],
  lists:foldl(fun({Regex, Replacement}, Msg) ->
                re:replace(Msg, Regex, Replacement, [{return, binary}]) end,
              Err, Changes).

sane_error(Mod, Error) ->
  list_to_binary(Mod:format_error(Error)).
