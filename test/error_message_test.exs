defmodule Greenbar.ErrorMessageTest do

  alias Greenbar.Engine
  alias Greenbar.CompileError

  use ExUnit.Case

  defp c(engine, template) do
    name = "#{:os.system_time}"
    fn() -> Engine.compile!(engine, name, template) end
  end

  setup_all do
    {:ok, engine} = Engine.new
    [engine: engine]
  end

  test "Missing tildes generate friendly error", context do
    assert_raise(CompileError, "Missing terminating tilde from tag expression: \"~end\"",
      c(context.engine, "~title var=$foo~ ~end"))
  end

  test "Missing incomplete tag attr assignment raises", context do
    assert_raise(CompileError, "Syntax error before <EOL>", c(context.engine, "~title var=~"))
  end

end
