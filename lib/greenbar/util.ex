defmodule Greenbar.Util do

  def combine(a, b) when is_list(a) and is_list(b) do
    [a] ++ b
  end
  def combine(a, b) when is_list(a) do
    a ++ [b]
  end
  def combine(a, b) when is_list(b) do
    [a|b]
  end
  def combine(a, b) do
    [a, b]
  end

end
