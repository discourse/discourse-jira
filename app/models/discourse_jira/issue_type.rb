# frozen_string_literal: true

module DiscourseJira
  class IssueType < ::ActiveRecord::Base
    self.table_name = "jira_issue_types"

    belongs_to :project
    has_many :fields, dependent: :destroy

    SUPPORTED_FIELD_TYPES ||= %w[string date array option].freeze
    DEFAULT_FIELDS ||= %w[summary description].freeze

    def sync_fields!(fields = nil)
      if fields.blank?
        data = Api.getJSON("issue/createmeta/#{self.project.key}/issuetypes/#{self.uid}")
        fields = data[:values] || []
      end

      if Api.get_version! >= 9
        fields.each { |json| sync_field!(json[:fieldId], json) }
      else
        fields.each { |key, json| sync_field!(key, json) }
      end
    end

    def sync_field!(key, data)
      type = data[:schema][:type]

      return unless SUPPORTED_FIELD_TYPES.include?(type)
      return unless data[:operations].include?("set")
      return if DEFAULT_FIELDS.include?(key.to_s)
      return if type == "array" && data[:schema][:items] != "option"
      return if %w[array option].include?(type) && data[:allowedValues].blank?

      field = self.fields.find_or_initialize_by(key: key)
      field.tap do |f|
        f.name = data[:name]
        f.required = data[:required]
        f.field_type = type
        (data[:allowedValues] || []).each do |option|
          f.options.find_or_create_by(jira_id: option[:id]) { |o| o.value = option[:value] }
        end
        f.save!
      end
    end

    def self.sync!
      return unless SiteSetting.discourse_jira_enabled
      return if ::DiscourseJira::Api.get_version! < 9

      projects = DiscourseJira::Project.order("synced_at ASC NULLS FIRST").limit(100)
      projects.each do |project|
        project.sync_issue_types!
        project.synced_at = Time.zone.now
        project.save!
      end
    end
  end
end
