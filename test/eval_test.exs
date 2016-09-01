defmodule Greenbar.EvalTest do

  use Greenbar.Test.Support.TestCase

  defp eval_template(name, template, args) do
    template = Greenbar.compile!(name, template)
    {:ok, engine} = Greenbar.Engine.default()
    Greenbar.Template.eval!(template, engine, args)
  end

  test "list variables render correctly" do
    result = eval_template("solo_variable", Templates.solo_variable, %{"item" => ["a","b","c"]})
    Assertions.directive_structure(result, [:text, :newline, :text])
    assert Enum.at(result, 2) == %{name: :text, text: "[\"a\",\"b\",\"c\"]."}
  end

  test "map variables render correctly" do
    result = eval_template("solo_variable", Templates.solo_variable, %{"item" => %{"name" => "baz"}})
    Assertions.directive_structure(result, [:text, :newline, :text])
  end

  test "parent/child scopes work" do
    data = %{"items" => ["a","b","c"]}
    result = eval_template("parent_child_scopes", Templates.parent_child_scopes, data)
    Assertions.directive_structure(result, [:text, :newline, # Header
                                            :text, :fixed_width, :newline, # a
                                            :text, :fixed_width, :newline, # b
                                            :text, :fixed_width, :newline, # c
                                            :text]) # Footer
  end

  test "indexed variables work" do
    data = %{"results" => [%{"documentation" => "These are my docs"}]}
    result = eval_template("documentation", Templates.documentation, data)
    assert [%{name: :text, text: "These are my docs"}] == result
  end

  test "real world template works" do
    data = %{"results" => [%{"id" => "bundle_123", "name" => "First Bundle", "enabled_version" => %{"version" => "1.1"}},
                           %{"id" => "bundle_124", "name" => "Second Bundle", "enabled_version" => %{"version" => "1.2"}},
                           %{"id" => "bundle_125", "name" => "Third Bundle", "enabled_version" => %{"version" => "1.3"}}]}
    result = eval_template("bundles", Templates.bundles, data)
    Assertions.directive_structure(result, [:text, :newline, :newline, #header
                                            :text, :newline, # Bundle ID
                                            :text, :newline, # Bundle Name
                                            :text, :newline, # Enabled Version
                                            :text, :newline, # Bundle ID
                                            :text, :newline, # Bundle Name
                                            :text, :newline, # Enabled Version
                                            :text, :newline, # Bundle ID
                                            :text, :newline, # Bundle Name
                                            :text]) # Enabled Version

  end

end
