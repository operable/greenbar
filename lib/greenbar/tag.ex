defmodule Greenbar.Tag do

  @moduledoc """
  A behaviour defining the API contract between Greenbar's rendering
  logic and custom extensions.

  Tags are a way to expose custom functionality to Greenbar templates
  without modifying the template engine directly.

  Greenbar processes all tags first before generating render directives
  from the resulting Markdown. Tags can emit plain text, Markdown-formatted text,
  or render directives.

  # Tag Syntax

  Greenbar supports three different tag call syntaxes within a template.

  ### 1. Tag name only

  ```
  ~timestamp~
  ```

  ### 2. Tag name with one or more attributes

  ```
  ~count var=$users max=5~
  ```

  Attributes act like named parameters. Each one is evaluated and placed into a map keyed by
  the attribute name. The populated map is passed to the tag module's `render/2` function.
  Tag processing occurs as in #1.

  ### 3. Tag with body

  ```
  ~each var=$users as=user~
    Name: ~$user.first_name~ ~$user.last_name~
  ~end~

  ```
  The tag's body content -- all template content ocurring between the tag and its matching `end` statement --
  will be evaluated none, one, or multiple times depending on the value the tag returns from its `render/2` function.


  # Controlling Template Execution

  Tags can control template execution by the value returned from `render/2`.

  * `{:halt, scope}` -- the tag has completed and the template should continue processing.
  * `{:halt, output, scope}` -- the tag has completed and generated output. The output will be written
    to the render buffer before processing the rest of the template.
  * `{:again, scope, body_scope}` -- execution should return to the tag after evaluating it's body.
    This return value is treated as `{:halt, scope}` when the tag lacks body content.
  * `{:once, scope, body_scope}` -- template execution should proceed after evaluating the tag's body
    exactly once. This return value is treated as `{:halt, scope}` when the tag lacks body content.
  * `{:again | :once, output, scope, body_scope}` -- identical to the output-less versions above except
    `output` is written to the render buffer before continuing.
  * `{:error, reason}` -- abort template execution and raise `Greenbar.EvaluationError`. `reason`, or a
    its textual version, will be stored in the error's `message` field.

  """

  alias Piper.Common.Scope
  alias Piper.Common.Scope.Scoped

  @type tag_attrs :: Map.t
  @type newline_output :: %{name: :newline}
  @type text_output :: %{name: :text, text: binary()}
  @type tag_output :: String.t | newline_output | text_output | nil

  @type continue_response :: {:again, tag_output, Scoped.t, Scoped.t} | {:again, [tag_output], Scoped.t, Scoped.t}
  @type continue_once_response :: {:once, tag_output, Scoped.t, Scoped.t} | {:once, [tag_output], Scoped.t, Scoped.t}
  @type done_response :: {:halt, tag_output, Scoped.t} | {:halt, [tag_output], Scoped.t}
  @type error_response :: {:error, term}

  @callback name() :: String.t
  @callback render(attrs :: tag_attrs, scope :: Scoped.t) :: continue_response | done_response | error_response

  defmacro __using__(_) do
    quote do
      @behaviour Greenbar.Tag

      import unquote(__MODULE__), only: [get_attr: 2, get_attr: 3, new_scope: 1]
    end
  end

  def get_attr(attrs, name, default \\ nil) do
    Map.get(attrs, name, default)
  end

  def new_scope(parent) do
    {:ok, new_scope} = Scoped.set_parent(Scope.empty_scope(), parent)
    new_scope
  end

end
