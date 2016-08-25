defprotocol Greenbar.Exec.Interpret do

  alias Greenbar.Engine
  alias Piper.Common.Scope.Scoped

  @spec run(Greenbar.Exec.Interpret, Engine.t, Scoped.t) :: {:ok, String.t, Scoped.t} | {:error, term}
  def run(executable, engine, scope)

end
