defmodule Greenbar.Engine do

  @default_tags [Greenbar.Tags.Title, Greenbar.Tags.Count]

  defstruct [tags: %{}]

  def default() do
    engine = %__MODULE__{}
    engine = Enum.reduce(@default_tags, engine, fn(tag, engine) -> {:ok, engine} = add_tag(engine, tag)
                                                                   engine end)
    {:ok, engine}
  end

  def add_tag(%__MODULE__{}=engine, tag_mod) when is_atom(tag_mod) do
    if tag_module?(tag_mod) do
      {:ok, %{engine | tags: Map.put(engine.tags, tag_mod.name, tag_mod)}}
    else
      {:error, :not_a_tag}
    end
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

end
