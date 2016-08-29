defmodule Greenbar.Runtime do

  alias Piper.Common.Scope.Scoped
  alias Greenbar.EvaluationError

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

  def render_tag!(tag_mod, attrs, scope) do
    case tag_mod.render(attrs, scope) do
      {:halt, output, scope} ->
        {output, scope}
      {:error, reason} when is_binary(reason) ->
        raise Greenbar.EvaluationError, message: reason
      {:error, reason} ->
        raise Greenbar.EvaluationError, message: "#{inspect reason, pretty: true}"
    end
  end

  def render_tag!(tag_mod, attrs, body_fn, scope, buffer) do
    case tag_mod.render(attrs, scope) do
      {:cont, output, scope, body_scope} ->
        buffer = append_output(buffer, output)
        render_tag!(tag_mod, attrs, body_fn, scope, body_fn.(body_scope, buffer))
      {:halt, output, scope} ->
        {scope, append_output(buffer, output)}
    end
  end

  def combine_text(%{name: :text}=v, []), do: [v]
  def combine_text(%{name: :text}=v, [%{name: :text, text: acc_text}|t]) do
    [%{name: :text, text: Enum.join([v, acc_text])}|t]
  end
  def combine_text(v, acc), do: [v|acc]

  def stringify_value(nil), do: ""
  def stringify_value(value) when is_list(value) or is_map(value), do: Poison.encode(value)
  def stringify_value(value) when is_binary(value), do: value
  def stringify_value(value), do: "#{value}"

  defp append_output(buffer, nil), do: buffer
  defp append_output(buffer, output), do: [%{name: :text, text: output}|buffer]

end
