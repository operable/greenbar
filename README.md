## Greenbar: The meta-template processor

[![Build Status](https://travis-ci.org/operable/greenbar.svg?branch=master)](https://travis-ci.org/operable/greenbar)
[![Coverage Status](https://coveralls.io/repos/github/operable/greenbar/badge.svg?branch=master)](https://coveralls.io/github/operable/greenbar?branch=master)
[![Ebert](https://ebertapp.io/github/operable/greenbar.svg)](https://ebertapp.io/github/operable/greenbar)

Standard template processors like erb, mustache, and eex return formatted output when they process a template.
Normally this is just fine as most applications use common formats like HTML or JSON for their outputs.

Meta-templates, templates which produce other templates, are useful when an application needs to support multiple
formats and/or format(s) which are unevenly implemented (Markdown I'm looking at you). This is the problem domain
Greenbar was designed to address.

### For the truly curious

We created Greenbar to improve [Cog](https://github.com/operable/cog)'s rendering abilities. Generating attractive
and uniform content across multiple chat providers is quite challenging and also vital to building a good user
experience.

## How Does It Work?

Greenbar templates use a combination of Markdown and custom Greenbar-specific tags to describe a template. Templates
are compiled to executable Elixir code and then cached for easy reuse. Executing a template generates a list of
directives which describe how to build the final output.

## Your First Template

Here's a simple template that says hello:

```
Hello ~$user~!

Have a __GREAT__ DAY!
```

After downloading and building Greenbar you can build the template like so:

```
iex(1)> template = """
...(1)> Hello ~$user~!
...(1)>
...(1)> Have a __GREAT__ DAY!
...(1)> """
"Hello ~$user~!\n\nHave a __GREAT__ DAY!\n"
iex(2)> {:ok, engine} = Greenbar.Engine.new
{:ok,
 %Greenbar.Engine{tags: %{"br" => Greenbar.Tags.Break,
    "count" => Greenbar.Tags.Count, "each" => Greenbar.Tags.Each,
    "title" => Greenbar.Tags.Title}, templates: %{}}}
iex(3)> engine = Greenbar.Engine.compile!(engine, "hello", template)
%Greenbar.Engine{tags: %{"br" => Greenbar.Tags.Break,
   "count" => Greenbar.Tags.Count, "each" => Greenbar.Tags.Each,
   "title" => Greenbar.Tags.Title},
 templates: %{"hello" => %Greenbar.Template{debug_source: nil,
    hash: "c8c61d458c8070f04d76cb3e07dffcbd7dd0965080dba7f406b7b5c8a123dc5f",
    name: "hello", source: "Hello ~$user~!\n\nHave a __GREAT__ DAY!\n",
    template_fn: #Function<12.54118792/2 in :erl_eval.expr/5>,
    timestamp: 1472755224456112954}}}
```

Let's execute the compiled template:

```
iex(4)> Greenbar.Engine.eval!(engine, "hello", %{"user" => "Zaphod"})
[%{name: :text, text: "Hello Zaphod!"}, %{name: :newline},
 %{name: :text, text: "Have a "}, %{name: :bold, text: "GREAT"},
 %{name: :text, text: " DAY!"}]
```

## Syntax

Standard Markdown notation for emphasis, strong, code line, and code blocks are implemented. Tables and (un)ordered lists
are coming soon.

Template variables and tags are referenced using tildes. See [test/support/templates.ex](https://github.com/operable/greenbar/blob/master/test/support/templates.ex) for more examples.

## Tags

Greenbar tags are designed to be extensible. See [lib/greenbar/tag.ex](https://github.com/operable/greenbar/blob/master/lib/greenbar/tag.ex) for details.
