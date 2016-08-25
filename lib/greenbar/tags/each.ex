defmodule Greenbar.Tags.Each do

  @remaining_key "__remaining__"

  use Greenbar.Tag

  alias Piper.Common.Scope.Scoped
  alias Piper.Common.Scope

  def name, do: "each"

  def render(attrs, scope) do
    child_scope = Scope.empty_scope()
    case get_remaining(attrs, scope) do
      nil ->
        {:error, "var attribute not set"}
      [] ->
        {:halt, nil, child_scope}
      [h|t] ->
        var_name = get_attr(attrs, "as") || "item"
        {:ok, child_scope} = Scoped.set(child_scope, var_name, h)
        {:ok, scope} = set_remaining(scope, t)
        {:ok, child_scope} = Scoped.set_parent(child_scope, scope)
        {:cont, nil, scope, child_scope}
    end
  end

  defp get_remaining(attrs, scope) do
    case Scoped.lookup(scope, @remaining_key) do
      {:not_found, _} ->
        get_attr(attrs, "var")
      {:ok, value} ->
        value
    end
  end

  defp set_remaining(scope, remaining) do
    case Scoped.update(scope, @remaining_key, remaining) do
      {:not_found, _} ->
        Scoped.set(scope, @remaining_key, remaining)
      {:ok, scope} ->
        {:ok, scope}
    end
  end

end

