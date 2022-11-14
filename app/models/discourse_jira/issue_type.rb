# frozen_string_literal: true

module DiscourseJira
  class IssueType < ::ActiveRecord::Base
    self.table_name = "jira_issue_types"

    belongs_to :project
    has_many :fields, dependent: :destroy

    def sync_fields(fields)
      return if fields.blank?

      fields.each do |key, json|
        next if json[:operations].exclude?("set")

        field = self.fields.find_or_create_by(key: key) do |f|
          f.name = json[:name]
          f.required = json[:required]
          f.field_type = json[:schema][:type]
        end
      end
    end
  end
end
