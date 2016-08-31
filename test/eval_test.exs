defmodule Greenbar.EvalTest do

  use Greenbar.Test.Support.TestCase

  defp eval_template(name, template, args) do
    template = Greenbar.compile!(name, template)
    {:ok, engine} = Greenbar.Engine.default()
    Greenbar.Template.eval!(template, engine, args)
  end

  test "list variables render correctly" do
    result = eval_template("solo_variable", Templates.solo_variable, %{"item" => ["a","b","c"]})
    Assertions.directive_structure(result, [:text, :newline, :text, :newline])
    assert Enum.at(result, 2) == %{name: :text, text: "[\"a\",\"b\",\"c\"]."}
  end

  test "map variables render correctly" do
    result = eval_template("solo_variable", Templates.solo_variable, %{"item" => %{"name" => "baz"}})
    Assertions.directive_structure(result, [:text, :newline, :text, :newline])
  end

  test "parent/child scopes work" do
    data = %{"items" => ["a","b","c"]}
    result = eval_template("parent_child_scopes", Templates.parent_child_scopes, data)
    Assertions.directive_structure(result, [:text, :newline, # Header
                                            :text, :fixed_width, :newline, # a
                                            :text, :fixed_width, :newline, # b
                                            :text, :fixed_width, :newline, # c
                                            :text, :newline]) # Footer
  end

  test "indexed variables work" do
    data = %{"results" => [%{"documentation" => "These are my docs"}]}
    result = eval_template("documentation", Templates.documentation, data)
    assert [%{name: :text, text: "These are my docs"}] == result
  end

end
