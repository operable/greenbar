defmodule Greenbar.Engine do

  @default_tags [Greenbar.Tags.Title, Greenbar.Tags.Count, Greenbar.Tags.Each,
                 Greenbar.Tags.Break, Greenbar.Tags.If]

  defstruct [tags: %{}, templates: %{}]

  alias Greenbar.Template

  def new() do
    engine = %__MODULE__{}
    engine = Enum.reduce(@default_tags, engine, fn(tag, engine) -> {:ok, engine} = add_tag(engine, tag)
                                                                   engine end)
    {:ok, engine}
  end

  def compile!(%__MODULE__{}=engine, name, source, opts \\ []) do
    source = Enum.join([String.trim(source), "\n"])
    hash = :crypto.hash(:sha256, source) |> Base.encode16(case: :lower)
    if should_compile?(engine, name, hash, opts) do
      case :gb_parser.scan_and_parse(source) do
        {:ok, parsed} ->
          {_, opts} = Keyword.pop(opts, :force)
          template = Template.compile!(name, parsed, opts)
          template = %{template | hash: hash, source: source}
          engine = %{engine | templates: Map.put(engine.templates, template.name, template)}
          engine
        {:error, reason} ->
          raise Greenbar.CompileError, message: reason
      end
    else
      engine
    end
  end

  def eval!(%__MODULE__{}=engine, name, scope \\ %{}) when is_binary(name) do
    case get_template(engine, name) do
      nil ->
        {:error, :not_found}
      template ->
        Template.eval!(template, engine, scope)
    end
  end

  def has_template?(%__MODULE__{}=engine, name) do
    Map.has_key?(engine.templates, name)
  end

  def get_template(%__MODULE__{}=engine, name, default \\ nil) when is_binary(name) do
    Map.get(engine.templates, name, default)
  end

  def delete_template(%__MODULE__{}=engine, name) do
    %{engine | templates: Map.delete(engine.templates, name)}
  end

  def reset_templates(%__MODULE__{}=engine) do
    %{engine | templates: %{}}
  end

  def add_tag(%__MODULE__{}=engine, tag_mod) when is_atom(tag_mod) do
    if tag_module?(tag_mod) do
      {:ok, %{engine | tags: Map.put(engine.tags, tag_mod.name, tag_mod)}}
    else
      {:error, :not_a_tag_module}
    end
  end

  def remove_tag(%__MODULE__{}=engine, tag_name) when is_binary(tag_name) do
    %{engine | templates: Map.delete(engine.templates, tag_name)}
  end
  def remove_tag(%__MODULE__{}=engine, tag_mod) when is_atom(tag_mod) do
    tag_name = tag_mod.name()
    remove_tag(engine, tag_name)
  end

  def get_tag(%__MODULE__{}=engine, tag_name) when is_binary(tag_name) do
    Map.get(engine.tags, tag_name)
  end

  defp tag_module?(tag_mod) do
    mod_attrs = tag_mod.__info__(:attributes)
    case Keyword.get(mod_attrs, :behaviour) do
      nil ->
        false
      behaviours ->
        Enum.member?(behaviours, Greenbar.Tag)
    end
  end

  defp should_compile?(engine, name, hash, opts) do
    if Keyword.get(opts, :force, false) == true do
        true
    else
      case Map.get(engine.templates, name) do
        nil ->
          true
        template ->
          template.hash != hash
      end
    end
  end

end
