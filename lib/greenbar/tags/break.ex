defmodule Greenbar.Tags.Break do

  @moduledoc """
  Inserts a hard newline into the rendered template.

  This can be useful to work around situtions where Markdown consolidates newlines.

  ### Example

  Normally Markdown will combine two code blocks into one if they are separated by a single newline.

  ```
  `This is a line of code`
  `This is another line of code`
  ```

  will render as `This a line of codeThis is another line of code`

  ```
  `This is a line of code`
  ~br~
  `This is another line of code`
  ```

  will render as

  ```
  This is a line of code
  This is another line of code
  ```
  """

  use Greenbar.Tag, name: "br"


  def render(_id, _attrs, scope) do
    {:halt, %{"name" => "newline"}, scope}
  end

end
