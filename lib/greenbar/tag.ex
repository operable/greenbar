defmodule Greenbar.Tag do

  @moduledoc """
  A behaviour module for implementing custom Greenbar tags.

  Greenbar tags are modules which are called during template rendering.
  Tags are processed before Greenbar expands Markdown into render directives.

  Greenbar supports three different tag call syntaxes within a template.

  ### 1. Tag name only
  Example:
  ```
  ~timestamp~
  ```

  Greenbar will call the corresponding tag module's `render/2` function  with an
  empty attribute map. The module can return one of the following values:

  * `{:halt, text}` where `text` is a Markdown formatted Elixir string. This will cause Greenbar
    to replace the literal tag text with the returned string.
  * `{:error, reason}` where `reason` is any Elixir term. Greenbar will raise `EvaluationError`
    and abort template evaluation.

  ### 2. Tag name with one or more attributes
  Example:
  ```
  ~count var=$users max=5~
  ```

  Attributes act like named parameters. Each one is evaluated and placed into a map keyed by
  the attribute name. The populated map is passed to the tag module's `render/2` function.
  Tag processing occurs as in #1.

  ### 3. Tag with body
  Example:
  ```
  ~each var=$users as=user~
    Name: ~$user.first_name~ ~$user.last_name~
  ~end~
  ```
  """

  alias Piper.Common.Scope
  alias Piper.Common.Scope.Scoped

  @type tag_attrs :: Map.t
  @type newline_output :: %{name: :newline}
  @type text_output :: %{name: :text, text: binary()}
  @type tag_output :: String.t | newline_output | text_output | nil

  @type continue_response :: {:cont, tag_output, Scoped.t, Scoped.t} | {:cont, [tag_output], Scoped.t, Scoped.t}
  @type done_response :: {:halt, tag_output, Scoped.t} | {:halt, [tag_output], Scoped.t}
  @type error_response :: {:error, term}

  @callback name() :: String.t
  @callback render(attrs :: tag_attrs, scope :: Scoped.t) :: continue_response | done_response | error_response

  defmacro __using__(_) do
    quote do
      @behaviour Greenbar.Tag

      import unquote(__MODULE__), only: [get_attr: 2, new_scope: 0, link_scopes: 2]
    end
  end

  def get_attr(attrs, name) do
    Map.get(attrs, name)
  end

  def new_scope() do
    Scope.empty_scope()
  end

  def link_scopes(parent, child) do
    Scoped.set_parent(child, parent)
  end

end
