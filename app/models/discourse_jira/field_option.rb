# frozen_string_literal: true

module DiscourseJira
  class FieldOption < ::ActiveRecord::Base
    self.table_name = "jira_field_options"

    belongs_to :field
  end
end
