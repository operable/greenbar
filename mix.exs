defmodule Mix.Tasks.Compile.Hoedown do
  @shortdoc "Compiles Hoedown"

  alias Mix.Shell.IO

  def run(_) do
    if match? {:win32, _}, :os.type do
      Mix.raise("Windows not yet supported")
    else
      File.mkdir_p! "priv"
      {result, error_code} = System.cmd("make", [], stderr_to_stdout: true)
      if error_code == 0 do
        IO.info(result)
        IO.info("(hoedown NIF) compilation complete.")
        :ok
      else
        IO.error("(hoedown NIF) #{result}")
        Mix.raise("(hoedown NIF) compilation failed.")
      end
    end
    :ok
  end
end

defmodule Greenbar.Mixfile do
  use Mix.Project

  def project do
    [app: :greenbar,
     version: "0.14.0",
     elixir: "~> 1.3.1",
     compilers: [:hoedown, :leex, :yecc, :erlang, :elixir, :app],
     erlc_options: [:debug_info, :warnings_as_errors],
     leex_options: [:warnings_as_errors],
     elixirc_paths: elixirc_paths(Mix.env),
     start_permanent: Mix.env == :prod,
     deps: deps] ++ compile_protocols(Mix.env)
  end

  def application do
    [applications: [:crypto,
                    :logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Direct dependencies
      {:piper, github: "operable/piper", branch: "kevsmith/templates"},
      {:hoedown, github: "hoedown/hoedown", branch: "master", app: false},

      # Test and Development
      {:mix_test_watch, "~> 0.2", only: [:dev, :test]},
    ]
  end

  defp compile_protocols(:prod), do: [build_embedded: true]
  defp compile_protocols(_), do: [build_embedded: false]

end
