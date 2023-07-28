# frozen_string_literal: true

module DiscourseJira
  class Project < ::ActiveRecord::Base
    self.table_name = "jira_projects"

    has_many :issue_types, dependent: :destroy

    def sync_issue_types!(issue_types = nil)
      return unless SiteSetting.discourse_jira_enabled

      if issue_types.blank?
        data = Api.getJSON("issue/createmeta/#{self.key}/issuetypes")
        issue_types = data[:values] || []
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

      synced_at = Time.zone.now
    end

    def self.sync!
      return unless SiteSetting.discourse_jira_enabled

      project_ids = []

      Api
        .getJSON("project")
        .each do |json|
          find_or_initialize_by(uid: json[:id]).tap do |p|
            p.name = json[:name]
            p.key = json[:key]
            if json[:issuetypes].present?
              p.sync_issue_types!(json[:issuetypes])
            elsif p.synced_at.blank? && !Api.createmeta_restricted?
              project_ids << p.uid
            end
            p.save!
          end
        end

      IssueType.sync_by_project_ids!(project_ids)
    end
  end
end
