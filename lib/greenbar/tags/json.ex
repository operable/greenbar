defmodule Greenbar.Tags.Json do
  @moduledoc """

  Generates a code block containing the pretty-printed JSON encoding
  of a variable.

  ## Example

  With `my_json` equal to

      %{"foo" => "bar",
        "stuff" => %{"hello": "world"}}

  the template

      ~json var=$my_json~

  would render the text

      ```{
        "foo": "bar",
        "stuff": {
          "hello": "world"
        }
      }```

  """
  use Greenbar.Tag

  def render(_id, attrs, scope) do
    case get_attr(attrs, "var") do
      nil ->
        {:error, "var attribute not set"}
      var ->
        {:halt, %{name: :fixed_width, text: "#{Poison.encode!(var, pretty: true)}"}, scope}
    end
  end

end
