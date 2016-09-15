defmodule Greenbar.Tags.AttachmentTest do
  use Greenbar.Test.Support.TestCase
  alias Greenbar.Engine

  setup_all do
    {:ok, engine} = Engine.new
    [engine: engine]
  end

  defp eval_template(engine, name, template, args) do
    engine = Engine.compile!(engine, name, template)
    Engine.eval!(engine, name, args)
  end

  test "attachment with body", context do
    result = eval_template(context.engine,
                           "basic_attachment",
                           "~attachment~body~end~",
                           %{})

    assert [%{name: :attachment,
              fields: [],
              children: [
                %{name: :text, text: "body"},
                %{name: :newline}
              ]}] == result
  end

  test "attachment with empty body", context do
    result = eval_template(context.engine,
                           "attachment_no_body",
                           "~attachment~~end~",
                           %{})

    assert [%{name: :attachment,
              fields: [],
              children: []}] == result
  end

  test "attachment with empty body (newline before end)", context do
    result = eval_template(context.engine,
                           "attachment_no_body_newline",
                           "~attachment~\n~end~",
                           %{})

    assert [%{name: :attachment,
              fields: [],
              children: []}] == result
  end

  test "attachment attributes", context do
    result = eval_template(context.engine,
                           "attachment_attrs",
                           "~attachment title=title title_url=title_url color=blue image_url=image_url author=author pretext=pretext~body~end~",
                           %{})

    assert [%{name: :attachment,
              title: "title",
              title_url: "title_url",
              color: "blue",
              image_url: "image_url",
              author: "author",
              pretext: "pretext",
              fields: [],
              children: [
                %{name: :text, text: "body"},
                %{name: :newline}
              ]}] == result
  end

  test "attachment fields", context do
    [attachment|_] = eval_template(context.engine,
                                   "attachment_fields",
                                   "~attachment title=title field1=Foo field2=\"Bar Baz\"~body~end~",
                                   %{})

    fields = Enum.sort(attachment.fields)
    expected = Enum.sort([%{title: "field1", value: "Foo", short: false},
                          %{title: "field2", value: "Bar Baz", short: false}])

    assert fields == expected
  end
end
