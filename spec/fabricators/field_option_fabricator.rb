# frozen_string_literal: true

Fabricator(:jira_field_option, from: "DiscourseJira::FieldOption") do
  field(fabricator: :jira_field)
  jira_id { sequence(:jira_id) }
  value { sequence(:option) { |i| "Option #{i}" } }
end
