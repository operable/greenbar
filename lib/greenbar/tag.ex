defmodule Greenbar.Tag do

  alias Piper.Common.Scope.Scoped

  @type tag_attrs :: Map.t
  @type tag_output :: String.t | nil

  @type continue_response :: {:cont, tag_output, Scoped.t, Scoped.t}
  @type done_response :: {:halt, tag_output, Scoped.t}
  @type error_response :: {:error, term}

  @callback name() :: String.t
  @callback render(attrs :: tag_attrs, scope :: Scoped.t) :: continue_response | done_response | error_response

  defmacro __using__(_) do
    quote do
      @behaviour Greenbar.Tag

      import unquote(__MODULE__), only: [get_attr: 2]
    end
  end

  def get_attr(attrs, name) do
    Map.get(attrs, name)
  end

end
