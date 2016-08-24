defmodule Greenbar.Test.Support.Templates do

  def vm_list do
    """
~each items=$vms~
~$item.name~
~end~
"""

  end

  def vms_per_region do
    """
~each items=$regions~
~$item.name~
  ~each items=$item.vms~
    ~$item.name~ (~$item.id~)
  ~end~
~end~
"""
  end

end
