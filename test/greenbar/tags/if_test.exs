defmodule Greenbar.Tags.IfTest do
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

  test "string equality", context do
    result = eval_template(context.engine,
                           "string_equality",
                           ~s[~if cond=$stuff == "stuff"~It worked!~end~],
                           %{"stuff" => "stuff"})

    assert [%{name: :paragraph, children: [%{name: :text, text: "It worked!"}]}] == result
  end

  test "integer greater than", context do
    result = eval_template(context.engine,
                           "integer_greater_than",
                           ~s[~if cond=$num > 5~It's greater!~end~],
                           %{"num" => 6})

    assert [%{name: :paragraph, children: [%{name: :text, text: "It's greater!"}]}] == result

    result = eval_template(context.engine,
                           "integer_greater_than",
                           ~s[~if cond=$num > 5~It's greater!~end~],
                           %{"num" => 4})

    assert [] == result
  end
end
