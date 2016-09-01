defmodule Greenbar do

  alias Greenbar.Template

  def compile!(name, source, opts \\ []) do
    source = String.trim(source)
    case :gb_parser.scan_and_parse(source) do
      {:ok, parsed} ->
        template = Template.compile!(name, parsed, opts)
        hash = :crypto.hash(:sha256, source) |> Base.encode16(case: :lower)
        %{template | hash: hash, source: source}
      {:error, reason} ->
        raise Greenbar.CompileError, message: reason
    end
  end

end
