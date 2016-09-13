defmodule Greenbar.ParserTest do

  use Greenbar.Test.Support.TestCase

  setup_all do
    {:ok, engine} = Engine.new
    [engine: engine]
  end


  test "text parses as text", context do
    {:ok, template} = Engine.parse(context.engine, "This is a test.")
    {:text, "This is a test."} = Enum.at(template, 0)
  end

  test "newlines stay with their parsed text", context do
    {:ok, template} = Engine.parse(context.engine, "This is a \ntest.\n")
    assert Enum.count(template) == 1
    text_node = Enum.at(template, 0)
    assert text_node == {:text, "This is a \ntest.\n"}
  end

  test "tags w/o bodies are parsed", context do
    {:ok, template} = Engine.parse(context.engine, "~count var=$foo~")
    assert Enum.count(template) == 1
    {:tag, "count", attrs, nil} = Enum.at(template, 0)
    assert [{:assign_tag_attr, "var", {:var, "foo", nil}}] == attrs
  end

  test "tags w/bodies are parsed", context do
    {:ok, template} = Engine.parse(context.engine, Templates.vm_list)
    assert Enum.count(template) == 1
    {:tag, "each", attrs, body} = Enum.at(template, 0)
    assert [{:assign_tag_attr, "var", {:var, "vms", nil}}] == attrs
    assert [{:var, "item", [key: "name"]}, {:text, "\n"}] == body
  end

  test "nested tags are parsed", context do
    {:ok, template} = Engine.parse(context.engine, Templates.vms_per_region)
    assert Enum.count(template) == 1
    {:tag, "each", attrs, body} = Enum.at(template, 0)
    assert [{:assign_tag_attr, "var", {:var, "regions", nil}}] == attrs
    assert {:var, "item", [key: "name"]} = Enum.at(body, 0)
    {:tag, "each", attrs, body} = Enum.at(body, 2)
    assert [{:assign_tag_attr, "var", {:var, "item", [key: "vms"]}}] == attrs
    assert [{:text, "    "}, {:var, "item", [key: "name"]}, {:text, " ("},
            {:var, "item", [key: "id"]}, {:text, ")\n  "}] == body
  end

  test "solo variables are parsed", context do
    {:ok, template} = Engine.parse(context.engine, Templates.solo_variable)
    [{:text, "This is a test.\n"}, {:var, "item", nil}, {:text, ".\n"}] = template
  end

  test "comments w/o terminating newlines are parsed", context do
    Greenbar.Engine.compile!(context.engine, "dangling_comment", Templates.dangling_comment)
  end

  test "double quoted strings lose their quotes", context do
    {:ok, template} = Engine.parse(context.engine, "~attachment title=\"This is a test\"~\n1 2 3\n~end~\n")
    assert [{:tag, "attachment",
             [{:assign_tag_attr, "title", {:string, 1, "This is a test"}}],
             [text: "\n1 2 3\n"]}] === template
  end

end
