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
end
