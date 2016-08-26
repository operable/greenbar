defmodule Greenbar.ParserTest do

  alias :greenbar_template_parser, as: Parser

  use Greenbar.Test.Support.TestCase
  alias Greenbar.Ast.Tag

  test "text parses as text" do
    {:ok, template} = Parser.scan_and_parse("This is a test.")
    text_node = Enum.at(template, 0)
    assert text_node.__struct__ == Piper.Common.Ast.String
    assert text_node.value == "This is a test."
  end

  test "newlines are included in text" do
    {:ok, template} = Parser.scan_and_parse("This is a \ntest.\n")
    assert Enum.count(template) == 1
    text_node = Enum.at(template, 0)
    assert text_node.__struct__ == Piper.Common.Ast.String
    assert text_node.value == "This is a \ntest.\n"
  end

  test "tags w/o bodies are parsed" do
    {:ok, template} = Parser.scan_and_parse("~title text='Hello' ~")
    assert Enum.count(template) == 1
    tag_node = Enum.at(template, 0)
    assert tag_node.__struct__ == Greenbar.Ast.Tag
    assert tag_node.tag == "title"
    assert tag_node.attributes == %{"text" => %Piper.Common.Ast.String{value: "Hello", col: 0, line: 0}}
  end

  test "tags w/bodies are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.vm_list)
    assert Enum.count(template) == 2
    tag_node = Enum.at(template, 0)
    assert tag_node.__struct__ == Greenbar.Ast.Tag
    assert tag_node.tag == "each"
    assert tag_node.attributes["var"] != nil
    assert Tag.body?(tag_node)
  end

  test "nested tags are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.vms_per_region)
    assert Enum.count(template) == 2
    outer = Enum.at(template, 0)
    assert outer.tag == "each"
    Assertions.ast_structure(outer.body, [Piper.Common.Ast.String,
                                  Piper.Common.Ast.Variable,
                                  Piper.Common.Ast.String,
                                  Greenbar.Ast.Tag,
                                  Piper.Common.Ast.String])
    inner = Enum.at(outer.body, 3)
    assert inner.tag == "each"
    Assertions.ast_structure(inner.body, [Piper.Common.Ast.String,
                                  Piper.Common.Ast.Variable,
                                  Piper.Common.Ast.String,
                                  Piper.Common.Ast.Variable,
                                  Piper.Common.Ast.String])

  end

  test "solo variables are parsed" do
    {:ok, template} = Parser.scan_and_parse(Templates.solo_variable)
    Assertions.ast_structure(template, [Piper.Common.Ast.String,
                                           Piper.Common.Ast.Variable,
                                           Piper.Common.Ast.String])
  end

end
