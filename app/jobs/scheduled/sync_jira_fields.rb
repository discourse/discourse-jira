# frozen_string_literal: true

module ::Jobs
  class SyncJiraFields < ::Jobs::Scheduled
    every 6.hours

    def execute(args)
      return unless SiteSetting.discourse_jira_enabled

      ::DiscourseJira::Field.sync!
    end
  end
end
