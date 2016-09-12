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
    {attachment, fields} = Enum.reduce(attrs, {%{}, []}, &(gen_attributes(&1, &2)))
    updated = attachment
              |> Map.put(:name, :attachment)
              |> Map.put(:fields, fields)
              |> Map.put(:children, response)
    {:ok, scope, updated}
  end

  # Inspired by Slack's attachment attributes
  # See https://api.slack.com/docs/message-attachments
  defp gen_attributes({"title", value}, {attachment, fields}) do
    {Map.put(attachment, :title, value), fields}
  end
  defp gen_attributes({"title_url", value}, {attachment, fields}) do
    {Map.put(attachment, :title_url, value), fields}
  end
  defp gen_attributes({"pretext", value}, {attachment, fields}) do
    {Map.put(attachment, :pretext, value), fields}
  end
  defp gen_attributes({"color", value}, {attachment, fields}) do
    {Map.put(attachment, :color, value), fields}
  end
  defp gen_attributes({"image_url", value}, {attachment, fields}) do
    {Map.put(attachment, :image_url, value), fields}
  end
  defp gen_attributes({"author", value}, {attachment, fields}) do
    {Map.put(attachment, :author, value), fields}
  end
  defp gen_attributes({key, value}, {attachment, fields}) do
    field = %{title: key,
              value: value,
              short: false}
    {attachment, [field|fields]}
  end

end
