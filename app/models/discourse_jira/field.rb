# frozen_string_literal: true

module DiscourseJira
  class Field < ::ActiveRecord::Base
    self.table_name = "jira_fields"

    SUPPORTED_TYPES ||= %w[string date array option].freeze
    DEFAULT_FIELDS ||= %w[summary description].freeze

    def self.fetch(project_id, issue_type_id)
      Discourse
        .cache
        .fetch("jira-createmeta-#{project_id}-#{issue_type_id}", expires_in: 6.hours) do
          Field.fetch_from_jira(project_id, issue_type_id)
        end
    end

    def self.fetch_from_jira(project_id, issue_type_id)
      fields = []

      if Api.createmeta_restricted?
        data = Api.getJSON("issue/createmeta/#{project_id}/issuetypes/#{issue_type_id}")
        fields = data[:values] if data[:values].present?
      else
        data =
          Api.getJSON(
            "issue/createmeta?projectIds=#{project_id}&issuetypeIds=#{issue_type_id}&expand=projects.issuetypes.fields",
          )
        data
          .dig(:projects, 0, :issuetypes, 0, :fields)
          &.each do |key, json|
            json[:fieldId] = key
            fields << json
          end
      end

      fields
        .select do |field|
          type = field[:schema][:type]

          next if SUPPORTED_TYPES.exclude?(type)
          next if field[:operations].exclude?("set")
          next if DEFAULT_FIELDS.include?(field[:fieldId].to_s)
          next if type == "array" && field[:schema][:items] != "option"
          next if %w[array option].include?(type) && field[:allowedValues].blank?

          true
        end
        .map do |field|
          {
            key: field[:fieldId],
            name: field[:name],
            required: field[:required],
            field_type: field[:schema][:type],
            options: field[:allowedValues]&.map { |o| { id: o[:id], value: o[:value] } },
          }
        end
    end

    def self.sync!
      return unless SiteSetting.discourse_jira_enabled
      return unless Api.createmeta_restricted?

      issue_types = DiscourseJira::IssueType.order("synced_at ASC NULLS FIRST").limit(100)
      issue_types.each do |issue_type|
        issue_type.sync_fields!
        issue_type.synced_at = Time.zone.now
        issue_type.save!
      end
    end
  end
end

# == Schema Information
#
# Table name: jira_fields
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  name       :string           not null
#  field_type :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
