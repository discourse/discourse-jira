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

# == Schema Information
#
# Table name: jira_project_issue_types
#
#  id            :bigint           not null, primary key
#  project_id    :bigint           not null
#  issue_type_id :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_jira_project_issue_types_on_project_id_and_issue_type_id  (project_id,issue_type_id) UNIQUE
#
