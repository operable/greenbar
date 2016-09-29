defmodule Greenbar.Compiler do

  alias Greenbar.Compiler.TagAttributes
  alias Greenbar.Render

  def compile(body) do
    quoted_body = Enum.map(body, &emit/1)
    quote do
      alias Greenbar.Runtime
      alias Greenbar.Runtime.Buffer
      alias Greenbar.Tag
      fn(scope, buffer) ->
        unquote_splicing(quoted_body)
        Greenbar.DirectivesGenerator.generate(buffer)
      end
    end
  end

  def emit({:text, text}) do
    quote bind_quoted: [text: text] do
      buffer = Render.text(buffer, text)
    end
  end
  def emit(:eol) do
    quote do
      buffer = Render.eol(buffer)
    end
  end
  def emit({:var, name, nil}) do
    quote bind_quoted: [name: name] do
      buffer = Render.var(buffer, name, scope)
    end
  end
  def emit({:var, name, ops}) do
    quote bind_quoted: [name: name, ops: ops] do
      buffer = Render.var(buffer, name, ops, scope)
    end
  end
  def emit({:tag, name, nil, nil}) do
    quote bind_quoted: [name: name] do
      {scope, buffer} = Render.tag(buffer, name, scope)
    end
  end
  def emit({:tag, name, attrs, nil}) do
    attr_exprs = TagAttributes.compile(attrs)
    quote bind_quoted: [name: name, attr_exprs: attr_exprs] do
      {scope, buffer} = Render.tag(buffer, name, attr_exprs, scope)
    end
  end
  def emit({:tag, name, attrs, body}) do
    attr_exprs = TagAttributes.compile(attrs)
    body_fn = generate_tag_body(body)
    quote do
      {scope, buffer} = Render.tag(buffer, unquote(name), unquote(attr_exprs), unquote(body_fn), scope)
    end
  end

  defp generate_tag_body(tag_body) do
    quoted_body = Enum.map(tag_body, &emit/1)
    quote do
      fn(scope, buffer) ->
        unquote_splicing(quoted_body)
      end
    end
  end

end
