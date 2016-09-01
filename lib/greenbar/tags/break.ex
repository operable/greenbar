defmodule Greenbar.Tags.Break do

  use Greenbar.Tag

  def name, do: "br"

  def render(_attrs, scope) do
    {:halt, %{name: :newline}, scope}
  end

end
