defmodule Greenbar.Test.Support.Templates do

  def documentation, do: "~$results[0].documentation~"

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

  def parent_child_scopes do
    """
This is a test. There are ~count var=$items~ items.
~each var=$items~
  `~$item~`
~end~


There are ~count var=$items~ items.
"""
  end

  def bundles do
    """
Here are all my bundles:
~br~
~each var=$results as=bundle~
ID: ~$bundle.id~
Name: ~$bundle.name~
# TODO: Need an "if" tag for this if there is no enabled version
Enabled Version: ~$bundle.enabled_version.version~

~end~
"""

  end

  def dangling_comment do
    "This is a test.\n# ~count var=$item~"
  end

  def if_tag do
    """
Testing the if tag.
~if cond=$item bound?~
~$item~
~end~
"""
    end

  def not_empty_check do
    """
~if cond=$user_creators not_empty?~
~br~
The following users can help you right here in chat:
~br~
~each var=$user_creators~
~$item~
~end~
~end~
"""
    end

end
