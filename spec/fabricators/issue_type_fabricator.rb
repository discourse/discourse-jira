# frozen_string_literal: true

Fabricator(:jira_issue_type, from: "DiscourseJira::IssueType") do
  uid { sequence(:uid) }
  project(fabricator: :jira_project)
  name { sequence(:name) { |i| "Issue Type #{i}" } }
end
