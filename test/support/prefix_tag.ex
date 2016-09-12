defmodule Greenbar.Test.Support.PrefixTag do

  use Greenbar.Tag, body: true, name: "prefix"

  def render(_id, _attrs, scope) do
    {:once, scope, new_scope(scope)}
  end

  def post_body(_id, _attrs, scope, _body_scope, body) do
    {:ok, scope, body ++ [%{name: :text, text: "This is the prefix tag."}]}
  end

end
