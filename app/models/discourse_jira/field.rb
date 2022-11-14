# frozen_string_literal: true

module DiscourseJira
  class Field < ::ActiveRecord::Base
    self.table_name = "jira_fields"

    belongs_to :issue_type

    def sync_fields(fields)
      
    end
  end
end
