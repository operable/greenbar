defmodule Greenbar.Test.Support.Templates do

  def vm_list do
    """
~each var=$vms~
~$item.name~
~end~
"""

  end

  def vms_per_region do
    """
~each var=$regions~
~$item.name~
  ~each var=$item.vms~
    ~$item.name~ (~$item.id~)
  ~end~
~end~
"""
  end

  def solo_variable do
    """
This is a test.
~$item~.
"""
  end

  def newlines do
    """
This is a test.

~each var=$items~
  ~$item.id~

~end~

This has been a test.
"""
  end

end
