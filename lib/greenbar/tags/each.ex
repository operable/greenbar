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

  use Greenbar.Tag, body: true

  def render(id, attrs, scope) do
    case get_remaining(scope, id, @remaining_key, attrs) do
      nil ->
        {:halt, scope}
      [] ->
        {:halt, put(scope, id, @remaining_key, [])}
      [h|t] ->
        var_name = get_attr(attrs, "as", "item")
        child_scope = new_scope(scope)
        child_scope = put(child_scope, :global, var_name, h)
        scope = put(scope, id, @remaining_key, t)
        {:again, nil, scope, child_scope}
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

