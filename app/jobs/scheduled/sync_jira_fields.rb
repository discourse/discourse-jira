# frozen_string_literal: true

module ::Jobs
  class SyncJira < ::Jobs::Scheduled
    every 8.hours

    def execute(args)
      return unless SiteSetting.discourse_jira_enabled
      return if SiteSetting.discourse_jira_url.blank?

      ::DiscourseJira::Field.create_discourse_fields!
      ::DiscourseJira::Field.sync!
    end
  end
end
