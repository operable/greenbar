defmodule Greenbar.Test.Test.HipChatRendererTest do
  use ExUnit.Case

  alias Greenbar.Renderers.HipChatRenderer

  test "processes a list of directives" do
    directives = [
      %{"name" => "text",
        "text" => "This is a rendering test. First, let's try italics: "},
      %{"name" => "italics",
        "text" => "I'm italic text!"},
      %{"name" => "text",
        "text" => "\nThat was fun; now let's do bold: "},
      %{"name" => "bold",
        "text" => "BEHOLD! BOLD!"},
      %{"name" => "text",
        "text" => "\nFascinating. How about some fixed width text?  "},
      %{"name" => "fixed_width",
        "text" => "BEEP BOOP... I AM A ROBOT... BEEP BOOP"},
      %{"name" => "newline"},
      %{"name" => "fixed_width_block", "text" => "I AM FROM THE FUTURE. BLEEP. BOOP."},
      %{"name" => "text",
        "text" => "\nWow, good stuff. And now... AN ASCII TABLE!\n\n"},
      %{"name" => "table",
        "children" => [%{"name" => "table_header",
                         "children" => [
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Member"}]},
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Instrument"}]}]},
                       %{"name" => "table_row",
                         "children" => [
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Geddy Lee"}]},
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Vocals, Bass, Keyboards"}]}]},
                       %{"name" => "table_row",
                         "children" => [
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Alex Lifeson"}]},
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Guitar"}]}]},
                       %{"name" => "table_row",
                         "children" => [
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Neal Peart"}]},
                           %{"name" => "table_cell",
                             "children" => [
                               %{"name" => "text",
                                 "text" => "Drums, Percussion"}]}]}]},
      %{"name" => "text",
        "text" => "\nHow do you like them apples?"}]

    rendered = HipChatRenderer.render(directives)
    expected = """
    This is a rendering test. First, let's try italics: <i>I'm italic text!</i>
    That was fun; now let's do bold: <strong>BEHOLD! BOLD!</strong>
    Fascinating. How about some fixed width text?  <code>BEEP BOOP... I AM A ROBOT... BEEP BOOP</code><pre>I AM FROM THE FUTURE. BLEEP. BOOP.</pre>
    Wow, good stuff. And now... AN ASCII TABLE!

    <pre>+--------------+-------------------------+
    | Member       | Instrument              |
    +--------------+-------------------------+
    | Geddy Lee    | Vocals, Bass, Keyboards |
    | Alex Lifeson | Guitar                  |
    | Neal Peart   | Drums, Percussion       |
    +--------------+-------------------------+
    </pre>
    How do you like them apples?
    """ |> String.trim
    assert expected == rendered
  end


  test "handles unrecognized text directives" do
    directives = [
      %{"name" => "text", "text" => "Important message: "},
      %{"name" => "wat", "text" => "whatever"}
    ]

    rendered = HipChatRenderer.render(directives)
    assert "Important message: whatever" == rendered
  end

  test "completely unrecognized directives get rendered directly" do
    directives = [
      %{"name" => "text", "text" => "Important message: "},
      %{"name" => "wat", "something" => "whatever", "meaning_of_life" => 42}
    ]

    rendered = HipChatRenderer.render(directives)
    expected = "Important message: <br/>Unrecognized directive: wat"

    assert expected == rendered
  end

  test "handles link directives" do
    directives = [
      %{"name" => "link", "text" => "a link", "url" => "http://www.example.com"}
    ]

    rendered = HipChatRenderer.render(directives)
    expected = "<a href='http://www.example.com'>a link</a>"

    assert expected == rendered
  end

  test "handles link directive with a nil url" do
    directives = [
      %{"name" => "link", "text" => "a link", "url" => nil}
    ]

    rendered = HipChatRenderer.render(directives)
    expected = "(invalid link! text:\"a link\" url: \"nil\")"

    assert expected == rendered
  end

  test "handles link directive with nil text" do
    directives = [
      %{"name" => "link", "text" => nil, "url" => "http://www.example.com"}
    ]

    rendered = HipChatRenderer.render(directives)
    expected = "<a href='http://www.example.com'>http://www.example.com</a>"

    assert expected == rendered
  end

  test "handles table cells that have fixed-width formatting" do
    directives = [%{"name" => "table",
                   "children" => [%{"name" => "table_header",
                                    "children" => [
                                      %{"name" => "table_cell",
                                        "children" => [
                                          %{"name" => "text",
                                            "text" => "Foo"}]}]},
                                  %{"name" => "table_row",
                                    "children" => [
                                      %{"name" => "table_cell",
                                        "children" => [
                                          %{"name" => "fixed_width",
                                            "text" => "Hello World"}]}]}]}]

    rendered = HipChatRenderer.render(directives)
    expected = """
    <pre>+-------------+
    | Foo         |
    +-------------+
    | Hello World |
    +-------------+
    </pre>
    """ |> String.trim()

    assert expected == rendered
  end


  test "omits a newline after attachments that are each a single line of output" do
    directives = [%{"name" => "attachment",
                    "fields" => [],
                    "children" => [%{"name" => "text", "text" => "Attachment 1"}]},
                  %{"name" => "attachment",
                    "fields" => [],
                    "children" => [%{"name" => "text", "text" => "Attachment 2"}]},
                  %{"name" => "attachment",
                    "fields" => [],
                    "children" => [%{"name" => "text", "text" => "Attachment 3"}]},
                  %{"name" => "attachment",
                    "fields" => [],
                    "children" => [%{"name" => "text", "text" => "Attachment 4"},
                                   %{"name" => "newline"},
                                   %{"name" => "text", "text" => "Plus a newline"}]},
                  %{"name" => "attachment",
                    "fields" => [],
                    "children" => [%{"name" => "text", "text" => "Attachment 5"},
                                   %{"name" => "newline"},
                                   %{"name" => "text", "text" => "Plus a newline"}]},
                  %{"name" => "attachment",
                    "fields" => [],
                    "children" => [%{"name" => "text", "text" => "Attachment 6"}]},
                  %{"name" => "text",
                    "text" => "Random text"},
                  %{"name" => "newline"},
                  %{"name" => "attachment",
                    "fields" => [],
                    "children" => [%{"name" => "text", "text" => "Attachment 7"}]}]

    expected = """
    Attachment 1<br/>
    Attachment 2<br/>
    Attachment 3<br/>
    Attachment 4<br/>
    Plus a newline<br/>
    <br/>
    Attachment 5<br/>
    Plus a newline<br/>
    <br/>
    Attachment 6<br/>
    Random text<br/>
    Attachment 7
    """ |> String.replace("\n", "")

    rendered = HipChatRenderer.render(directives)

    assert expected == rendered
  end
end
