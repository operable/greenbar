defmodule Greenbar.Generator do

  def generate_template(body) do
    quoted_body = Enum.map(body, &emit/1)
    quote do
      fn(scope, buffer) ->
        unquote_splicing(quoted_body)
        Greenbar.DirectivesGenerator.generate(Enum.reverse(buffer))
      end
    end
  end

  def emit({:text, text}) do
    quote bind_quoted: [text: text] do
      buffer = [%{name: :text, text: text}|buffer]
    end
  end
  def emit(:eol) do
    quote do
      buffer = [%{name: :newline}|buffer]
    end
  end
  def emit({:var, name, nil}) do
    quote bind_quoted: [name: name] do
      buffer = [%{name: :text, text: Greenbar.Runtime.var_to_text(scope, name)}|buffer]
    end
  end
  def emit({:var, name, ops}) do
    quote bind_quoted: [name: name, ops: ops] do
      buffer = [%{name: :text, text: Greenbar.Runtime.var_to_text(scope, name, ops)}|buffer]
    end
  end
  def emit({:tag, name, nil, nil}) do
    quote bind_quoted: [name: name] do
      tag_mod = Greenbar.Runtime.get_tag!(scope, name)
      {tag_output, scope} = Greenbar.Runtime.render_tag!(tag_mod, nil, nil, scope)
      buffer = if tag_output != nil do
        [%{name: :text, text: tag_output}|buffer]
      else
        buffer
      end
    end
  end
  def emit({:tag, name, attrs, nil}) do
    tag_attr_exprs = build_attr_exprs(attrs, nil)
    quote bind_quoted: [name: name, tag_attr_exprs: tag_attr_exprs] do
      attrs = tag_attr_exprs
      tag_mod = Greenbar.Runtime.get_tag!(scope, name)
      {tag_output, scope} = Greenbar.Runtime.render_tag!(tag_mod, attrs, scope)
      buffer = if tag_output != nil do
        [%{name: :text, text: tag_output}|buffer]
      else
        buffer
      end
    end
  end
  def emit({:tag, name, attrs, body}) do
    tag_attr_exprs = build_attr_exprs(attrs, nil)
    quoted_body_fn = generate_tag_body(body)
    quote do
      body_fn = unquote(quoted_body_fn)
      attrs = unquote(tag_attr_exprs)
      tag_mod = Greenbar.Runtime.get_tag!(scope, unquote(name))
      {scope, buffer} = Greenbar.Runtime.render_tag!(tag_mod, attrs, body_fn, scope, buffer)
    end
  end

  defp build_attr_exprs([], attr_expr) do
    Macro.pipe(quote do %{} end, attr_expr, 0)
  end
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {type, _, value, nil}}|t], nil) when type in [:integer, :float, :string] do
    build_attr_exprs(t, quote do Map.put(unquote(attr_name), unquote(value)) end)
  end
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:var, name, ops}}|t], nil) do
    build_attr_exprs(t, quote do Map.put(unquote(attr_name), Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops))) end)
  end
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {type, _, value, nil}}|t], expr) when type in [:integer, :float, :string] do
    expr = Macro.pipe(quote do Map.put(unquote(attr_name), unquote(value)) end, expr, 0)
    build_attr_exprs(t, expr)
  end
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:var, name, ops}}|t], expr) do
    expr = Macro.pipe(quote do
                       Map.put(unquote(attr_name), Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)))
                      end, expr, 0)
    build_attr_exprs(t, expr)
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
