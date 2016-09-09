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

  It is mandatory that tags use the `:body` option to indicate when they expect body content. `false` indicates
  the tag expects no content; `true` indicates it does. The default is `false`.


  # Controlling Template Execution

  Tags can control template execution by the value returned from `render/2`.

  These return values are always valid:
  * `{:halt, scope}` -- the tag has completed and the template should continue processing.
  * `{:halt, output, scope}` -- the tag has completed and generated output. The output will be written
    to the render buffer before processing the rest of the template.
  * `{:error, reason}` -- abort template execution and raise `Greenbar.EvaluationError`. `reason`, or a
    its textual version, will be stored in the error's `message` field.

  These return values are valid when a tag has body content:
  * `{:again, scope, body_scope}` -- execution should return to the tag after evaluating it's body.
    This return value is treated as `{:halt, scope}` when the tag lacks body content.
  * `{:once, scope, body_scope}` -- template execution should proceed after evaluating the tag's body
    exactly once. This return value is treated as `{:halt, scope}` when the tag lacks body content.
  * `{[:again | :once], output, scope, body_scope}` -- identical to the output-less versions above except
    `output` is written to the render buffer before continuing.

  Returning the wrong response type, ie. returning a body response when a tag has no body, will raise a
  `Greenbar.EvaluationError` at runtime.

  # Hello, World tag example

  ```
  defmodule MyApp.Tags.HelloWorld do

    use Greenbar.Tag, name: "hello_world", # This would default to "helloworld"
                                           # if not overridden here
                      body: false

    # Emits "hello, world" into template output buffer
    def render(_id, _attrs, scope) do
      {:halt, "hello, world", scope}
    end

  end
  ```

  """

  alias Piper.Common.Scope
  alias Piper.Common.Scope.Scoped
  alias Greenbar.Runtime

  @type tag_attrs :: Map.t
  @type newline_output :: %{name: :newline}
  @type text_output :: %{name: :text, text: binary()}
  @type tag_output :: String.t | newline_output | text_output | nil

  @type continue_response :: {:again, tag_output, Scoped.t, Scoped.t} | {:again, [tag_output], Scoped.t, Scoped.t}
  @type continue_once_response :: {:once, tag_output, Scoped.t, Scoped.t} | {:once, [tag_output], Scoped.t, Scoped.t}
  @type done_response :: {:halt, tag_output, Scoped.t} | {:halt, [tag_output], Scoped.t}
  @type error_response :: {:error, term}

  @callback name() :: String.t
  @callback body?() :: boolean
  @callback render(id :: pos_integer, attrs :: tag_attrs, scope :: Scoped.t) :: continue_response | done_response | error_response

  defmacro __using__(opts) do
    tag_name = tag_name!(opts, __CALLER__)
    body_flag = body_flag!(opts, __CALLER__)

    quote do
      @behaviour unquote(__MODULE__)

      import unquote(__MODULE__), only: [get_attr: 2, get_attr: 3,
                                         new_scope: 1, make_tag_key: 2]

      def name(), do: unquote(tag_name)
      def body?(), do: unquote(body_flag)

      defoverridable [name: 0, body?: 0]
    end
  end

  def make_tag_key(id, key) do
    "__tag_#{id}_#{key}"
  end

  def get_attr(attrs, name, default \\ nil) do
    Map.get(attrs, name, default)
  end

  def new_scope(parent) do
    {:ok, new_scope} = Scoped.set_parent(Scope.empty_scope(), parent)
    new_scope
  end

  defmacrop raise_eval_error(reason) do
    quote do
      if is_binary(unquote(reason)) do
        raise Greenbar.EvaluationError, message: unquote(reason)
      else
        raise Greenbar.EvaluationError, message: "#{inspect unquote(reason), pretty: true}"
      end
    end
  end

  def render!(tag_id, tag_mod, attrs, scope, buffer) when is_map(scope) and is_list(buffer) do
    case tag_mod.render(tag_id, attrs, scope) do
      {action, _scope, _body_scope} when action in [:again, :once] ->
        raise Greenbar.EvaluationError, message: "Tag module '#{tag_mod}' returned a body response with no tag body"
      {action, _output, _scope, _body_scope} when action in [:again, :once] ->
        raise Greenbar.EvaluationError, message: "Tag module '#{tag_mod}' returned a body response with no tag body"
      {:halt, scope} ->
        {scope, buffer}
      {:halt, output, scope} ->
        {scope, Runtime.add_tag_output!(output, buffer, tag_mod)}
      {:error, reason} ->
        raise_eval_error(reason)
    end
  end

  def render!(tag_id, tag_mod, attrs, body_fn, scope, buffer) when is_map(scope) and is_list(buffer) do
    result = tag_mod.render(tag_id, attrs, scope)
    case  result do
      {:again, scope, body_scope} ->
        buffer = render_body!(body_fn, body_scope, buffer)
        render!(tag_id, tag_mod, attrs, body_fn, scope, buffer)
      {:again, output, scope, body_scope} ->
        buffer = Runtime.add_tag_output!(output, buffer, tag_mod)
        buffer = render_body!(body_fn, body_scope, buffer)
        render!(tag_id, tag_mod, attrs, body_fn, scope, buffer)
      {:once, scope, body_scope} ->
        buffer = render_body!(body_fn, body_scope, buffer)
        {scope, buffer}
      {:once, output, scope, body_scope} ->
        buffer = Runtime.add_tag_output!(output, buffer, tag_mod)
        buffer = render_body!(body_fn, body_scope, buffer)
        {scope, buffer}
      {:halt, output, scope} ->
        {scope, Runtime.add_tag_output!(output, buffer, tag_mod)}
      {:halt, scope} ->
        {scope, buffer}
      {:error, reason} ->
        raise_eval_error(reason)
    end
  end

  defp render_body!(body_fn, scope, buffer) do
    case body_fn.(scope, buffer) do
      {_, buffer} ->
        buffer
      buffer when is_list(buffer) ->
        buffer
    end
  end

  defp tag_name!(opts, caller) do
    case Keyword.get(opts, :name) do
      nil ->
        caller.module
        |> Atom.to_string
        |> String.split(".")
        |> List.last
        |> String.downcase
      name when is_binary(name) ->
        name
      _ ->
        raise CompileError, description: "Greenbar tag :name option must be a string",
          file: caller.file, line: caller.line
    end

  end

  defp body_flag!(opts, caller) do
    case Keyword.get(opts, :body, false) do
      body_flag when is_boolean(body_flag) ->
        body_flag
      _ ->
        raise CompileError, description: "Greenbar tag :body option must be boolean",
          file: caller.file, line: caller.line
    end
  end

end
