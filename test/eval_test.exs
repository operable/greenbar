defmodule Greenbar.EvalTest do

  use Greenbar.Test.Support.TestCase

  test "list variables render correctly" do
    [result] = Greenbar.eval(Templates.solo_variable, %{"item" => ["a","b","c"]})
    Assertions.directive_structure(result, ["text", "newline", "text", "text", "newline"])
    assert Enum.at(result, 2) == %{name: "text", text: "[\"a\",\"b\",\"c\"]"}
  end

  test "map variables render correctly" do
    [result] = Greenbar.eval(Templates.solo_variable, %{"item" => %{"name" => "baz"}})
    Assertions.directive_structure(result, ["text", "newline", "text", "newline"])
  end

  test "newlines are preserved" do
    data = %{"items" => [%{"id" => "abc"}, %{"id" => "def"}, %{"id" => "ghi"}]}
    [result] = Greenbar.eval(Templates.newlines, data)
    Assertions.directive_structure(result, ["text", "newline",  # This is a test.
                                            "text", "newline",  # id = "abc"
                                            "text", "newline",  # id = "def"
                                            "text", "newline",  # id = "ghi"
                                            "text", "newline"]) # This has been a test.
  end

  test "parent/child scopes work" do
    data = %{"items" => ["a","b","c"]}
    [result] = Greenbar.eval(Templates.parent_child_scopes, data)
    Assertions.directive_structure(result, ["text", "newline",  # Header
                                            "text", "newline",  # a
                                            "text", "newline",  # b
                                            "text", "newline",  # c
                                            "text", "newline"]) # Footer
  end

  test "indexing works" do
    data = %{"things" => [%{"id" => 1,
                            "name" => "First"},
                          %{"id" => 2,
                            "name" => "Second"}]}
    [directives] = Greenbar.eval(Templates.explicit_indexing, data)
    assert [%{name: "text", text: "Here&#39;s the first thing&#39;s ID:"},
            %{name: "newline", text: "\n"},
            %{name: "text", text: "1"},
            %{name: "newline"}] == directives
  end

end
