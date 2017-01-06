defmodule Greenbar.WhitespaceTest do
  use Greenbar.Test.Support.TestCase
  alias Greenbar.Engine

  setup_all do
    {:ok, engine} = Engine.new
    [engine: engine]
  end

  defp eval_template(engine, name, template, args) do
    engine = Engine.compile!(engine, name, template)
    Engine.eval!(engine, name, scope: args)
  end

  test "stripping whitespace around a multiline each tag", context do
    template = """
    ~each var=$bundles as=bundle~
    Bundle: ~$bundle~
    ~end~
    """

    actual = eval_template(context.engine, "bundles", template, %{"bundles" => ["ec2", "ecs", "s3"]})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "Bundle: ec2"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: ecs"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: s3"}]}]

    assert expected == actual
  end

  test "stripping whitespace around a multiline each tag with surrounding newlines", context do
    template = """
    These are the bundles.

    ~each var=$bundles as=bundle~
    Bundle: ~$bundle~
    ~end~

    Look at them!
    """

    actual = eval_template(context.engine, "bundles_with_surrounding_newlines", template, %{"bundles" => ["ec2", "ecs", "s3"]})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "These are the bundles."}]},
                %{name: :paragraph,
                  children: [%{name: :text, text: "Bundle: ec2"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: ecs"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: s3"}]},
                %{name: :paragraph,
                  children: [%{name: :text, text: "Look at them!"}]}]

    assert expected == actual
  end

  test "stripping a single whitespace token around a multiline each tag with surrounding newlines", context do
    template = """
    These are the bundles.

    ~each var=$bundles as=bundle~
    Bundle: ~$bundle~

    ~end~

    Look at them!
    """

    actual = eval_template(context.engine, "bundle_paragraphs_with_surrounding_newlines", template, %{"bundles" => ["ec2", "ecs", "s3"]})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "These are the bundles."}]},
                %{name: :paragraph,
                  children: [%{name: :text, text: "Bundle: ec2"}]},
                %{name: :paragraph,
                  children: [%{name: :text, text: "Bundle: ecs"}]},
                %{name: :paragraph,
                  children: [%{name: :text, text: "Bundle: s3"}]},
                %{name: :paragraph,
                  children: [%{name: :text, text: "Look at them!"}]}]

    assert expected == actual
  end

  test "Injecting newlines into an each", context do
    template = """
    These are the bundles.
    ~each var=$bundles as=bundle~Bundle: ~$bundle~~end~
    Look at them!
    """

    actual = eval_template(context.engine, "single_line_bundles", template, %{"bundles" => ["ec2", "ecs", "s3"]})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "These are the bundles."},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: ec2"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: ecs"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: s3"},
                             %{name: :newline},
                             %{name: :text, text: "Look at them!"}]}]

    assert expected == actual

    actual = eval_template(context.engine, "single_line_bundles", template, %{"bundles" => []})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "These are the bundles."},
                             %{name: :newline},
                             %{name: :text, text: "Look at them!"}]}]

    assert expected == actual
  end

  test "Injecting newlines into an each on template boundaries", context do
    template = """
    ~each var=$bundles as=bundle~Bundle: ~$bundle~~end~
    """

    actual = eval_template(context.engine, "template_boundary_bundles", template, %{"bundles" => ["ec2", "ecs", "s3"]})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "Bundle: ec2"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: ecs"},
                             %{name: :newline},
                             %{name: :text, text: "Bundle: s3"}]}]

    assert expected == actual

    actual = eval_template(context.engine, "template_boundary_bundles", template, %{"bundles" => []})

    expected = []

    assert expected == actual
  end

  test "Preserving an inline join", context do
    template = """
    I like many things: ~join var=$things~~$item~~end~
    """

    actual = eval_template(context.engine, "inline_join", template, %{"things" => ["ec2", "ecs", "s3"]})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "I like many things: ec2, ecs, s3"}]}]

    assert expected == actual
  end

  test "Back to back tags", context do
    template = """
    ~each var=$things~
    ~$item~
    ~end~
    ~each var=$things~
    ~$item~
    ~end~
    """

    actual = eval_template(context.engine, "back_to_back_tags", template, %{"things" => ["ec2", "ecs", "s3"]})

    expected = [%{name: :paragraph,
                  children: [%{name: :text, text: "ec2"},
                             %{name: :newline},
                             %{name: :text, text: "ecs"},
                             %{name: :newline},
                             %{name: :text, text: "s3"},
                             %{name: :newline},
                             %{name: :text, text: "ec2"},
                             %{name: :newline},
                             %{name: :text, text: "ecs"},
                             %{name: :newline},
                             %{name: :text, text: "s3"}]}]

    assert expected == actual
  end
end
