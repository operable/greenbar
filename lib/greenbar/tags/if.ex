defmodule Greenbar.Tags.If do

  @moduledoc """
  Conditionally evaluates its body based on the value of the `cond` attribute.

  ## Conditionals

  `if` provides a small set of operators to express conditional logic.

  | Symbol | Name | Variable value types |
  | :--- | :--- | :--- |
  | > | greater than | int, float |
  | >= | greater than equal | int, float |
  | < | less than | int, float |
  | <= | less than equal | int, float |
  | == | equal | int, float, string |
  | != | not equal | int, float, string |
  | bound? | is bound | any |
  | empty? | is empty | list, map |

  ### Example

  The template

  ```
  ~if cond=$doit bound?~
  Hello there!
  ~end~
  ```

  will render an empty string if the template variable is unbound or `nil` and
  the string "Hello there!" if the template variable is bound.

  """

  use Greenbar.Tag, body: true

  def render(_id, attrs, scope) do
    if get_attr(attrs, "cond", false) do
      {:once, scope, new_scope(scope)}
    else
      {:halt, scope}
    end
  end

end
