# frozen_string_literal: true

Tag.seed(:name) { |tag| tag.name = "jira-issue" }

TagGroup.seed(:name) do |tag_group|
  tag_group.name = "Jira Issue Status"
  tag_group.parent_tag_id = Tag.find_by(name: "jira-issue").id
  tag_group.permissions = [[Group::AUTO_GROUPS[:staff], TagGroupPermission.permission_types[:full]]]
  tag_group.one_per_topic = true
end
