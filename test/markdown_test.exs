defmodule Greenbar.MarkdownTest do

  alias :greenbar_markdown, as: Markdown

  use ExUnit.Case

  test "italics are parsed correctly" do
    {:ok, output} = Markdown.analyze("This is a test.\n\n_foo_\n")
    assert output === [%{name: :paragraph, children: [%{name: :text, text: "This is a test."}]},
                       %{name: :paragraph, children: [%{name: :italics, text: "foo"}]}]
  end

  test "boldface are parsed correctly" do
    {:ok, output} = Markdown.analyze("This is a test.\n\n__foo__\n")
    assert output === [%{name: :paragraph, children: [%{name: :text, text: "This is a test."}]},
                       %{name: :paragraph, children: [%{name: :bold, text: "foo"}]}]
  end

  test "paragraphs are parsed correctly" do
    {:ok, output} = Markdown.analyze("This is a test.\n\n\n__foo__\n\n\nThis is another test.\n")
    assert output === [%{name: :paragraph, children: [%{name: :text, text: "This is a test."}]},
                       %{name: :paragraph, children: [%{name: :bold, text: "foo"}]},
                       %{name: :paragraph, children: [%{name: :text, text: "This is another test."}]}]
  end

  test "single line code blocks are parsed correctly" do
    {:ok, output} = Markdown.analyze("`This is a test`")
    assert output === [%{name: :paragraph, children: [%{name: :fixed_width, text: "This is a test"}]}]
  end

  test "multi line code blocks are parsed correctly" do
    {:ok, output} = Markdown.analyze("""
```
This is
a test
```
""")
    assert output === [%{name: :fixed_width_block, text: "This is\na test"}]
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
    {:ok, output} = Markdown.analyze("Click on [operable](https://operable.io) to learn more about Cog.\n")
    assert output === [%{name: :paragraph, children: [%{name: :text, text: "Click on "},
                                                      %{name: :link, text: "operable", url: "https://operable.io"},
                                                      %{name: :text, text: " to learn more about Cog."}]}]
  end

  test "unordered lists are parsed correctly" do
    {:ok, output} = Markdown.analyze("* One\n* Two\n* Three\n")
    assert output === [%{children: [%{children: [%{name: :text, text: "One"}],
                                      name: :list_item},
                                    %{children: [%{name: :text, text: "Two"}],
                                      name: :list_item},
                                    %{children: [%{name: :text, text: "Three"}],
                                      name: :list_item}], name: :unordered_list}]
  end

  test "ordered lists are parsed correctly" do
    {:ok, output} = Markdown.analyze("1. Abc\n1. Def\n1. _Ghi_\n")
    assert output === [%{children: [%{children: [%{name: :text, text: "Abc"}],
                                      name: :list_item},
                                    %{children: [%{name: :text, text: "Def"}],
                                      name: :list_item},
                                    %{children: [%{name: :italics, text: "Ghi"}],
                                      name: :list_item}], name: :ordered_list}]
  end

  test "codeblocks don't nest" do
    {:ok, output} = Markdown.analyze("```\n```\nfoo\n```\n```\n")
    assert output === [%{name: :paragraph, children: [%{name: :text, text: "foo"}, %{name: :newline}]}]
  end

  test "empty link titles don't trigger a crash" do
    {:ok, output} = Markdown.analyze("[](here)")
    assert output === [%{name: :paragraph, children: [%{name: :link, text: "", url: "here"}]}]
  end

  test "empty link urls don't trigger a crash" do
    {:ok, output} = Markdown.analyze("[foo]()")
    assert output === [%{name: :paragraph, children: [%{name: :link, text: "foo", url: ""}]}]
  end

end
