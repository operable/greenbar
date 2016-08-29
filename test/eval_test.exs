defmodule Greenbar.EvalTest do

  use Greenbar.Test.Support.TestCase

  defp eval_template(name, template, args) do
    template = Greenbar.compile!(name, template)
    {:ok, engine} = Greenbar.Engine.default()
    Greenbar.Template.eval!(template, engine, args)
  end

  test "list variables render correctly" do
    result = eval_template("solo_variable", Templates.solo_variable, %{"item" => ["a","b","c"]})
    Assertions.directive_structure(result, ["text", "newline", "text", "newline"])
    assert Enum.at(result, 2) == %{name: "text", text: "[\"a\",\"b\",\"c\"]."}
  end

  test "map variables render correctly" do
    result = eval_template("solo_variable", Templates.solo_variable, %{"item" => %{"name" => "baz"}})
    Assertions.directive_structure(result, ["text", "newline", "text", "newline"])
  end

  test "newlines are preserved" do
    data = %{"items" => [%{"id" => "abc"}, %{"id" => "def"}, %{"id" => "ghi"}]}
    result = eval_template("newlines", Templates.newlines, data)
    Assertions.directive_structure(result, ["text", "newline", "newline",  # This is a test.
                                            "text", "newline",             # id = "abc"
                                            "text", "newline",             # id = "def"
                                            "text", "newline",             # id = "ghi"
                                            "newline",
                                            "text", "newline"]) # This has been a test.
  end

  test "parent/child scopes work" do
    data = %{"items" => ["a","b","c"]}
    result = eval_template("parent_child_scopes", Templates.parent_child_scopes, data)
    Assertions.directive_structure(result, ["text", "newline",  # Header
                                            "text", "newline",  # a
                                            "text", "newline",  # b
                                            "text", "newline",  # c
                                            "newline", # gap
                                            "text", "newline"]) # Footer
  end

end
