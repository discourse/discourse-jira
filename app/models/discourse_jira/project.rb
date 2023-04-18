# frozen_string_literal: true

module DiscourseJira
  class Project < ::ActiveRecord::Base
    self.table_name = "jira_projects"

    has_many :issue_types, dependent: :destroy

    def sync_issue_types!(issue_types = nil)
      return unless SiteSetting.discourse_jira_enabled

      if issue_types.blank?
        response = Api.get("issue/createmeta/#{self.key}/issuetypes")
        issue_types = JSON.parse(response.body, symbolize_names: true)[:values]
      end

      issue_types.each do |json|
        next if json[:subtask]

        issue_type = self.issue_types.find_or_initialize_by(uid: json[:id])
        issue_type.tap do |i|
          i.name = json[:name]
          if json[:fields].present?
            i.sync_fields!(json[:fields])
            i.synced_at = Time.zone.now
          end
          i.save!
        end
      end
    end

    def self.sync!
      return unless SiteSetting.discourse_jira_enabled

      projects = []

      if ::DiscourseJira::Api.get_version! >= 9
        response = Api.get("project")
        projects = JSON.parse(response.body, symbolize_names: true)
      else
        response = Api.get("issue/createmeta?expand=projects.issuetypes.fields")
        projects = JSON.parse(response.body, symbolize_names: true)[:projects]
      end

      projects.each do |json|
        project = find_or_initialize_by(uid: json[:id])
        project.tap do |p|
          p.name = json[:name]
          p.key = json[:key]
          if json[:issuetypes].present?
            p.sync_issue_types!(json[:issuetypes])
            p.synced_at = Time.zone.now
          end
          p.save!
        end
      end
    end
  end
end
