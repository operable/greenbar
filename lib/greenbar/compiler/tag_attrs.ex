defmodule Greenbar.Compiler.TagAttributes do

  def compile(attrs) do
    exprs = build_attr_exprs(attrs, nil)
    quote do
      fn(scope) -> unquote(exprs) end
    end
  end

  defp attrs_pipe_start(nil) do
    quote do %{} end
  end
  defp attrs_pipe_start(expr), do: expr


  defp build_attr_exprs([], attr_expr) do
    attr_expr
  end
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {type, _, value}}|t], expr) when type in [:integer, :float, :string, :boolean] do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do Map.put(unquote(attr_name), unquote(value)) end, 0)
    build_attr_exprs(t, expr)
  end
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:var, name, ops}}|t], expr) do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                         Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # greater than
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:gt, {:var, name, ops},
                                                        {type, _, value}}}|t], expr) when type in [:integer, :float] do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                       (Kernel.>(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)), unquote(value))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # greater than equal
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:gte, {:var, name, ops},
                                                        {type, _, value}}}|t], expr) when type in [:integer, :float] do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name), (Kernel.>=(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)),
                             unquote(value))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # less than
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:lt, {:var, name, ops},
                                                        {type, _, value}}}|t], expr) when type in [:integer, :float] do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                       (Kernel.<(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)), unquote(value))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # less than equal
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:lte, {:var, name, ops},
                                                        {type, _, value}}}|t], expr) when type in [:integer, :float] do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                       (Kernel.<(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)), unquote(value)) or
                         Kernel.==(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)), unquote(value))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # equal
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:equal, {:var, name, ops},
                                                        {type, _, value}}}|t], expr) when type in [:integer, :float, :string, :boolean] do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                       (Kernel.==(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)), unquote(value))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # not equal
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:not_equal, {:var, name, ops},
                                                        {type, _, value}}}|t], expr) when type in [:integer, :float, :string, :boolean] do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                       (Kernel.!==(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops)), unquote(value))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # empty
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:empty, {:var, name, ops}}}|t], expr) do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                         Greenbar.Runtime.empty?(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # not empty
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:not_empty, {:var, name, ops}}}|t], expr) do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                         Greenbar.Runtime.not_empty?(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops))))
    end, 0)
    build_attr_exprs(t, expr)
  end


  # bound
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:bound, {:var, name, ops}}}|t], expr) do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                         Greenbar.Runtime.bound?(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops))))
    end, 0)
    build_attr_exprs(t, expr)
  end

  # not bound
  defp build_attr_exprs([{:assign_tag_attr, attr_name, {:not_bound, {:var, name, ops}}}|t], expr) do
    expr = Macro.pipe(attrs_pipe_start(expr), quote do
                       Map.put(unquote(attr_name),
                         Greenbar.Runtime.not_bound?(Greenbar.Runtime.var_to_value(scope, unquote(name), unquote(ops))))
    end, 0)
    build_attr_exprs(t, expr)
  end

end
