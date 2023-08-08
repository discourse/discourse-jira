# frozen_string_literal: true

module ::Jobs
  class SyncJira < ::Jobs::Scheduled
    every 4.hours

    def execute(args)
      return unless SiteSetting.discourse_jira_enabled

      ::DiscourseJira::IssueType.sync!
      ::DiscourseJira::Project.sync!
    end
  end
end
