defmodule Greenbar.Tags.Each do

  @moduledoc """
  Iterates over a list binding each item to a variable scoped to the tag's
  body.

  ## Examples

  * Using the default body variable `item`
  ```
  ~each var=$users~
  First Name: ~$item.first_name~
  Last Name: ~$item.last_name~
  ~end~
  ```

  * Customizing the body variable
  ```
  ~each var=$users as=user~
  First Name: ~$user.first_name~
  Last Name: ~$user.last_name~
  ~end~
  ```

  Given the variable `$users` is bound `[%{"first_name" => "John", "last_name" => "Doe"}]` then both
  of the above templates would produce:

  ```
  First Name: John
  Last Name: Doe
  ```
  """

  @remaining_key "__remaining__"

  use Greenbar.Tag

  alias Piper.Common.Scope.Scoped

  def name, do: "each"

  def render(attrs, scope) do
    case get_remaining(attrs, scope) do
      nil ->
        {:halt, scope}
      [] ->
        {:halt, scope}
      [h|t] ->
        var_name = get_attr(attrs, "as", "item")
        child_scope = new_scope(scope)
        {:ok, child_scope} = Scoped.set(child_scope, var_name, h)
        {:ok, scope} = set_remaining(scope, t)
        {:again, nil, scope, child_scope}
    end
  end

  defp get_remaining(attrs, scope) do
    case Scoped.lookup(scope, @remaining_key) do
      {:not_found, _} ->
        case get_attr(attrs, "var") do
          {:not_found, _} ->
            nil
          value ->
            value
        end
      {:ok, value} ->
        value
    end
  end

  defp set_remaining(scope, remaining) do
    case Scoped.update(scope, @remaining_key, remaining) do
      {:not_found, _} ->
        Scoped.set(scope, @remaining_key, remaining)
      {:ok, scope} ->
        {:ok, scope}
    end
  end

end

