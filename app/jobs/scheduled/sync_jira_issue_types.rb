# frozen_string_literal: true

module ::Jobs
  class SyncJiraIssueTypes < ::Jobs::Scheduled
    every 3.hours

    def execute(args)
      return unless SiteSetting.discourse_jira_enabled

      ::DiscourseJira::IssueType.sync!
    end
  end
end
