defmodule Greenbar.Tags.Attachment do

  @moduledoc """
  Wraps body in an attachment directive
  """

  use Greenbar.Tag, body: true

  def render(_id, _attrs, scope) do
    child_scope = new_scope(scope)
    {:once, scope, child_scope}
  end

  def post_body(_id, attrs, scope, _body_scope, response) do
    attachment = Enum.reduce(attrs, %{}, &(generate_attributes(&1, &2))) |> Map.put(:name, :attachment)
    {:ok, scope, Map.put(attachment, :children, response)}
  end

  defp generate_attributes({key, value}, accum) do
    case key do
      "left_border" ->
        Map.put(accum, :left_border, value)
      _ ->
        accum
    end
  end

end
