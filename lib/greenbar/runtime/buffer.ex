defmodule Greenbar.Runtime.Buffer do

  alias Greenbar.EvaluationError

  @allowed_directive_atoms Enum.sort([:text, :newline, :bold, :italics, :fixed_width, :header, :link,
                                      :attachment])
  @allowed_directive_strings Enum.sort(Enum.map(@allowed_directive_atoms, &(Atom.to_string(&1))))

  defstruct [items: [], last: nil]

  def append!(%__MODULE__{}=buffer, nil), do: buffer
  def append!(%__MODULE__{}=buffer, text) when is_binary(text) do
    append!(buffer, %{name: :text, text: text})
  end
  def append!(%__MODULE__{last: %{name: :text, text: t1}}=buffer, %{name: :text, text: t2}) do
    %{buffer | last: %{name: :text, text: Enum.join([t1, t2])}}
  end
  def append!(%__MODULE__{last: nil}=buffer, %{name: name}=item) do
    if allowed_directive?(name) do
      %{buffer | last: item}
    else
      raise EvaluationError, message: "Unknown directive: #{inspect name}"
    end
  end
  def append!(%__MODULE__{items: items, last: last}=buffer, %{name: name}=item) do
    if allowed_directive?(name) do
      %{buffer | items: items ++ [last], last: item}
    else
      raise EvaluationError, message: "Unknown directive: #{inspect name}"
    end
  end
  def append!(%__MODULE__{}=buffer, items) when is_list(items) do
    Enum.reduce(items, buffer, &(append!(&2, &1)))
  end
  def append!(%__MODULE__{}, unknown_item) do
    raise EvaluationError, message: "Cannot process unknown template output: #{inspect unknown_item}"
  end

  def join(%__MODULE__{}=firstbuf, %__MODULE__{}=secondbuf) do
    case items(firstbuf) ++ items(secondbuf) do
      [] ->
        %__MODULE__{}
      [item] ->
        %__MODULE__{last: item}
      items ->
        case consolidate(items) do
          [item] ->
            %__MODULE__{last: item}
          items ->
            last = List.last(items)
            items = List.delete_at(items, -1)
            %__MODULE__{last: last, items: items}
        end
    end
  end

  def items(%__MODULE__{items: items, last: nil}), do: items
  def items(%__MODULE__{items: items, last: last}), do: items ++ [last]

  def empty?(%__MODULE__{items: [], last: nil}), do: true
  def empty?(%__MODULE__{}), do: false

  defp allowed_directive?(name) when name in @allowed_directive_atoms, do: true
  defp allowed_directive?(name) when name in @allowed_directive_strings, do: true
  defp allowed_directive?(_), do: false

  defp consolidate(items) do
    Enum.reduce(items, [], &consolidate/2)
    |> Enum.reverse
  end
  defp consolidate(item, []), do: [item]
  defp consolidate(%{name: text, text: t2}, [%{name: :text, text: t1}|t]) do
    t3 = %{name: text, text: t1 <> t2}
    [t3|t]
  end
  defp consolidate(item, acc), do: [item|acc]

end

defimpl Enumerable, for: Greenbar.Runtime.Buffer do

  alias Greenbar.Runtime.Buffer

  def count(%Buffer{}=buf) do
    Enum.count(Buffer.items(buf))
  end

  def member?(%Buffer{}=buf, item) do
    Enum.member?(Buffer.items(buf), item)
  end

  def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}
  def reduce(%Buffer{}=buf, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(buf, &1, fun)}
  def reduce(%Buffer{}=buf, {:cont, acc}, fun) do
    if Buffer.empty?(buf) do
      {:done, acc}
    else
      case buf do
        %Buffer{items: [], last: last} ->
          reduce(%{buf | last: nil}, fun.(last, acc), fun)
        %Buffer{items: [h|t]} ->
          reduce(%{buf| items: t}, fun.(h, acc), fun)
      end
    end
  end

end
