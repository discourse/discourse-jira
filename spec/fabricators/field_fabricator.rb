# frozen_string_literal: true

Fabricator(:jira_field, from: "DiscourseJira::Field") do
  issue_type(fabricator: :jira_issue_type)
  key { sequence(:key) { |i| "key#{i}" } }
  name { sequence(:name) { |i| "Issue Type #{i}" } }
  field_type "string"
  required false
end
