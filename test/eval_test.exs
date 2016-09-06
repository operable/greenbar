defmodule Greenbar.EvalTest do

  use Greenbar.Test.Support.TestCase
  alias Greenbar.Engine

  setup_all do
    {:ok, engine} = Engine.new
    [engine: engine]
  end

  defp eval_template(engine, name, template, args) do
    engine = Engine.compile!(engine, name, template)
    Engine.eval!(engine, name, args)
  end

  test "list variables render correctly", context do
    result = eval_template(context.engine, "solo_variable", Templates.solo_variable, %{"item" => ["a","b","c"]})
    Assertions.directive_structure(result, [:text, :newline, :text])
    assert Enum.at(result, 2) == %{name: :text, text: "[\"a\",\"b\",\"c\"]."}
  end

  test "map variables render correctly", context do
    result = eval_template(context.engine, "solo_variable", Templates.solo_variable, %{"item" => %{"name" => "baz"}})
    Assertions.directive_structure(result, [:text, :newline, :text])
  end

  test "parent/child scopes work", context do
    data = %{"items" => ["a","b","c"]}
    result = eval_template(context.engine, "parent_child_scopes", Templates.parent_child_scopes, data)
    Assertions.directive_structure(result, [:text, :newline, # Header
                                            :text, :fixed_width, :newline, # a
                                            :text, :fixed_width, :newline, # b
                                            :text, :fixed_width, :newline, # c
                                            :text]) # Footer
  end

  test "indexed variables work", context do
    data = %{"results" => [%{"documentation" => "These are my docs"}]}
    result = eval_template(context.engine, "documentation", Templates.documentation, data)
    assert [%{name: :text, text: "These are my docs"}] == result
  end

  test "real world template works", context do
    data = %{"results" => [%{"id" => "bundle_123", "name" => "First Bundle", "enabled_version" => %{"version" => "1.1"}},
                           %{"id" => "bundle_124", "name" => "Second Bundle", "enabled_version" => %{"version" => "1.2"}},
                           %{"id" => "bundle_125", "name" => "Third Bundle", "enabled_version" => %{"version" => "1.3"}}]}
    result = eval_template(context.engine, "bundles", Templates.bundles, data)
    Assertions.directive_structure(result, [:text, :newline, :newline, #header
                                            :text, :newline, # Bundle ID
                                            :text, :newline, # Bundle Name
                                            :text, :newline, # Enabled Version
                                            :text, :newline, # Bundle ID
                                            :text, :newline, # Bundle Name
                                            :text, :newline, # Enabled Version
                                            :text, :newline, # Bundle ID
                                            :text, :newline, # Bundle Name
                                            :text]) # Enabled Version

  end

  test "if tag", context do
    # Bound? fails
    result = eval_template(context.engine, "if_tag", Templates.if_tag, %{})
    Assertions.directive_structure(result, [:text])

    # Bound? succeeds
    result = eval_template(context.engine, "if_tag", Templates.if_tag, %{"item" => "`Kilroy was here`"})
    Assertions.directive_structure(result, [:text, :newline, :fixed_width])
  end

  test "not_empty? check works", context do
    result = eval_template(context.engine, "not_empty_check", Templates.not_empty_check, %{"user_creators" => ["bob", "sue", "frank"]})
    Assertions.directive_structure(result, [:newline, :text, :newline, :newline, # header
                                            :text, :newline, # bob
                                            :text, :newline, # sue
                                            :text]) #frank
    result = eval_template(context.engine, "not_empty_check", Templates.not_empty_check, %{})
    assert length(result) == 0
  end

  test "building ordered lists works", context do
    result = eval_template(context.engine, "generated_ordered_list", Templates.generated_ordered_list, %{"users" => [%{"name" => "Susan"},
                                                                                                                     %{"name" => "Oscar"}]})
    assert result === [%{children: [%{children: [%{name: :text, text: "Susan"}, %{name: :newline}],
                                      name: :list_item},
                                    %{children: [%{name: :text, text: "Oscar"}, %{name: :newline}],
                                      name: :list_item}], name: :ordered_list}]
  end

  test "building unordered lists works", context do
    result = eval_template(context.engine, "generated_unordered_list", Templates.generated_unordered_list, %{"users" => [%{"name" => "Mr. Hooper"},
                                                                                                                         %{"name" => "Grover"}]})
    assert result === [%{children: [%{children: [%{name: :text, text: "Mr. Hooper"}, %{name: :newline}],
                                      name: :list_item},
                                    %{children: [%{name: :text, text: "Grover"}, %{name: :newline}],
                                      name: :list_item}], name: :unordered_list}]
  end

  test "building dynamic lists works", context do
    [result] = eval_template(context.engine, "dynamic_list", Templates.dynamic_list, %{"users" => [%{"name" => "Mr. Hooper"},
                                                                                                   %{"name" => "Grover"}],
                                                                                       "li" => "*"})
    assert result.name == :unordered_list
    [result] = eval_template(context.engine, "dynamic_list", Templates.dynamic_list, %{"users" => [%{"name" => "Mr. Hooper"},
                                                                                                   %{"name" => "Grover"}],
                                                                                       "li" => "1."})
    assert result.name == :ordered_list
  end

  test "nested lists work", context do
    result = eval_template(context.engine, "nested_lists", Templates.nested_lists, %{"groups" => [%{"name" => "admins",
                                                                                                    "users" => [%{"name" => "Big Bird"}]},
                                                                                                  %{"name" => "accounting",
                                                                                                    "users" => [%{"name" => "The Count"}]}]})
    assert result === [%{children: [%{children: [%{name: :text, text: "admins"}, %{name: :newline}],
                                      name: :list_item}], name: :unordered_list},
                       %{children: [%{children: [%{name: :text, text: "Big Bird"}, %{name: :newline}],
                                      name: :list_item}], name: :ordered_list},
                       %{children: [%{children: [%{name: :text, text: "accounting"},
                                                 %{name: :newline}], name: :list_item}], name: :unordered_list},
                       %{children: [%{children: [%{name: :text, text: "accounting"},
                                                 %{name: :newline}], name: :list_item}],
                         name: :ordered_list}]
  end
end
