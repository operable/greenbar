defmodule Greenbar.EngineTest do

  alias Greenbar.Engine

  use ExUnit.Case

  test "changing template contents updates Engine's template store" do
    {:ok, engine} = Engine.new
    engine = Engine.compile!(engine, "foo", "foo")
    template1 = Engine.get_template(engine, "foo")
    engine = Engine.compile!(engine, "foo", "bar")
    template2 = Engine.get_template(engine, "foo")
    assert template1.hash != template2.hash
    assert template1.source != template2.source
    assert template1.name === template2.name
  end

end
