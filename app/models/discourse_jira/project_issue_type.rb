# frozen_string_literal: true

module DiscourseJira
  class ProjectIssueType < ::ActiveRecord::Base
    self.table_name = "jira_project_issue_types"

    belongs_to :project
    belongs_to :issue_type

    def fetch_fields
      Field.fetch(self.project.uid, self.issue_type.uid)
    end
  end
end
