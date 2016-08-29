defmodule Greenbar.Template do

  alias Piper.Common.Scope
  alias Piper.Common.Scope.Scoped
  alias Greenbar.Generator

  defstruct [:name, :template_fn, :source, :hash, :timestamp, :debug_source]

  def compile!(name, parsed, opts \\ []) do
    quoted = Generator.generate_template(parsed)
    {template_fn, _} = Code.eval_quoted(quoted)
    debug_source = if Keyword.get(opts, :debug, false) == true do
      Macro.to_string(quoted)
    else
      nil
    end
    %__MODULE__{name: name, template_fn: template_fn, debug_source: debug_source, timestamp: System.system_time()}
  end

  def eval!(%__MODULE__{}=template, engine, scope) do
    eval_scope = Scope.from_map(scope)
    {:ok, eval_scope} = Scoped.set(eval_scope, "__ENGINE__", engine)
    template.template_fn.(eval_scope, [])
  end

end

defimpl String.Chars, for: Greenbar.Template do

  def to_string(template) do
    "Greenbar.Template<name: #{template.name},timestamp: #{template.timestamp}, hash: #{template.hash}>"
  end

end
