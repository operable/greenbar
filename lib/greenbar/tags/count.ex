defmodule Greenbar.Tags.Count do

  use Greenbar.Tag

  def name, do: "count"

  def render(attrs, scope) do
    IO.inspect attrs, pretty: true
    case get_attr(attrs, "var") do
      nil ->
        {:error, "var attribute not set"}
      value when is_list(value) ->
        {:halt, "#{length(value)}", scope}
      value when is_map(value) ->
        {:halt, "#{length(Map.keys(value))}", scope}
      _ ->
        {:halt, "N/A", scope}
    end
  end

end
