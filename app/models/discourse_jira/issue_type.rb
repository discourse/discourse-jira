# frozen_string_literal: true

module DiscourseJira
  class IssueType < ::ActiveRecord::Base
    self.table_name = "jira_issue_types"

    belongs_to :project
  end
end
