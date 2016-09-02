defmodule Greenbar.Tags.If do

  use Greenbar.Tag

  def name, do: "if"

  def render(attrs, scope) do
    if get_attr(attrs, "cond", false) do
      {:once, nil, scope, new_scope(scope)}
    else
      {:halt, scope}
    end
  end

end
