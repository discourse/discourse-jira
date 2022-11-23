# frozen_string_literal: true

Fabricator(:jira_project, from: "DiscourseJira::Project") do
  uid { sequence(:uid) }
  key { sequence(:key) { |i| "key#{i}" } }
  name { sequence(:name) { |i| "Project #{i}" } }
end
