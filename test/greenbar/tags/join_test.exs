defmodule Greenbar.Tags.JoinTest do
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

  test "simple join", context do
    result = eval_template(context.engine,
                           "simple_join",
                           "~join var=$stuff~~$item~~end~",
                           %{"stuff" => ["foo", "bar", "baz"]})

    assert [%{name: :paragraph, children: [%{name: :text, text: "foo, bar, baz"}]}] == result
  end

  test "simple join with non-default joiner", context do
    result = eval_template(context.engine,
                           "simple_join_with_joiner",
                           "~join var=$stuff with=\"-\" ~~$item~~end~",
                           %{"stuff" => ["foo", "bar", "baz"]})

    assert [%{name: :paragraph, children: [%{name: :text, text: "foo-bar-baz"}]}] == result
  end

  test "join with a body", context  do
    result = eval_template(context.engine,
                           "join_with_body",
                           "~join var=$stuff~~$item.name~~end~",
                           %{"stuff" => [%{"name" => "larry"},
                                         %{"name" => "moe"},
                                         %{"name" => "curly"}]})

    assert [%{name: :paragraph, children: [%{name: :text, text: "larry, moe, curly"}]}] == result
  end

  test "join with single input", context do
    result = eval_template(context.engine,
                           "join_with_one_input",
                           "~join var=$stuff~~$item~~end~",
                           %{"stuff" => ["highlander"]})

    assert [%{name: :paragraph, children: [%{name: :text, text: "highlander"}]}] == result
  end

  test "nested joins", context do
    result = eval_template(context.engine,
                           "nested",
                           "~join var=$stuff with=\"-\"~~join var=$item as=i~~$i~~end~~end~",
                           %{"stuff" => [["one", "two", "three"],
                                         ["four", "five", "six"],
                                         ["seven", "eight", "nine"]]})

    assert [%{name: :paragraph, children: [
                 %{name: :text, text: "one, two, three-four, five, six-seven, eight, nine"}]}] == result
  end

  test "join inside an each", context do
    result = eval_template(context.engine,
                           "join_inside_an_each",
                           """
                           ~each var=$people as=person~
                           **Name:** ~$person.name~
                           **Mech Keyboards:** ~join var=$person.mech_keyboards with=", "~~$item.name~~end~
                           ~end~
                           """,
                           %{"people" => [%{"name" => "Shelton",
                                            "mech_keyboards" => []},
                                          %{"name" => "Mark",
                                            "mech_keyboards" => [%{"name" => "Ergodox"}]},
                                          %{"name" => "Patrick",
                                            "mech_keyboards" => [%{"name" => "MiniVan"}]}]})

    assert [%{name: :paragraph, children: [%{name: :bold, text: "Name:"}, %{name: :text, text: " Shelton"}, %{name: :newline},
                                           %{name: :bold, text: "Mech Keyboards:"}, %{name: :text, text: " "}, %{name: :newline},
                                           %{name: :bold, text: "Name:"}, %{name: :text, text: " Mark"}, %{name: :newline},
                                           %{name: :bold, text: "Mech Keyboards:"}, %{name: :text, text: " Ergodox"}, %{name: :newline},
                                           %{name: :bold, text: "Name:"}, %{name: :text, text: " Patrick"}, %{name: :newline},
                                           %{name: :bold, text: "Mech Keyboards:"}, %{name: :text, text: " MiniVan"}]}] = result
  end
end
