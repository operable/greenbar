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

  def bound_check do
    """
~if cond=$user_creators not_bound?~
No user creators available.
~end~
~if cond=$user_creators bound?~
~count var=$user_creators~ user creator(s) available.
~end~
"""
  end

  def simple_list do
    """
* One
* Two
* Three
"""
  end

  def generated_ordered_list do
    """
~each var=$users as=user~
1. ~$user.name~
~end~
"""
  end

  def generated_unordered_list do
    """
~each var=$users as=user~
* ~$user.name~
~end~
"""
  end

  def dynamic_list do
    """
~each var=$users as=user~
~$li~ ~$user.name~
~end~
"""
  end

  def nested_lists do
    """
~each var=$groups as=group~

* ~$group.name~
~each var=$group.users as=user~

  1. ~$user.name~
~end~
~end~
    """
  end

  def bundle_details do
    """
ID: ~$results[0].id~
Name: ~$results[0].name~

Versions: ~each var=$results[0].versions~
~$item.version~
~end~

# TODO: Think I need some 'if' tags here, too
Enabled Version: ~$results[0].enabled_version.version~
Relay Groups: ~each var=$results[0].relay_groups~
~$item.name~
~end~
"""
  end

  def length_test do
    """
~if cond=length($pets.puppies) > 1~
Lots of puppies!
~end~
~if cond=length($pets.puppies) == 1~
One puppy
~end~
~if cond=length($pets.puppies) == 0~
No puppies :(
~end~
"""
  end

  def table_with_each do
    """
| First Name | Last Name | Foo |
|---|---|---|
~each var=$users as=user~
| ~$user.first_name~ | ~$user.last_name~ | Bar |
~end~
"""
  end

  def attachment_tag do
    """
~attachment color=$color custom_field=$woot~
| Bundle | Status |
|---|---|
~each var=$bundles as=bundle~
|~$bundle.name~|~$bundle.status~|
~end~
~end~
"""
  end

end
