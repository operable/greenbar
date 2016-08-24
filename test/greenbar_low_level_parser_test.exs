defmodule Greenbar.Test.LowLevelParser do

  alias :greenbar_template_parser, as: Parser
  alias Greenbar.Test.Support.Templates
  alias Greenbar.Ast.Tag

  use ExUnit.Case

  test "text parses as text" do
    {:ok, template} = Parser.scan_and_parse("This is a test.")
    text_node = Enum.at(template.statements, 0)
    assert text_node.__struct__ == Greenbar.Ast.Text
    assert text_node.text == "This is a test."
  end

  test "newlines are included in text" do
    {:ok, template} = Parser.scan_and_parse("This is a \ntest.\n")
    assert length(template.statements) == 1
    text_node = Enum.at(template.statements, 0)
    assert text_node.__struct__ == Greenbar.Ast.Text
    assert text_node.text == "This is a \ntest.\n"
  end

  test "tags w/o bodies are parsed" do
    {:ok, template} = Parser.scan_and_parse("~title text='Hello' ~")
    assert length(template.statements) == 1
    tag_node = Enum.at(template.statements, 0)
    assert tag_node.__struct__ == Greenbar.Ast.Tag
    assert tag_node.tag == "title"
    assert tag_node.attributes == %{"text" => "Hello"}
  end

  test "tags w/bodies are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.vm_list)
    assert length(template.statements) == 2
    tag_node = Enum.at(template.statements, 0)
    assert tag_node.__struct__ == Greenbar.Ast.Tag
    assert tag_node.tag == "each"
    assert tag_node.attributes["items"] != nil
    assert Tag.body?(tag_node)
  end

  test "nested tags are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.vms_per_region)
    assert length(template.statements) == 2
  end

end
