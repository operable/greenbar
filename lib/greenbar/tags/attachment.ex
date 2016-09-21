defmodule Greenbar.Tags.Attachment do

  @moduledoc """
  Wraps body in an attachment directive

  The initial design is heavily influenced by Slack's attachment API.

  The following tag attributes are supported:

  * `title` -- Attachment title
  * `title_link` -- Optional title link URL
  * `color` -- Color to be used when rendering attachment (interpretation may vary by provider)
  * `image_url` -- Link to image asset (if any)
  * `author` -- Author name
  * `pretext` -- Preamble text displayed before attachment body

  Any other attributes will be interpreted as custom fields and included in the attachments' `fields`
  field. Custom fields have the following structure:

  ```
  %{title: <attribute_name>,
    value: <attribute_value>,
    short: false}
  ```

  ## Example

  The template

  ```
  ~attachment title="VM Use By Region" runtime=$timestamp~
  |Region|Count|
  |---|---|
  ~each var=$regions as=region~
  |~$region.name~|~$region.vm_count~|
  ~end~
  ~end~
  ```

  when executed with the data

 ```
 %{"timestamp" => "Mon Sep 12 13:06:57 EDT 2016",
   "regions" => [%{"name" => "us-east-1", "vm_count" => 113},
                 %{"name" => "us-west-1", "vm_count" => 105}]}
  ```

  generates the rendering directives


  ```
  [%{name: :attachment,
     title: "VM Use By Region",
     fields: [%{short: false,
                title: "runtime",
                value: "Mon Sep 12 13:06:57 EDT 2016"}],
                children: [%{name: :table, children: [%{name: :table_header,
                                    children: [%{name: :table_cell,
                                             children: [%{name: :text, text: "Region"}]},
                                           %{name: :table_cell,
                                             children: [%{name: :text, text: "Count"}]}]},
                              %{name: :table_row,
                                children: [%{name: :table_cell,
                                             children: [%{name: :text, text: "us-east-1"}]},
                                           %{name: :table_cell,
                                             children: [%{name: :text, text: "113"}]}]},
                              %{name: :table_row,
                                children: [%{name: :table_cell,
                                             children: [%{name: :text, text: "us-west-1"}]},
                                           %{name: :table_cell,
                                             children: [%{name: :text, text: "105"}]}]}]}]}]
  ```
  """

  use Greenbar.Tag, body: true

  def render(_id, _attrs, scope) do
    child_scope = new_scope(scope)
    {:once, scope, child_scope}
  end

  def post_body(_id, attrs, scope, _body_scope, response) do
    attachment = make_attachment(attrs)
    # Reverse the body to get it in the correct order for the attachment
    children = Enum.reverse(response)
    {:ok, scope, Map.put(attachment, :children, children)}
  end

  defp make_attachment(nil) do
    make_attachment(%{})
  end
  defp make_attachment(attrs) do
    {attachment, fields} = Enum.reduce(attrs, {%{}, []}, &(gen_attributes(&1, &2)))
    attachment
    |> Map.put(:name, :attachment)
    |> Map.put(:fields, fields)
  end


  # Inspired by Slack's attachment attributes
  # See https://api.slack.com/docs/message-attachments
  defp gen_attributes({"title", value}, {attachment, fields}) do
    {Map.put(attachment, :title, value), fields}
  end
  defp gen_attributes({"title_link", value}, {attachment, fields}) do
    {Map.put(attachment, :title_link, value), fields}
  end
  defp gen_attributes({"pretext", value}, {attachment, fields}) do
    {Map.put(attachment, :pretext, value), fields}
  end
  defp gen_attributes({"color", value}, {attachment, fields}) do
    {Map.put(attachment, :color, value), fields}
  end
  defp gen_attributes({"image_url", value}, {attachment, fields}) do
    {Map.put(attachment, :image_url, value), fields}
  end
  defp gen_attributes({"author", value}, {attachment, fields}) do
    {Map.put(attachment, :author, value), fields}
  end
  defp gen_attributes({key, value}, {attachment, fields}) do
    field = %{title: key,
              value: value,
              short: false}
    {attachment, [field|fields]}
  end

end
