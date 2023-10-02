# frozen_string_literal: true

module DiscourseJira
  class Field < ::ActiveRecord::Base
    self.table_name = "jira_fields"

    SUPPORTED_TYPES ||= %w[string date array option].freeze
    DEFAULT_FIELDS ||= %w[summary description].freeze
    DISCOURSE_FIELDS ||= {
      post_url: "url",
      post_view_count: "float",
      post_reply_count: "float",
      post_created_at: "datetime",
      post_updated_at: "datetime",
      user_email: "textfield",
      profile_url: "url",
    }.freeze

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
        data[:projects].first[:issuetypes].first[:fields].each do |key, json|
          json[:fieldId] = key
          fields << json
        end
      end

      fields
        .select do |field|
          type = field[:schema][:type]

          next unless SUPPORTED_TYPES.include?(type)
          next unless field[:operations].include?("set")
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
            hidden: DISCOURSE_FIELDS.keys.include?(field[:name]),
            options: field[:allowedValues]&.map { |o| { id: o[:id], value: o[:value] } },
          }
        end
    end

    def self.sync!
      return unless SiteSetting.discourse_jira_enabled

      Api
        .getJSON("field")
        .each do |json|
          find_or_initialize_by(key: json[:id]).tap do |field|
            field.name = json[:name]
            field.field_type = json[:schema][:type]
            field.custom = json[:custom]
            field.save!
          end
        end
    end

    def self.create_discourse_fields!
      return unless SiteSetting.discourse_jira_enabled
      return if where(discourse_field: true).count == DISCOURSE_FIELDS.count

      DISCOURSE_FIELDS.each do |field_name, field_type|
        data = {
          name: "Discourse #{field_name}".humanize,
          type: "com.atlassian.jira.plugin.system.customfieldtypes:#{field_type}",
        }

        DiscourseJira::Field
          .find_or_initialize_by(name: data[:name])
          .tap do |field|
            next unless field.new_record?

            response = Api.post("field", data)
            json =
              begin
                JSON.parse(response.body, symbolize_names: true)
              rescue StandardError
                {}
              end

            field.key = json[:id]
            field.field_type = field_type
            field.custom = true
            field.discourse_field = true
            field.save!

            if SiteSetting.discourse_jira_add_fields_to_default_screen
              Api.post("screens/addToDefault/#{field_id}", {})
            end
          end
      end
    end
  end
end
