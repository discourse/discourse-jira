# frozen_string_literal: true

module DiscourseJira
  class Field < ::ActiveRecord::Base
    self.table_name = "jira_fields"

    belongs_to :issue_type
    has_many :options, dependent: :destroy, class_name: "DiscourseJira::FieldOption"

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
