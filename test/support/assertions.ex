defmodule Greenbar.Test.Support.Assertions do

  defmacro ast_structure(nodes, types) do
    quote bind_quoted: [nodes: nodes, types: types] do
      assert Enum.count(nodes) == Enum.count(types)
      Enum.each(Enum.with_index(nodes), fn({node, i}) ->
        ct = Enum.at(types, i)
        unless node.__struct__ == ct do
          raise %ExUnit.AssertionError{left: node.__struct__,
                                       right: ct,
                                       message: "Expected #{inspect ct} but have #{inspect node, pretty: true}"}
        end end)
    end
  end

  defmacro directive_structure(nodes, types) do
    quote bind_quoted: [nodes: nodes, types: types] do
      assert Enum.count(nodes) == Enum.count(types)
      Enum.each(Enum.with_index(nodes),
        fn({node, i}) ->
          ct = Enum.at(types, i)
          unless Map.get(node, :name) == ct do
            raise %ExUnit.AssertionError{left: node,
                                         right: ct,
                                         message: "Expected #{inspect ct} but have #{inspect node, pretty: true}"}
          end end)
    end
  end

  def extract_names(result) do
    extract_names(result, [])
  end

  def extract_names([], accum), do: Enum.reverse(accum)
  def extract_names([%{name: name, children: children}|t], accum) do
    children = extract_names(children)
    extract_names(t, [{name, children}|accum])
  end
  def extract_names([%{name: name}|t], accum) do
    extract_names(t, [name|accum])
  end

end
