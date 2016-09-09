defmodule Greenbar.Test.Support.TestCase do

  defmacro __using__(_) do
    quote do
        require Greenbar.Test.Support.Assertions

        alias Greenbar.Test.Support.Assertions
        alias Greenbar.Test.Support.Templates
        alias Greenbar.Engine

        use ExUnit.Case

    end
  end

end
