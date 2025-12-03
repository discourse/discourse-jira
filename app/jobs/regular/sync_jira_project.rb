# frozen_string_literal: true

module ::Jobs
  class SyncJiraProject < ::Jobs::Base
    class RateLimited < ::StandardError
    end

    sidekiq_options queue: "low", retry: 3

    sidekiq_retry_in do |_count, exception|
      if exception.is_a?(RateLimited)
        retry_after = exception.message.to_i
        retry_after = 60 if retry_after == 0
        rand(retry_after..(2 * retry_after))
      else
        :discard
      end
    end

    def execute(args)
      project_uid = args[:project_uid]
      raise Discourse::InvalidParameters.new if project_uid.blank?

      project = ::DiscourseJira::Project.find_or_initialize_by(uid: project_uid)
      response = ::DiscourseJira::Api.get("project/#{project.uid}?expand=issueTypes")

      case response.code.to_s
      when "429"
        raise RateLimited.new(response["Retry-After"])
      when "200"
        project.sync_issue_types!(JSON.parse(response.body, symbolize_names: true))
      else
        DiscourseJira::Api.invalid_response_exception(response)
      end
    end
  end
end
