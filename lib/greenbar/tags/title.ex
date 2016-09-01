defmodule Greenbar.Tags.Title do

  use Greenbar.Tag

  def name, do: "title"

  def render(attrs, scope) do
    {:halt, "# #{Map.get(attrs, "var")}", scope}
  end

end
