# frozen_string_literal: true

module DiscourseJira
  class PostsController < ::ApplicationController
    requires_plugin DiscourseJira::PLUGIN_NAME

    before_action :ensure_logged_in
    before_action :ensure_can_create_jira_issue

    def formatted_post_history
      topic = Topic.find_by(id: params[:topic_id])
      raise Discourse::NotFound if !topic
      guardian.ensure_can_see!(topic)

      result = topic.formatted_post_history(params[:post_number].to_i)

      render json: { formatted_post_history: result }
    end

    private

    def ensure_can_create_jira_issue
      guardian.ensure_can_create_jira_issue!
    end
  end
end
