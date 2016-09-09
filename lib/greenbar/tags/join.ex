defmodule Greenbar.Tags.Join do

  @remaining_key "__remaining__"
  @downstream_key "__downstream__"

  use Greenbar.Tag, body: true

  alias Piper.Common.Scope.Scoped

  require Logger
  def render(id, attrs, scope) do
    remaining_key = make_tag_key(id, @remaining_key)
    downstream_key = make_tag_key(id, @downstream_key)
    {downstream, scope} = case Scoped.lookup(scope, downstream_key) do
                            {:ok, _} ->
                              {true, scope}
                            _ ->
                              {:ok, scope} = Scoped.set(scope, downstream_key, true)
                              {false, scope}
                          end
    joiner = get_attr(attrs, "with", ", ")
    case get_remaining(scope, remaining_key, attrs) do
      nil ->
        {:halt, scope}
      [] ->
        scope = scope
        |> Scoped.erase(downstream_key)
        |> Scoped.erase(remaining_key)
        {:halt, scope}
      [h|t] ->
        var_name = get_attr(attrs, "as", "item")
        child_scope = new_scope(scope)
        {:ok, child_scope} = Scoped.set(child_scope, var_name, h)
        {:ok, scope} = set_remaining(scope, remaining_key, t)

        output = if downstream do
          joiner
        else
          nil
        end

        {:again, output, scope, child_scope}
    end
  end

  defp get_remaining(scope, key, attrs) do
    case Scoped.lookup(scope, key) do
      {:not_found, _} ->
        case get_attr(attrs, "var") do
          {:not_found, _} ->
            nil
          value ->
            value
        end
      {:ok, value} ->
        value
    end
  end

  defp set_remaining(scope, key, remaining) do
    case Scoped.update(scope, key, remaining) do
      {:not_found, _} ->
        Scoped.set(scope, key, remaining)
      {:ok, scope} ->
        {:ok, scope}
    end
  end

end
