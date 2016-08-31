defmodule Greenbar.ParserTest do

  alias :gb_parser, as: Parser

  use Greenbar.Test.Support.TestCase

  test "text parses as text" do
    {:ok, template} = Parser.scan_and_parse("This is a test.")
    {:text, "This is a test."} = Enum.at(template, 0)
  end

  test "newlines stay with their parsed text" do
    {:ok, template} = Parser.scan_and_parse("This is a \ntest.\n")
    assert Enum.count(template) == 1
    text_node = Enum.at(template, 0)
    assert text_node == {:text, "This is a \ntest.\n"}
  end

  test "tags w/o bodies are parsed" do
    {:ok, template} = Parser.scan_and_parse("~title text=\"Hello\" ~")
    assert Enum.count(template) == 1
    {:tag, "title", attrs, nil} = Enum.at(template, 0)
    assert [{:assign_tag_attr, "text", {:string, 1, "\"Hello\""}}] == attrs
  end

  test "tags w/bodies are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.vm_list)
    assert Enum.count(template) == 2
    {:tag, "each", attrs, body} = Enum.at(template, 0)
    assert [{:assign_tag_attr, "var", {:var, "vms", nil}}] == attrs
    assert [{:var, "item", [key: "name"]}, {:text, "\n"}] == body
  end

  test "nested tags are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.vms_per_region)
    assert Enum.count(template) == 2
    {:tag, "each", attrs, body} = Enum.at(template, 0)
    assert [{:assign_tag_attr, "var", {:var, "regions", nil}}] == attrs
    assert {:var, "item", [key: "name"]} = Enum.at(body, 0)
    {:tag, "each", attrs, body} = Enum.at(body, 2)
    assert [{:assign_tag_attr, "var", {:var, "item", [key: "vms"]}}] == attrs
    assert [{:text, "    "}, {:var, "item", [key: "name"]}, {:text, " ("},
            {:var, "item", [key: "id"]}, {:text, ")\n  "}] == body
  end

  test "solo variables are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.solo_variable)
    [{:text, "This is a test.\n"}, {:var, "item", nil}, {:text, ".\n"}] = template
  end

end
