defmodule Greenbar.Runtime do

  @allowed_directive_atoms Enum.sort([:text, :newline, :bold, :italics, :fixed_width, :header, :link,
                                      :attachment])
  @allowed_directive_strings Enum.sort(Enum.map(@allowed_directive_atoms, &(Atom.to_string(&1))))

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

  def not_empty?(v), do: not(empty?(v))

  def empty?(nil), do: true
  def empty?(value) when is_list(value), do: Enum.count(value) == 0
  def empty?(value) when value == %{}, do: true
  def empty?(_), do: false

  def bound?(nil), do: false
  def bound?(_), do: true

  def not_bound?(v), do: not(bound?(v))

  def eval_ops!(ops, value, var_name) do
    Enum.reduce(ops, value, &(eval_op!(var_name, &1, &2)))
  end

  def eval_op!(_var_name, {:funcall, name}, value) do
    funcall(name, value)
  end
  def eval_op!(_var_name, {:key, key}, value) when is_map(value) do
    case Map.get(value, key) do
      nil ->
        nil
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

  def stringify_value(nil), do: ""
  def stringify_value(value) when is_list(value) or is_map(value), do: Poison.encode!(value)
  def stringify_value(value) when is_binary(value), do: value
  def stringify_value(value), do: "#{value}"

  def funcall("length", nil), do: 0
  def funcall("length", value) when is_list(value) or is_map(value) do
    Enum.count(value)
  end
  def funcall("length", _), do: 0
  def funcall(name, _) do
    raise Greenbar.EvaluationError, message: "Unknown built-in function '#{name}'"
  end

end
