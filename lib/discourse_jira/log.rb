# frozen_string_literal: true

module DiscourseJira
  module Log
    def log(message)
      Rails.logger.warn("Jira verbose log:\n #{message}") if SiteSetting.discourse_jira_verbose_log
    end
  end
end
