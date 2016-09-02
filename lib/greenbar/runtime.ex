defmodule Greenbar.Runtime do

  alias Piper.Common.Scope.Scoped
  alias Greenbar.EvaluationError

  @allowed_directives [:text, :newline, :bold, :italics, :fixed_width]

  defmacrop raise_eval_error(reason) do
    quote do
      if is_binary(unquote(reason)) do
        raise Greenbar.EvaluationError, message: unquote(reason)
      else
        raise Greenbar.EvaluationError, message: "#{inspect unquote(reason), pretty: true}"
      end
    end
  end

  def var_to_value(scope, var_name, ops \\ nil)
  def var_to_value(scope, var_name, nil) do
    case Scoped.lookup(scope, var_name) do
      {:not_found, _} ->
        nil
      {:ok, value} ->
        value
    end
  end
  def var_to_value(scope, var_name, ops) do
    case var_to_value(scope, var_name, nil) do
      nil ->
        nil
      value ->
        eval_ops!(ops, value, var_name)
    end
  end

  def var_to_text(scope, var_name, ops \\ nil)
  def var_to_text(scope, var_name, nil) do
    stringify_value(var_to_value(scope, var_name, nil))
  end
  def var_to_text(scope, var_name, ops) do
    stringify_value(var_to_value(scope, var_name, ops))
  end

  def empty?(value) when is_list(value), do: Enum.count(value) == 0
  def empty?(_), do: false

  def bound?(nil), do: false
  def bound?(_), do: true

  def eval_ops!(ops, value, var_name) do
    Enum.reduce(ops, value, &(eval_op!(var_name, &1, &2)))
  end

  def eval_op!(var_name, {:key, key}, value) when is_map(value) do
    case Map.get(value, key) do
      nil ->
        raise EvaluationError, message: "Key #{key} not found while evaluating reference to variable '#{var_name}'"
      value ->
        value
    end
  end
  def eval_op!(_var_name, {:index, i}, value) when is_list(value) do
    Enum.at(value, i)
  end
  def eval_op!(var_name, {:key, key}, _value) do
    raise EvaluationError, message: "Cannot retrieve key '#{key}' from non-map value while evaluating reference to variable '#{var_name}'"
  end
  def eval_op!(var_name, {:list, i}, _value) do
    raise EvaluationError, message: "Cannot access index '#{i}' from non-list value while evaluating reference to variable '#{var_name}'"
  end

  def get_tag!(scope, name) do
    case Piper.Common.Scope.Scoped.lookup(scope, "__ENGINE__") do
      {:not_found, _} ->
        raise Greenbar.EvaluationError, message: "Template engine missing from evaluation environment"
      {:ok, engine} ->
        case Greenbar.Engine.get_tag(engine, name) do
          nil ->
            raise Greenbar.EvaluationError, message: "Module for tag '#{name}' missing"
          tag_mod ->
            tag_mod
        end
    end
  end

  def render_tag!(tag_mod, attrs, scope, buffer) do
    if skip_tag?(attrs) do
      {scope, buffer}
    else
      case tag_mod.render(attrs, scope) do
        {action, scope} when action in [:again, :halt, :once] ->
          {scope, buffer}
        {action, output, scope} when action in [:again, :halt, :once] ->
          {scope, add_tag_output!(output, buffer, tag_mod)}
        {:error, reason} ->
          raise_eval_error(reason)
      end
    end
  end

  def render_tag!(tag_mod, attrs, body_fn, scope, buffer) do
    if skip_tag?(attrs) do
      {scope, buffer}
    else
      case tag_mod.render(attrs, scope) do
        {:again, scope, body_scope} ->
          render_tag!(tag_mod, attrs, body_fn, scope, body_fn.(body_scope, buffer))
        {:again, output, scope, body_scope} ->
          buffer = add_tag_output!(output, buffer, tag_mod)
          render_tag!(tag_mod, attrs, body_fn, scope, body_fn.(body_scope, buffer))
        {:once, scope, body_scope} ->
          {scope, body_fn.(body_scope, buffer)}
        {:once, output, scope, body_scope} ->
          buffer = add_tag_output!(output, buffer, tag_mod)
          buffer = body_fn.(body_scope, buffer)
          {scope, buffer}
        {:halt, output, scope} ->
          {scope, add_tag_output!(output, buffer, tag_mod)}
        {:halt, scope} ->
          {scope, buffer}
        {:error, reason} ->
          raise_eval_error(reason)
      end
    end
  end

  def add_to_buffer(%{name: :text, text: text}, [%{name: :text, text: bt}|buffer]) do
    [%{name: :text, text: Enum.join([bt, text])}|buffer]
  end
  def add_to_buffer(item, buffer), do: [item|buffer]

  def stringify_value(nil), do: ""
  def stringify_value(value) when is_list(value) or is_map(value), do: Poison.encode!(value)
  def stringify_value(value) when is_binary(value), do: value
  def stringify_value(value), do: "#{value}"

  defp skip_tag?(nil), do: false
  defp skip_tag?(attrs) do
    Map.get(attrs, "when", true) == false
  end

  defp add_tag_output!(nil, buffer, _tag_mod), do: buffer
  defp add_tag_output!(output, buffer, _tag_mod) when is_binary(output) do
    add_to_buffer(%{name: :text, text: output}, buffer)
  end
  defp add_tag_output!(%{name: name}=output, buffer, _tag_mod) when name in @allowed_directives do
    add_to_buffer(output, buffer)
  end
  defp add_tag_output!(outputs, buffer, tag_mod) when is_list(outputs) do
    Enum.reduce(outputs, buffer, fn(output, buffer) -> add_tag_output!(output, buffer, tag_mod) end)
  end
  defp add_tag_output!(output, _, tag_mod) do
    raise Greenbar.EvaluationError, message: "Tag '#{tag_mod.name()}' returned invalid output: #{inspect output, pretty: true}"
  end

end
