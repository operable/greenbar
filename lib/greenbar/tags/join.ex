defmodule Greenbar.Tags.Join do

  @moduledoc """
  Iterates over a list, joining the rendered items with a separator.

  With this, input of `["foo", "bar", "baz"]` could ultimately be
  rendered to the string `"foo, bar, baz"`

  By default, the joining text is `", "`

  ## Examples

  * Create a comma-delimited list
  ```
  ~join var=$names~~$item~~end~
  ```

  * Specify a custom joiner

  ```
  ~join var=$names with="-"~~$item~~end~
  ```

  * Custom binding
  ```
  ~join var=$names as=name~~$name~~end~
  ```

  * Bodies can contain arbitrary instructions
  ```
  ~join var=$users~~$item.profile.username~~end~
  ```

  """

  @remaining_key "__remaining__"
  @downstream_key "__downstream__"

  use Greenbar.Tag, body: true

  alias Piper.Common.Scope.Scoped

  require Logger
  def render(id, attrs, scope) do
    remaining_key = make_tag_key(id, @remaining_key)
    downstream_key = make_tag_key(id, @downstream_key)
    {downstream, scope} = case Scoped.lookup(scope, downstream_key) do
                            {:ok, _} ->
                              {true, scope}
                            _ ->
                              {:ok, scope} = Scoped.set(scope, downstream_key, true)
                              {false, scope}
                          end
    joiner = get_attr(attrs, "with", ", ")
    case get_remaining(scope, id, remaining_key, attrs) do
      nil ->
        {:halt, scope}
      [] ->
        {:halt, put(scope, id, remaining_key, [])}
      [h|t] ->
        var_name = get_attr(attrs, "as", "item")
        child_scope = new_scope(scope)
        child_scope = put(child_scope, :global, var_name, h)
        scope = put(scope, id, remaining_key, t)

        output = if downstream do
          joiner
        else
          nil
        end

        {:again, output, scope, child_scope}
    end
  end

  defp get_remaining(scope, id, key, attrs) do
    case get(scope, id, key) do
      nil ->
        case get_attr(attrs, "var") do
          {:not_found, _} ->
            nil
          value ->
            value
        end
      value ->
        value
    end
  end

end
