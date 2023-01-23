# frozen_string_literal: true

module DiscourseJira
  class IssueType < ::ActiveRecord::Base
    self.table_name = "jira_issue_types"

    belongs_to :project
    has_many :fields, dependent: :destroy

    SUPPORTED_FIELD_TYPES ||= %w[string date array option].freeze
    DEFAULT_FIELDS ||= %w[summary description].freeze

    def sync_fields(fields)
      return if fields.blank?

      fields.each do |key, json|
        type = json[:schema][:type]

        next unless SUPPORTED_FIELD_TYPES.include?(type)
        next unless json[:operations].include?("set")
        next if DEFAULT_FIELDS.include?(key.to_s)
        next if type == "array" && json[:schema][:items] != "option"
        next if %w[array option].include?(type) && json[:allowedValues].blank?

        field =
          self
            .fields
            .find_or_create_by(key: key) do |f|
              f.name = json[:name]
              f.required = json[:required]
              f.field_type = type
            end

        (json[:allowedValues] || []).each do |data|
          field.options.find_or_create_by(jira_id: data[:id]) { |o| o.value = data[:value] }
        end
      end
    end
  end
end
