defmodule Greenbar.Tags.AttachmentTest do
  use Greenbar.Test.Support.TestCase
  alias Greenbar.Engine

  setup_all do
    {:ok, engine} = Engine.new
    [engine: engine]
  end

  defp eval_template(engine, name, template, args) do
    engine = Engine.compile!(engine, name, template)
    Engine.eval!(engine, name, scope: args)
  end

  test "attachment with body", context do
    result = eval_template(context.engine,
                           "basic_attachment",
                           "~attachment~body~end~",
                           %{})

    assert [%{"name" => "attachment",
              "fields" => [],
              "children" => [
                %{"name" => "paragraph", "children" => [%{"name" => "text", "text" => "body"}]}
              ]}] == result
  end

  test "attachment with empty body", context do
    result = eval_template(context.engine,
                           "attachment_no_body",
                           "~attachment~~end~",
                           %{})

    assert [%{"name" => "attachment",
              "fields" => [],
              "children" => []}] == result
  end

  test "attachment with empty body (newline before end)", context do
    result = eval_template(context.engine,
                           "attachment_no_body_newline",
                           "~attachment~\n~end~",
                           %{})

    assert [%{"name" => "attachment",
              "fields" => [],
              "children" => []}] == result
  end

  test "attachment with empty body with other template content", context do
    result = eval_template(context.engine, "attachment_no_body_more_content",
      """
~attachment~~end~
~each var=$things as=thing~
Displaying _~$thing~_
~end~
""", %{"things" => ["a","b","c","d"]})
    assert [%{"children" => [], "fields" => [], "name" => "attachment"},
            %{"name" => "paragraph", "children" => [%{"name" => "text", "text" => "Displaying "}, %{"name" => "italics", "text" => "a"}, %{"name" => "newline"},
                                           %{"name" => "text", "text" => "Displaying "}, %{"name" => "italics", "text" => "b"}, %{"name" => "newline"},
                                           %{"name" => "text", "text" => "Displaying "}, %{"name" => "italics", "text" => "c"}, %{"name" => "newline"},
                                           %{"name" => "text", "text" => "Displaying "}, %{"name" => "italics", "text" => "d"}]}] == result
  end

  test "attachment with empty body and attrs with other template content", context do
    result = eval_template(context.engine, "attachment_no_body_attrs_more_content",
      """
~attachment color=red title="Testing 123"~
~end~
* One
* Two
* Three
      """, %{})
    assert [%{"children" => [], "color" => "red", "fields" => [], "name" => "attachment",
              "title" => "Testing 123"},
            %{"children" => [%{"children" => [%{"name" => "text", "text" => "One"}],
                           "name" => "list_item"},
                         %{"children" => [%{"name" => "text", "text" => "Two"}],
                           "name" => "list_item"},
                         %{"children" => [%{"name" => "text", "text" => "Three"}],
                           "name" => "list_item"}], "name" => "unordered_list"}] == result
  end

  test "attachment with a footer attr", context do
    result = eval_template(context.engine, "attachment_with_footer",
                           ~s(~attachment title="Footer Test" footer="This is a footer"~~end~),
                           %{})
    assert [%{"children" => [],
              "title" => "Footer Test",
              "footer" => "This is a footer",
              "fields" => [],
              "name" => "attachment"}] == result

  end

  test "string attachment attribute names", context do
    result = eval_template(context.engine, "attachment_string_attrs",
                           "~attachment \"Error Status\"=$error~~end~",
                           %{"error" => "Network disconnect"})
    assert [%{"children" => [],
              "fields" =>[%{"short" => false, "title" => "Error Status",
                         "value" => "Network disconnect"}], "name" => "attachment"}] == result
  end

  test "attachment attributes", context do
    result = eval_template(context.engine,
                           "attachment_attrs",
                           "~attachment title=title title_url=title_url color=blue image_url=image_url author=author pretext=pretext~body~end~",
                           %{})

    assert [%{"name" => "attachment",
              "title" => "title",
              "title_url" => "title_url",
              "color" => "blue",
              "image_url" => "image_url",
              "author" => "author",
              "pretext" => "pretext",
              "fields" => [],
              "children" => [
                %{"name" => "paragraph",
                  "children" => [%{"name" => "text", "text" => "body"}]}
              ]}] == result
  end

  test "attachment fields", context do
    [attachment|_] = eval_template(context.engine,
                                   "attachment_fields",
                                   "~attachment title=title field1=Foo field2=\"Bar Baz\"~body~end~",
                                   %{})

    fields = Enum.sort(attachment["fields"])
    expected = Enum.sort([%{"title" => "field1", "value" => "Foo", "short" => false},
                          %{"title" => "field2", "value" => "Bar Baz", "short" => false}])

    assert fields == expected
  end
end
