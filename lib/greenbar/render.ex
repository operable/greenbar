defmodule Greenbar.Render do

  alias Greenbar.Runtime
  alias Greenbar.Tag

  def text(buffer, text) do
    Runtime.add_to_buffer(%{name: :text, text: text}, buffer)
  end

  def eol(buffer) do
    Runtime.add_to_buffer(%{name: :newline}, buffer)
  end

  def var(buffer, name, scope) do
    value = Runtime.var_to_text(scope, name)
    Runtime.add_to_buffer(%{name: :text, text: value}, buffer)
  end

  def var(buffer, name, ops, scope) do
    value = Runtime.var_to_text(scope, name, ops)
    Runtime.add_to_buffer(%{name: :text, text: value}, buffer)
  end

  def tag(buffer, name, scope) do
    tag_id = next_tag_id()
    tag_mod = Runtime.get_tag!(scope, name)
    Tag.render!(tag_id, tag_mod, nil, scope, buffer)
  end

  def tag(buffer, name, attrs, scope) do
    tag_id = next_tag_id()
    tag_mod = Runtime.get_tag!(scope, name)
    Tag.render!(tag_id, tag_mod, attrs.(scope), scope, buffer)
  end

  def tag(buffer, name, attrs, body_fn, scope) do
    tag_id = next_tag_id()
    tag_mod = Runtime.get_tag!(scope, name)
    Tag.render!(tag_id, tag_mod, attrs.(scope), body_fn, scope, buffer)
  end

  defp next_tag_id() do
    :erlang.abs(:erlang.monotonic_time())
  end

end
