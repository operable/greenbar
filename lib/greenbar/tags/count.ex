defmodule Greenbar.Tags.Count do

  @moduledoc """
  Returns the size of the referenced variable. When referencing lists
  the size is the length of the list. For maps, size is the number of the
  map's unique keys. Any other value type will display "N/A".

  Here are some examples of how the following template would render given
  different types of values.

  ### Example Template

  `There are ~count var=$users~ users.`

  ### Lists

  `users = [%{"name" => "jennifer"}, %{"name" => "bob"}]` => `There are 2 users.`

  ### Maps

  `users = %{"name" => "lucy", "login" => "lsimpson"}` => `There are 2 users.`

  ### Scalars

  `users = "bob"` => `There are N/A users.`

  """

  use Greenbar.Tag


  def render(_id, attrs, scope) do
    case get_attr(attrs, "var") do
      value when is_list(value) ->
        {:halt, "#{length(value)}", scope}
      value when is_map(value) ->
        {:halt, "#{length(Map.keys(value))}", scope}
      _ ->
        {:halt, "N/A", scope}
    end
  end

end
