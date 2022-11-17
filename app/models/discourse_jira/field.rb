# frozen_string_literal: true

module DiscourseJira
  class Field < ::ActiveRecord::Base
    self.table_name = "jira_fields"

    belongs_to :issue_type
  end
end
