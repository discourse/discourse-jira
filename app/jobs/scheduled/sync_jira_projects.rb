# frozen_string_literal: true

module ::Jobs
  class SyncJiraProjects < ::Jobs::Scheduled
    every 1.hour

    def execute(args)
      return unless SiteSetting.discourse_jira_enabled

      ::DiscourseJira::Project.sync!
    end
  end
end
