defmodule Greenbar.Tags.JoinTest do
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

  test "simple join", context do
    result = eval_template(context.engine,
                           "simple_join",
                           "~join var=$stuff~~$item~~end~",
                           %{"stuff" => ["foo", "bar", "baz"]})

    assert [%{name: :text, text: "foo, bar, baz"}] == result
  end

  test "simple join with non-default joiner", context do
    result = eval_template(context.engine,
                           "simple_join_with_joiner",
                           "~join var=$stuff with=ooo ~~$item~~end~",
                           %{"stuff" => ["foo", "bar", "baz"]})

    assert [%{name: :text, text: "fooooobarooobaz"}] == result
  end

  test "join with a body", context  do
    result = eval_template(context.engine,
                           "join_with_body",
                           "~join var=$stuff~~$item.name~~end~",
                           %{"stuff" => [%{"name" => "larry"},
                                         %{"name" => "moe"},
                                         %{"name" => "curly"}]})

    assert [%{name: :text, text: "larry, moe, curly"}] == result
  end

  test "join with single input", context do
    result = eval_template(context.engine,
                           "join_with_one_input",
                           "~join var=$stuff~~$item~~end~",
                           %{"stuff" => ["highlander"]})

    assert [%{name: :text, text: "highlander"}] == result
  end

  test "nested joins", context do
    result = eval_template(context.engine,
                           "nested",
                           "~join var=$stuff with=ooo~~join var=$item as=i~~$i~~end~~end~",
                           %{"stuff" => [["one", "two", "three"],
                                         ["four", "five", "six"],
                                         ["seven", "eight", "nine"]]})

    assert [%{name: :text, text: "one, two, threeooofour, five, sixoooseven, eight, nine"}] == result
  end
end
