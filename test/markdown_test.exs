defmodule Greenbar.MarkdownTest do

  alias Greenbar.Markdown

  use ExUnit.Case

  test "italics are parsed correctly" do
    {:ok, output} = Markdown.analyze("This is a test.\n_foo_\n")
    assert output === [%{name: :text, text: "This is a test."},
                       %{name: :newline},
                       %{name: :italics, text: "foo"},
                       %{name: :newline}]
  end

  test "boldface are parsed correctly" do
    {:ok, output} = Markdown.analyze("This is a test.\n__foo__\n")
    assert output === [%{name: :text, text: "This is a test."},
                       %{name: :newline},
                       %{name: :bold, text: "foo"},
                       %{name: :newline}]
  end

  test "single line code blocks are parsed correctly" do
    {:ok, output} = Markdown.analyze("`This is a test`")
    assert output === [%{name: :fixed_width, text: "This is a test"},
                       %{name: :newline}]
  end

  test "multi line code blocks are parsed correctly" do
    {:ok, output} = Markdown.analyze("```This is\na test```")
    assert output === [%{name: :fixed_width, text: "This is\na test"},
                       %{name: :newline}]
  end

  test "headers are parsed correctly" do
    {:ok, output} = Markdown.analyze("# H1\n\n## H2\n\n### H3")
    assert output === [%{name: :header, level: 1,
                         text: "H1"},
                       %{name: :header, level: 2,
                         text: "H2"},
                       %{name: :header, level: 3,
                         text: "H3"}]
  end

  test "links are parsed correctly" do
    {:ok, output} = Markdown.analyze("[operable](https://operable.io)")
    assert output === [%{name: :link,
                         text: "operable",
                         url: "https://operable.io"},
                       %{name: :newline}]
  end

end
