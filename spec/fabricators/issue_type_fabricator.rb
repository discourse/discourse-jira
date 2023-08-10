# frozen_string_literal: true

Fabricator(:jira_issue_type, from: "DiscourseJira::IssueType") do
  uid { sequence(:uid) }
  name { sequence(:name) { |i| "Issue Type #{i}" } }
end
