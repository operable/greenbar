Definitions.

TAG_NAME                 = ~[a-z][a-z0-9"_]+
TAG_FIELD                = [a-z][a-z0-9_]+
FLOAT                    = [0-9]+\.[0-9]+
INTEGER                  = [0-9]+
ASSIGN                   = \=
DBL_QUOTED_TEXT          = "(\\\^.|\\.|[^"])*"
SNGL_QUOTED_TEXT         = '(\\\^.|\\.|[^'])*'
TEXT                     = [^\.,\=\[\]]+
VAR                      = \$[a-zA-Z]+[a-zA-Z0-9_]*
BRACKET                  = \[|\]
DOT                      = \.
COMMA                    = ,
TILDE                    = ~
SKIPPED                  = \s

Rules.

{TAG_NAME}              : {token, {tag, TokenLine, tag_name(TokenChars)}}.
{TAG_FIELD}             : {token, {tag_field, TokenLine, TokenChars}}.
{ASSIGN}                : {token, {assign, TokenLine, "="}}.
{FLOAT}                 : {token, {float, TokenLine, TokenChars}}.
{INTEGER}               : {token, {integer, TokenLine, TokenChars}}.
{VAR}                   : {token, {var, TokenLine, TokenChars}}.
{BRACKET}               : {token, which_bracket(TokenLine, TokenChars)}.
{DOT}                   : {token, {dot, TokenLine, "."}}.
{COMMA}                 : {token, {comma, TokenLine, ","}}.
{TILDE}                 : {token, {tilde, TokenLine, "~"}}.
{DBL_QUOTED_TEXT}       : {token, {text, TokenLine, remove_quotes(double, TokenChars)}}.
{SNGL_QUOTED_TEXT}      : {token, {text, TokenLine, remove_quotes(single, TokenChars)}}.
{SKIPPED}               : skip_token.

Erlang code.

tag_name([$~|Name]) -> Name.

which_bracket(TokenLine, "[") -> {lbracket, TokenLine, "["};
which_bracket(TokenLine, "]") -> {rbracket, TokenLine, "]"}.

remove_quotes(single, Str) ->
  Str1 = re:replace(Str, "^'", "", [{return, list}]),
  re:replace(Str1, "'$", "", [{return, list}]);
remove_quotes(double, Str) ->
  Str1 = re:replace(Str, "^\"", "", [{return, list}]),
  re:replace(Str1, "\"$", "", [{return, list}]).
